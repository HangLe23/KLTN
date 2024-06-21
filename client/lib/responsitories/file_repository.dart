import 'package:client/apis/index.dart';
import 'package:client/index.dart';

class FileReponsitory {
  RestApiClient restApiClient;
  FileReponsitory({required this.restApiClient});
  Future<ListResponse<FileData>> uploadFile() async {
    return FileService(apiClient: restApiClient).uploadFile();
  }
}
