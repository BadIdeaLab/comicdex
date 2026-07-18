import 'dart:io';

import 'package:dio/dio.dart';

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      validateStatus: (status) => status != null && status < 500,
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  const testMid = '3166275';
  const thumbnailHosts = <String>['t1', 't2', 't3', 't4', 't'];
  const imageHosts = <String>['i1', 'i2', 'i3', 'i4', 'i'];

  for (final host in thumbnailHosts) {
    final domain = '$host.nhentai.net';
    final url = 'https://$domain/galleries/$testMid/thumb.webp';
    await _checkHost(dio, domain, url);
  }

  for (final host in imageHosts) {
    final domain = '$host.nhentai.net';
    final url = 'https://$domain/galleries/$testMid/1.webp';
    await _checkHost(dio, domain, url);
  }
}

Future<void> _checkHost(Dio dio, String domain, String url) async {
  stdout.writeln('checking $url');
  await InternetAddress.lookup(domain);
  final response = await dio.get(url);
  stdout.writeln('status=${response.statusCode}');
}
