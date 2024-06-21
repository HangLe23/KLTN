import 'index.dart';

class APIRequest {
  APIRequest({
    required this.method,
    required this.path,
    this.headers,
    //this.parameters,
    this.body,
  });

  HTTPMethod method;
  String path;
  dynamic headers;
  //Map<String, dynamic>? parameters;
  dynamic body;
}
