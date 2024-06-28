import 'dart:convert' as convert;
import 'dart:html' as html;

import 'package:client/apis/index.dart';
import 'package:client/index.dart';
import 'package:client/screen/node_service.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SourceScreen extends StatefulWidget {
  const SourceScreen({Key? key}) : super(key: key);

  @override
  State<SourceScreen> createState() => _SourceScreenState();
}

class _SourceScreenState extends State<SourceScreen> {
  List<FileData> fileList = [];

  Future<void> saveFileList() async {
    if (kIsWeb) {
      html.window.localStorage['fileList'] =
          convert.jsonEncode(fileList.map((file) => file.toJson()).toList());
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setStringList(
        'fileList',
        fileList.map((file) => convert.jsonEncode(file.toJson())).toList(),
      );
    }
  }

  bool isFileAlreadyUploaded(String fileName) {
    return fileList.any((file) => file.fileName == fileName);
  }

  Future<void> uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.single;
      String fileId = const Uuid().v4();
      Dio dio = Dio();

      // Check if file already exists in fileList
      if (isFileAlreadyUploaded(file.name)) {
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('File Upload Error'),
              content: const Text('This file has already been uploaded.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }

      // Show input dialog for iterations and checksum
      Map<String, dynamic>? dialogResult = await showInputDialog(context);
      if (dialogResult == null) {
        return; // User cancelled the input dialog
      }

      int iterations = dialogResult['iterations'];
      String checksum = dialogResult['checksum'];
      String service;
      if (file.name.toLowerCase().contains('fm')) {
        service = 'FM Receiver';
      } else if (file.name.toLowerCase().contains('wifi')) {
        service = 'Wifi Receiver';
      } else {
        service = 'Unknown Service';
      }
      String sdr;
      if (file.name.toLowerCase().contains('lime')) {
        sdr = 'LimeSDR';
      } else if (file.name.toLowerCase().contains('b200')) {
        sdr = 'USRP B200 mini';
      } else {
        sdr = 'Unknown SDR';
      }
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
          "${BaseURLs.development.url}/uploads",
          data: formData,
        );

        setState(() {
          fileList.add(FileData(
            id: fileId,
            fileName: file.name,
            size: file.size.toString(),
            dateUpload: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            iteration: iterations,
            checksum: checksum,
            sdr: sdr,
            service: service,
          ));
          NodeService().service = fileList;
        });

        // Save the updated list of files to storage
        saveFileList();

        print(response.data);
      } catch (e) {
        print('Error uploading file: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> showInputDialog(BuildContext context) async {
    TextEditingController iterationsController = TextEditingController();
    TextEditingController checksumController = TextEditingController();

    return await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Iterations and Checksum'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: iterationsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Iterations'),
              ),
              TextField(
                controller: checksumController,
                decoration: const InputDecoration(labelText: 'Checksum'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'iterations': int.tryParse(iterationsController.text) ?? 0,
                  'checksum': checksumController.text,
                });
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Cancel button
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    //loadFileList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.white,
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
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
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columnSpacing: 120,
                  columns: [
                    DataColumn(
                      label: Text(
                        'File Name',
                        style: TextStyles.titleTable,
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Size',
                        style: TextStyles.titleTable,
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Date Upload',
                        style: TextStyles.titleTable,
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Service',
                        style: TextStyles.titleTable,
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'SDR Device',
                        style: TextStyles.titleTable,
                      ),
                    ),
                  ],
                  rows: fileList.map((file) {
                    return DataRow(
                        cells: [
                          DataCell(Text(
                            file.fileName,
                            style: TextStyles.textTable,
                          )),
                          DataCell(Text(
                            file.size,
                            style: TextStyles.textTable,
                          )),
                          DataCell(Text(
                            file.dateUpload,
                            style: TextStyles.textTable,
                          )),
                          DataCell(Text(
                            file.service,
                            style: TextStyles.textTable,
                          )),
                          DataCell(Text(
                            file.sdr,
                            style: TextStyles.textTable,
                          )),
                        ],
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              String? description;

                              if (file.fileName.contains('fm') &&
                                  file.fileName.contains('lime')) {
                                description = 'FM Receiver for limeSDR';
                              } else if (file.fileName.contains('fm') &&
                                  file.fileName.contains('b200')) {
                                description = 'FM Receiver for USRP B200 mini';
                              } else if (file.fileName.contains('wifi') &&
                                  file.fileName.contains('lime')) {
                                description = 'Wifi Receiver for limeSDR';
                              } else if (file.fileName.contains('wifi') &&
                                  file.fileName.contains('b200')) {
                                description =
                                    'Wifi Receiver for USRP B200 mini';
                              }

                              return AlertDialog(
                                title: const Text("File Details"),
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("File Name: ${file.fileName}"),
                                    const Divider(),
                                    const Text("Type: Python"),
                                    const SizedBox(height: 10),
                                    Text("File Size: ${file.size}"),
                                    const SizedBox(height: 10),
                                    Text("Date Upload: ${file.dateUpload}"),
                                    const Divider(),
                                    Text("Iteration: ${file.iteration}"),
                                    const SizedBox(height: 10),
                                    Text("Checksum: ${file.checksum}"),
                                    const SizedBox(height: 10),
                                    Text("SDR Device: ${file.sdr}"),
                                    const Divider(),
                                    Text("Description: $description"),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text("Close"),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        color: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.hovered)) {
                              return CustomColor.purple50;
                            }
                            return null;
                          },
                        ));
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getServiceGroup(String fileName) {
    List<String> parts = fileName.split('-');
    if (parts.isNotEmpty) {
      return parts.first; // Return the first element of the list
    }
    return ''; // Default case when no valid data is present
  }
}
