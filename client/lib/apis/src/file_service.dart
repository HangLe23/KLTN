import 'package:client/apis/index.dart';
import 'package:client/index.dart';

class FileService {
  APIClient apiClient;
  FileService({required this.apiClient});
  Future<ListResponse<FileData>> uploadFile() async {
    var request = FileRequest.upload();
    final response = await apiClient.execute(request: request);
    final listResponse =
        response.toList().map<FileData>((e) => FileData.fromJson(e)).toList();
    return ListResponse(list: listResponse);
  }
}
