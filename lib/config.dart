import 'package:yaml/yaml.dart';

class Config {
  final String token;
  final String zoneId;
  final String? ipv4Url;
  final String? ipv6Url;
  final List<ConfigRecord> records;

  Config(YamlMap yaml)
      : token = yaml['token'],
        zoneId = yaml['zoneId'],
        ipv4Url = yaml['ipv4Url'],
        ipv6Url = yaml['ipv6Url'],
        records =
            (yaml['records'] as List).map((r) => ConfigRecord(r)).toList();
}

class ConfigRecord {
  final String type;
  final String name;

  ConfigRecord(YamlMap yaml)
      : type = yaml['type'],
        name = yaml['name'];
}
