import 'dart:io';

import 'package:args/args.dart';
import 'package:cloudflare_dyn_dns/cache.dart';
import 'package:cloudflare_dyn_dns/cloudflare.dart';
import 'package:cloudflare_dyn_dns/config.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

Future<void> main(List<String> args) async {
  // Parse args
  final parser = ArgParser()
    ..addFlag('help',
        abbr: 'h', help: 'Displays this help information.', negatable: false)
    ..addFlag('skip-cache',
        abbr: 's',
        help:
            'Ignore IP cache file. By default, Cloudflare API calls will be avoided '
            'if public IPs did not change since the last time this program was ran.',
        defaultsTo: false,
        negatable: false)
    ..addOption('config', abbr: 'c', help: 'Configuration file (required).');

  final argResults = parser.parse(args);

  if (argResults['help'] ||
      !argResults.options.any((o) => argResults.wasParsed(o))) {
    print(
        'Update Cloudflare DNS records with this machine\'s current public IP address(s).');
    print('');
    print('Usage: cloudflare_dyn_dns [arguments]');
    print('');
    print('Options:');
    print(parser.usage);
    return;
  }

  // Read cache file
  final bool skipCache = argResults['skip-cache'];
  final IpCache cache;

  if (!skipCache) {
    cache = await getIpCache();
  } else {
    cache = IpCache.empty();
  }

  // Read config file
  final configFile = File(argResults['config']);
  if (!configFile.existsSync()) {
    print('Could not find config file at ${configFile.absolute.path}');
    exit(1);
  }

  final config = Config(loadYaml(await configFile.readAsString()));

  // Set up clients
  final client = CloudflareClient(token: config.token);
  final http = Client();

  try {
    // Determine public IPs
    final String? ipv4;
    if (config.ipv4Url != null) {
      final ipv4Response = await http.get(Uri.parse(config.ipv4Url!));
      if (ipv4Response.statusCode != 200) {
        stderr.writeln(
            '${config.ipv4Url} returned ${ipv4Response.statusCode}. Body: ${ipv4Response.body}');
        exit(1);
      }

      ipv4 = ipv4Response.body;
      print('Found IPv4: $ipv4');
    } else {
      ipv4 = null;
    }

    final String? ipv6;
    if (config.ipv6Url != null) {
      final ipv6Response = await http.get(Uri.parse(config.ipv6Url!));
      if (ipv6Response.statusCode != 200) {
        stderr.writeln(
            '${config.ipv6Url} returned ${ipv6Response.statusCode}. Body: ${ipv6Response.body}');
        exit(1);
      }

      ipv6 = ipv6Response.body;
      print('Found IPv6: $ipv6');
    } else {
      ipv6 = null;
    }

    if (cache.ipv4 == ipv4 && cache.ipv6 == ipv6) {
      print('IP(s) have not changed since last run.');
      exit(0);
    }

    // Get existing DNS records
    final records = await client.listDnsRecords(config.zoneId);

    // Create/update DNS records
    for (final record in config.records) {
      if (!const ['A', 'AAAA'].contains(record.type)) {
        stderr.writeln('Invalid record type in config: ${record.type}');
        exit(1);
      }

      final existing = records.firstWhereOrNull(
          (r) => r.type == record.type && r.name == record.name);
      final ip = record.type == 'A' ? ipv4 : ipv6;

      if (ip == null) {
        stderr.writeln('No IP found for ${record.type} type record.');
        exit(1);
      }

      if (existing == null) {
        await client.createDnsRecord(
          config.zoneId,
          type: record.type,
          name: record.name,
          content: ip,
        );
        print('Created DNS record: ${record.type} ${record.name} -> $ip');
      } else if (existing.content != ip) {
        await client.updateDnsRecord(
          config.zoneId,
          id: existing.id,
          type: existing.type,
          name: existing.name,
          content: ip,
        );
        print('Updated DNS record: ${existing.type} ${existing.name} -> $ip');
      } else {
        print(
            'DNS record: ${existing.type} ${existing.name} $ip already up-to-date.');
      }
    }

    // Update cache file
    if (!skipCache) {
      final cachePath = await writeIpCache(ipv4: ipv4, ipv6: ipv6);
      print('Caching IP(s) at ${p.absolute(cachePath)}');
    }
  } on CloudflareException catch (ex) {
    stderr.writeln(ex.message);
    exit(1);
  } finally {
    http.close();
    client.close();
  }
}
