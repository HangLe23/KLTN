import 'package:client/apis/api_client/index.dart';
import 'package:dio/dio.dart';

class RestApiClient extends APIClient {
  static final RestApiClient _instance = RestApiClient._();

  RestApiClient._();

  factory RestApiClient() => _instance;

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: BaseURLs.development.schemes +
          BaseURLs.development.host +
          BaseURLs.development.port,
    ),
  )..interceptors.add(APIInterceptor());

  @override
  Future<APIResponse> execute({required APIRequest request}) async {
    final options = Options(
      method: request.method.value,
      contentType: Headers.jsonContentType,
    );

    try {
      final response = await dio.request(
        request.path,
        //queryParameters: request.parameters.addApiKey(),
        data: request.body,
        options: options,
      );

      return APIResponse.fromJson(response.data);
    } on DioError catch (e) {
      switch (e.response?.statusCode) {
        case 401:
          throw APIError.fromJson(e.response?.data);

        default:
          throw APIError(statusMessage: e.message);
      }
    }
  }
}

// extension APIKey on Map<String, dynamic>? {
//   Map<String, dynamic>? addApiKey() {
//     if (this == null) {
//       return {'api_key': AppConstants.api};
//     } else {
//       this!.addAll({
//         'api_key': AppConstants.api,
//       });

//       return this;
//     }
//   }
// }
