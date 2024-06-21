import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:client/apis/index.dart';
import 'package:client/index.dart';
import 'package:client/responsitories/file_repository.dart';
import 'package:meta/meta.dart';

part 'source_file_event.dart';
part 'source_file_state.dart';

class SourceFileBloc extends Bloc<SourceFileEvent, SourceFileState> {
  FileReponsitory reponsitory = FileReponsitory(restApiClient: RestApiClient());
  SourceFileBloc() : super(const SourceFileInitial()) {
    on<UpLoadFile>(onUpLoadFile);
  }

  Future<FutureOr<void>> onUpLoadFile(
      UpLoadFile event, Emitter<SourceFileState> emit) async {
    emit(const LoadPageSource());
    if (state.files!.isEmpty) {
      emit(FileNull());
    } else {
      try {
        var files = await reponsitory.uploadFile();
        emit(ListFileUpload(files: files.list));
      } catch (e) {
        emit(SourceError(files: null, error: e.toString()));
      }
    }
  }
}
