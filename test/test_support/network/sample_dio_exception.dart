import 'package:dio/dio.dart';

DioException sampleDioException([int? statusCode]) {
  return DioException(
    requestOptions: RequestOptions(path: '/'),
    response: statusCode == null
        ? null
        : Response<dynamic>(
            requestOptions: RequestOptions(path: '/'),
            statusCode: statusCode,
          ),
  );
}
