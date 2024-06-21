import 'package:client/apis/index.dart';

class FileRequest {
  FileRequest._();
  static APIRequest upload() => APIRequest(
        method: HTTPMethods.post,
        path: '/uploads',
      );
}
