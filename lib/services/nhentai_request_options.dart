import 'package:dio/dio.dart';

/// Timeouts for every request this app makes.
///
/// Dio's own default is **no timeout at all**, so a `Dio()` built without
/// these waits for the operating system to give up — which, when the site is
/// unreachable rather than merely down, can be minutes of a spinner with no
/// way out. P89 added these; P98 moved them here after finding four services
/// that had each built a bare `Dio()` and inherited the old behaviour.
///
/// Lives in its own file so that a service the client depends on — the CDN
/// config service — can use them without importing the client back.
final BaseOptions nhentaiRequestOptions = BaseOptions(
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 30),
  sendTimeout: const Duration(seconds: 30),
);
