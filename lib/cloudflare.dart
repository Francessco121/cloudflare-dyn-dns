import 'dart:convert';

import 'package:http/http.dart';

class CloudflareClient {
  final _http = Client();
  final String _token;

  CloudflareClient({required String token}) : _token = token;

  Future<void> createDnsRecord(
    String zoneId, {
    required String type,
    required String name,
    required String content,
  }) async {
    final response = await _http.post(
      Uri.parse(
          'https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'type': type,
        'name': name,
        'content': content,
      }),
    );

    if (response.statusCode != 200) {
      throw CloudflareException(
          'Cloudflare API (create DNS record) returned ${response.statusCode}. Body: ${response.body}');
    }
  }

  Future<void> updateDnsRecord(
    String zoneId, {
    required String id,
    required String type,
    required String name,
    required String content,
  }) async {
    final response = await _http.patch(
      Uri.parse(
          'https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records/$id'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'id': id,
        'type': type,
        'name': name,
        'content': content,
      }),
    );

    if (response.statusCode != 200) {
      throw CloudflareException(
          'Cloudflare API (update DNS record) returned ${response.statusCode}. Body: ${response.body}');
    }
  }

  Future<List<DnsRecord>> listDnsRecords(String zoneId) async {
    final response = await _http.get(
      Uri.parse(
          'https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json'
      },
    );

    if (response.statusCode != 200) {
      throw CloudflareException(
          'Cloudflare API (list DNS records) returned ${response.statusCode}. Body: ${response.body}');
    }

    final result = json.decode(response.body);

    return (result['result'] as List).map((r) => DnsRecord(r)).toList();
  }

  void close() {
    _http.close();
  }
}

class CloudflareException implements Exception {
  final String message;

  CloudflareException(this.message);

  @override
  String toString() {
    return 'CloudflareException: $message';
  }
}

class DnsRecord {
  final String id;
  final String type;
  final String name;
  final String content;

  DnsRecord(Map<String, dynamic> json)
      : id = json['id'],
        type = json['type'],
        name = json['name'],
        content = json['content'];
}
