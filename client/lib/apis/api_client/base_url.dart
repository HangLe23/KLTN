class BaseURL {
  const BaseURL._({
    required this.schemes,
    required this.host,
    required this.port,
  });

  final String schemes;
  final String host;
  final String port;
  String get url => schemes + host + port;
}

class BaseURLs {
  static const BaseURL development = BaseURL._(
    schemes: 'http://',
    host: 'localhost',
    port: ':8000',
  );
}
