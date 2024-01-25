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
          "http://172.31.71.106:8080/uploads",
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
          const SizedBox(height: 20),
          Row(
            children: [
              const SizedBox(width: 100),
              IconButton(
                onPressed: () {
                  uploadFile();
                },
                icon: CustomIcons.upload,
              ),
            ],
          ),
          const DividerWidget(),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columnSpacing: 120, // Khoảng cách giữa các cột
                columns: [
                  DataColumn(
                    label: Text(
                      'File Name',
                      style: TextStyles.tittleTable,
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Size',
                      style: TextStyles.tittleTable,
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Date Upload',
                      style: TextStyles.tittleTable,
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Download',
                      style: TextStyles.tittleTable,
                    ),
                  ),
                ],
                rows: fileList
                    .map(
                      (file) => DataRow(
                        cells: [
                          DataCell(InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      FileDetailsView(file: file),
                                ),
                              );
                            },
                            child: Text(
                              file.fileName,
                              style: TextStyles.textTable,
                            ),
                          )),
                          DataCell(
                            Text(
                              file.size,
                              style: TextStyles.textTable,
                            ),
                          ),
                          DataCell(
                            Text(
                              file.dateUpload,
                              style: TextStyles.textTable,
                            ),
                          ),
                          DataCell(
                            ElevatedButton(
                              onPressed: () async {
                                Response response = await Dio().get(
                                  "http://172.31.71.106:8080/downloads?name=${file.fileName}",
                                );
                                print(response);
                              },
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        CustomColor.purple50),
                              ),
                              child: const Text(
                                'Download',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
