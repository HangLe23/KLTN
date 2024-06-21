import 'dart:convert' as convert;
import 'dart:developer';
import 'dart:html' as html;

import 'package:client/apis/index.dart';
import 'package:client/index.dart';
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
  Map<String, bool> selectedFiles =
      {}; // Map to store selected state for each fileId

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

  int determineIteration(String fileName) {
    List<String> parts = fileName.split('-');
    if (parts.isNotEmpty) {
      String firstPart = parts[0];
      String lastPart = parts.last.split('.').first;
      if (firstPart == 'fm' && lastPart == 'lime') {
        return 8;
      } else if (firstPart == 'fm' && lastPart == 'b200') {
        return 14;
      } else if (firstPart == 'wifi' && lastPart == 'b200') {
        return 14;
      } else if (firstPart == 'wifi' && lastPart == 'lime') {
        return 7;
      }
    }
    return 0;
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
          ));
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

  Future<void> loadFileList() async {
    if (kIsWeb) {
      String? jsonFileList = html.window.localStorage['fileList'];
      if (jsonFileList != null) {
        Iterable decoded = convert.jsonDecode(jsonFileList);
        fileList =
            decoded.map((fileJson) => FileData.fromJson(fileJson)).toList();
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? jsonFileList = prefs.getStringList('fileList');
      if (jsonFileList != null) {
        fileList = jsonFileList
            .map((json) => FileData.fromJson(convert.jsonDecode(json)))
            .toList();
      }
    }
    setState(() {});
  }

  Future<void> sendDownloadAllRequest() async {
    Dio dio = Dio();
    try {
      // Get selected files
      List<FileData> selectedFilesList =
          fileList.where((file) => selectedFiles[file.id] ?? false).toList();

      // Get unique service groups from selected files
      Set<String> uniqueServiceGroups = selectedFilesList
          .map((file) => getServiceGroup(file.fileName))
          .toSet();

      // Generate message for server
      String message = 'all_${uniqueServiceGroups.join('-')}-rx';

      Response response = await dio.post(
        "${BaseURLs.development.url}/triggerDownload",
        data: {'message': message},
      );

      print(response.data);
      // Optionally handle response here
    } catch (e) {
      print('Error sending download request: $e');
      // Handle error
    }
  }

  Future<void> sendDownloadRequest(String fileName) async {
    Dio dio = Dio();
    try {
      // Send request to download a specific file
      Response response = await dio.post(
        "${BaseURLs.development.url}/downloads",
        data: {'file': fileName}, // Pass single file name as data
      );

      print(response.data);
      // Handle response from server if necessary
    } catch (e) {
      print('Error sending download request: $e');
      // Handle error if occurs
    }
  }

  @override
  void initState() {
    super.initState();
    loadFileList();
  }

  @override
  Widget build(BuildContext context) {
    // Group files by service group
    Map<String, List<FileData>> groupedFiles = {};

    for (FileData file in fileList) {
      String serviceGroup = getServiceGroup(file.fileName);
      if (!groupedFiles.containsKey(serviceGroup)) {
        groupedFiles[serviceGroup] = [];
      }
      groupedFiles[serviceGroup]!.add(file);
    }

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
              ElevatedButton(
                onPressed: () {
                  // Get selected files
                  sendDownloadAllRequest();
                },
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(CustomColor.purple50),
                ),
                child: const Text(
                  'Download All',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const DividerWidget(),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: groupedFiles.entries.map((entry) {
                  String serviceGroup = entry.key;
                  List<FileData> files = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          serviceGroup,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
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
                                'Download',
                                style: TextStyles.titleTable,
                              ),
                            ),
                          ],
                          rows: files.map((file) {
                            return DataRow(
                                selected: selectedFiles[file.id] ?? false,
                                onSelectChanged: (selected) {
                                  setState(() {
                                    selectedFiles[file.id] = selected ?? false;
                                  });
                                },
                                cells: [
                                  DataCell(
                                    Text(
                                      file.fileName,
                                      style: TextStyles.textTable,
                                    ),
                                  ),
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
                                      onPressed: () {
                                        // Handle individual file download
                                        // Not fully implemented in this example
                                        sendDownloadRequest(file.fileName);
                                        log(file.fileName);
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
                                onLongPress: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("File Details"),
                                        content: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text("File Name: ${file.fileName}"),
                                            const DividerWidget(),
                                            const Text("Type: Python"),
                                            const SizedBox(height: 10),
                                            Text("File Size: ${file.size}"),
                                            const SizedBox(height: 10),
                                            Text(
                                                "Date Upload: ${file.dateUpload.toString()}"),
                                            const DividerWidget(),
                                            Text(
                                                "Iteration: ${file.iteration}"),
                                            const SizedBox(height: 10),
                                            Text("Checksum: ${file.checksum}"),
                                            const SizedBox(height: 10),
                                            const Text("SDR Device"),
                                            const DividerWidget(),
                                            const Text("Decription: "),
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
                                color:
                                    MaterialStateProperty.resolveWith<Color?>(
                                  (Set<MaterialState> states) {
                                    if (states
                                        .contains(MaterialState.hovered)) {
                                      return CustomColor.purple50;
                                    }
                                    return null;
                                  },
                                ));
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
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
