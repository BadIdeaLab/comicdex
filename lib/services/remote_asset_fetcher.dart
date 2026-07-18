import 'dart:typed_data';

import 'package:dio/dio.dart';

abstract class RemoteAssetFetcher {
  Future<Uint8List> fetchBytes(String url);
}

class DioRemoteAssetFetcher implements RemoteAssetFetcher {
  DioRemoteAssetFetcher({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  Future<Uint8List> fetchBytes(String url) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('No bytes returned for $url');
    }
    return Uint8List.fromList(data);
  }
}
