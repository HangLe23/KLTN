class APIResponse {
  dynamic results;

  APIResponse(this.results);

  APIResponse.fromJson(Map<String, dynamic> json) {
    results = json['results'];
  }

  Map<String, dynamic> toObject() {
    return Map<String, dynamic>.from(results);
  }

  List<Map<String, dynamic>> toList() {
    return List<Map<String, dynamic>>.from(results);
  }

  List<Map<String, dynamic>> toItems() {
    return List<Map<String, dynamic>>.from(results['results']);
  }
}

// when errror
class APIError implements Exception {
  bool? success;
  int? statusCode;
  String? statusMessage;

  APIError({
    this.success,
    this.statusCode,
    this.statusMessage,
  });

  APIError.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    statusCode = json['status_code'];
    statusMessage = json['status_message'];
  }

  @override
  String toString() {
    return statusMessage ?? 'An unexpected error occurred.';
  }
}
