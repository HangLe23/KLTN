import 'package:client/index.dart';
import 'package:flutter/material.dart';

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
