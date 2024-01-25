import 'dart:convert' as convert;
import 'dart:html' as html;

import 'package:client/index.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SourceScreen extends StatefulWidget {
  const SourceScreen({Key? key}) : super(key: key);

  @override
  State<SourceScreen> createState() => _SourceScreenState();
}

class _SourceScreenState extends State<SourceScreen> {
  List<FileData> fileList = [];

  @override
  void initState() {
    super.initState();
    // Load the list of files from storage when the widget is initialized
    loadFileList();
  }

  Future<void> loadFileList() async {
    if (kIsWeb) {
      // Check if there is a file list stored in localStorage
      final storedFileList = html.window.localStorage['fileList'];
      if (storedFileList != null) {
        // If yes, update fileList from the stored data
        setState(() {
          fileList = (convert.jsonDecode(storedFileList) as List)
              .map((data) => FileData.fromJson(data))
              .toList();
        });
      }
    } else {
      // If not in a web environment, use SharedPreferences as before
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        fileList = prefs
                .getStringList('fileList')
                ?.map((data) => FileData.fromJson(convert.jsonDecode(data)))
                .toList() ??
            [];
      });
    }
  }

  Future<void> saveFileList() async {
    if (kIsWeb) {
      // If in a web environment, save fileList to localStorage
      html.window.localStorage['fileList'] =
          convert.jsonEncode(fileList.map((file) => file.toJson()).toList());
    } else {
      // If not in a web environment, use SharedPreferences as before
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setStringList(
        'fileList',
        fileList.map((file) => convert.jsonEncode(file.toJson())).toList(),
      );
    }
  }

  Future<void> uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.single;

      Dio dio = Dio();

      FormData formData;

      if (kIsWeb) {
        formData = FormData.fromMap({
          "file": MultipartFile.fromBytes(
            file.bytes!,
            filename: file.name,
          ),
        });
      } else {
        formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(
            file.path!,
            filename: file.name,
          ),
        });
      }

      try {
        Response response = await dio.post(
          "http://localhost:8080/uploads",
          data: formData,
        );

        setState(() {
          fileList.add(FileData(
            fileName: file.name,
            size: file.size.toString(),
            dateUpload: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          ));
        });

        // Save the updated list of files to storage
        saveFileList();

        print(response.data);
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.background,
      body: Column(
        children: [
          IconButton(
            onPressed: () {
              uploadFile();
            },
            icon: CustomIcons.upload,
          ),
          Expanded(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('File Name')),
                DataColumn(label: Text('Size')),
                DataColumn(label: Text('Date Upload')),
              ],
              rows: fileList
                  .map(
                    (file) => DataRow(
                      onSelectChanged: (isSelected) {
                        if (isSelected != null && isSelected) {
                          // Navigate to file details view when a row is selected
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FileDetailsView(file: file),
                            ),
                          );
                        }
                      },
                      cells: [
                        DataCell(Text(file.fileName)),
                        DataCell(Text(file.size)),
                        DataCell(Text(file.dateUpload)),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class FileDetailsView extends StatelessWidget {
  final FileData file;

  const FileDetailsView({Key? key, required this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Details'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('File Name: ${file.fileName}'),
          Text('Size: ${file.size}'),
          Text('Date Upload: ${file.dateUpload}'),
          // Add more details as needed
        ],
      ),
    );
  }
}

class FileData {
  String fileName;
  String size;
  String dateUpload;

  FileData({
    required this.fileName,
    required this.size,
    required this.dateUpload,
  });

  // Convert FileData instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'size': size,
      'dateUpload': dateUpload,
    };
  }

  // Create FileData instance from JSON
  factory FileData.fromJson(Map<String, dynamic> json) {
    return FileData(
      fileName: json['fileName'] ?? '',
      size: json['size'] ?? '',
      dateUpload: json['dateUpload'] ?? '',
    );
  }
}
