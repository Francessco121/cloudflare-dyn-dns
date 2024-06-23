import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xdg_directories/xdg_directories.dart' as xdg;
import 'package:yaml/yaml.dart';

class IpCache {
  final String? ipv4;
  final String? ipv6;

  IpCache(YamlMap yaml)
      : ipv4 = yaml['ipv4'],
        ipv6 = yaml['ipv6'];

  IpCache.empty()
      : ipv4 = null,
        ipv6 = null;
}

Future<IpCache> getIpCache() async {
  final cacheFile = getIpCacheFile();
  if (cacheFile.existsSync()) {
    try {
      return IpCache(loadYaml(await cacheFile.readAsString()));
    } on Exception {
      return IpCache.empty();
    }
  } else {
    return IpCache.empty();
  }
}

Future<String> writeIpCache({
  required String? ipv4,
  required String? ipv6,
}) async {
  final sb = StringBuffer();
  if (ipv4 != null) {
    sb.writeln('ipv4: \'$ipv4\'');
  }
  if (ipv6 != null) {
    sb.writeln('ipv6: \'$ipv6\'');
  }

  final cacheFile = getIpCacheFile();
  await cacheFile.writeAsString(sb.toString());

  return cacheFile.path;
}

File getIpCacheFile() {
  final Directory cacheDir;
  if (Platform.isLinux) {
    if (Platform.environment.containsKey('HOME')) {
      cacheDir = xdg.cacheHome;
    } else {
      cacheDir = Directory.systemTemp;
    }
  } else {
    cacheDir = Directory.systemTemp;
  }

  final appCacheDir = Directory(p.join(cacheDir.path, 'cloudflare_dyn_dns'));
  appCacheDir.createSync(recursive: true);

  return File(p.join(appCacheDir.path, 'cache.yaml'));
}
