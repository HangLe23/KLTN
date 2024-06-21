class ListResponse<T> {
  List<T> list;
  ListResponse({
    required this.list,
  });
}

class ObjectResponse<T> {
  T object;
  ObjectResponse({
    required this.object,
  });
}
