part of 'source_file_bloc.dart';

@immutable
abstract class SourceFileState {
  final List<FileData>? files;
  final String? error;
  const SourceFileState({this.files, this.error});
}

final class SourceFileInitial extends SourceFileState {
  const SourceFileInitial();
}

final class LoadPageSource extends SourceFileState {
  const LoadPageSource();
}

final class ListFileUpload extends SourceFileState {
  const ListFileUpload({required super.files, super.error});
}

final class SourceError extends SourceFileState {
  const SourceError({required super.files, super.error});
}

final class FileNull extends SourceFileState {}
