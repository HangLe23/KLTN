import 'index.dart';

abstract class APIClient {
  Future<APIResponse> execute({required APIRequest request});
}
