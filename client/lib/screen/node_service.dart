// node_service.dart
import 'package:client/index.dart';

class NodeService {
  static final NodeService _singleton = NodeService._internal();
  factory NodeService() {
    return _singleton;
  }
  NodeService._internal();

  List<NodeItem> nodes = [];
}
