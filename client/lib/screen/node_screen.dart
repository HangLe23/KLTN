import 'dart:developer';

import 'package:client/apis/api_client/base_url.dart';
import 'package:client/index.dart';
import 'package:client/responsitories/node_firebase.dart';
import 'package:client/screen/node_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class NodeScreen extends StatefulWidget {
  const NodeScreen({Key? key}) : super(key: key);

  @override
  _NodeScreenState createState() => _NodeScreenState();
}

class _NodeScreenState extends State<NodeScreen> {
  List<NodeItem> items = [];
  IO.Socket? socket;
  final Map<String, String> _specialStatuses = {};
  final Map<String, String> _specialStatusesUpdate = {};
  Map<String, String?> selectedServices = {};
  Map<String, bool> selectedNodes = {};
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    setupSocket();
    _firestoreService.getNodes().listen((nodeItems) {
      setState(() {
        items = nodeItems;
      });
    });
  }

  void setupSocket() {
    socket = IO.io(BaseURLs.development.url,
        IO.OptionBuilder().setTransports(['websocket']).build());

    socket?.onConnect((_) {
      print('Connected to socket');
    });

    socket?.on('downloadProgress', (data) {
      setState(() {
        // Tách id và thông điệp progress từ data
        final parts = data.split('_');
        final id = parts[0];
        final file = parts[1];
        final progressString = parts[2];

        if (progressString.contains('%')) {
          // Chuyển đổi progress từ chuỗi sang double
          final progress =
              double.tryParse(progressString.replaceAll('%', '')) ?? 0.0;

          // Tìm node với ID tương ứng và cập nhật progress của nó
          for (var item in items) {
            if (item.id == id) {
              item.progress = progress / 100;
              break;
            }
          }

          // Cập nhật thông báo tiến trình đặc biệt
          _specialStatuses[id] = file + " downloading " + progressString;
        } else {
          // Cập nhật thông báo trạng thái đặc biệt
          _specialStatuses[id] = _getProgressText(file, progressString);
        }
      });
    });
//update
    socket?.on('updateProgress', (data) {
      setState(() {
        // Tách id và thông điệp progress từ data
        final parts = data.split('_');
        final id = parts[0];
        final file = parts[1];
        final status = parts[2];
        final progressString = parts[3];

        if (status == 'progr') {
          // Chuyển đổi progress từ chuỗi sang double
          final progress = double.tryParse(progressString) ?? 0.0;

          // Tìm node với ID tương ứng và cập nhật progress của nó
          for (var item in items) {
            if (item.id == id) {
              item.progress = progress / 100;
              break;
            }
          }
          _specialStatusesUpdate[id] = 'Updating $progressString%';
        } else if (status == 'finish') {
          _specialStatusesUpdate[id] = _getProgressUpdate(file, progressString);
        } else if (status != 'progr' && status != 'finish') {
          _specialStatusesUpdate[id] = 'Run time: $status';
          log(_specialStatusesUpdate[id].toString());
        }
      });
    });

    socket?.onDisconnect((_) {
      //print('Disconnected from socket');
    });
  }

  String _getProgressText(String file, String progressString) {
    switch (progressString) {
      case 'finish':
        return 'File $file downloaded but not checksum';
      case 'fail':
        return 'File $file downloaded failed but not checksum';
      case 'checksumsuccess':
        return 'File $file downloaded successfully';
      case 'checksumfail':
        return 'File $file download failed';
      default:
        return 'Unknown status';
    }
  }

  String _getProgressUpdate(String file, String progressString) {
    switch (progressString) {
      case 'success':
        return 'Updated successfully with $file';
      case 'fail':
        return 'Updated failed with $file';
      default:
        return 'Unknown status';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.white,
      body: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              const SizedBox(width: 100),
              ElevatedButton(
                onPressed: () {
                  List<String> selectedNodeIds = selectedNodes.entries
                      .where((entry) => entry.value)
                      .map((entry) => entry.key)
                      .toList();

                  bool allNodesSelected =
                      selectedNodeIds.length == items.length;

                  if (allNodesSelected) {
                    String service =
                        selectedServices[selectedNodeIds.first] ?? '';
                    sendDownloadAllRequest(service);
                  } else {
                    for (var nodeId in selectedNodeIds) {
                      String service = selectedServices[nodeId] ?? '';
                      sendDownloadRequest(service, nodeId);
                    }
                  }
                },
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(CustomColor.purple50),
                ),
                child: const Text(
                  'Download',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columns: [
                  DataColumn(
                    label: Text(
                      'No.',
                      style: TextStyles.titleTable,
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'ID',
                      style: TextStyles.titleTable,
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Location',
                      style: TextStyles.titleTable,
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'SDR device',
                      style: TextStyles.titleTable,
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Select Service',
                      style: TextStyles.titleTable,
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Download',
                      style: TextStyles.titleTable,
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Update',
                      style: TextStyles.titleTable,
                    ),
                  ),
                ],
                rows: _buildRows(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DataRow> _buildRows() {
    return items.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final item = entry.value;
      final progress = item.progress ?? 0.0; // Sử dụng progress từ NodeItem
      final progressString = _specialStatuses[item.id] ?? '';
      final progressStringUpdate = _specialStatusesUpdate[item.id] ?? '';
      // Các dòng còn lại giữ nguyên như trước
      return DataRow(
        selected: selectedNodes[item.id] ?? false,
        onSelectChanged: (selected) {
          setState(() {
            selectedNodes[item.id ?? ''] = selected ?? false;
          });
        },
        cells: [
          DataCell(Text('$index', style: TextStyles.textTable)),
          DataCell(Text(item.id ?? '', style: TextStyles.textTable)),
          DataCell(Text("${item.location} at lab E3.1 - UIT",
              style: TextStyles.textTable)),
          DataCell(Text(item.deviceSDR ?? '', style: TextStyles.textTable)),
          DataCell(
            DropdownButton<String>(
              value: selectedServices[item.id],
              hint: const Text('Select Service'),
              items: NodeService()
                  .service
                  .map((file) => file.service)
                  .toSet()
                  .map((service) {
                return DropdownMenuItem<String>(
                  value: service,
                  child: Text(service),
                );
              }).toList(),
              onChanged: (value) async {
                setState(() {
                  selectedServices[item.id ?? ''] = value;
                  item.services = value!;
                });
                // Cập nhật service đã chọn lên Firestore
                await FirebaseFirestore.instance
                    .collection('Node')
                    .doc(item.id)
                    .update({'SDRService': value});
              },
            ),
          ),
          DataCell(
            progressString.contains(RegExp(r'\d+%'))
                ? Stack(
                    children: [
                      SizedBox(
                        width: 250,
                        height: 30,
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          backgroundColor: Colors.grey,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      Center(
                        child: Text('${progress.toStringAsFixed(2)}%',
                            style: TextStyles.textTable),
                      ),
                    ],
                  )
                : Text(progressString, style: TextStyles.textTable),
          ),
          DataCell(
            progressStringUpdate.contains(RegExp(r'\d+%'))
                ? Stack(
                    children: [
                      SizedBox(
                        width: 300,
                        height: 30,
                        child: LinearProgressIndicator(
                          value: item.progress ?? 0.0,
                          backgroundColor: Colors.grey,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      Center(
                        child: Text(progressStringUpdate,
                            style: TextStyles.textTable),
                      ),
                    ],
                  )
                : Text(progressStringUpdate, style: TextStyles.textTable),
          ),
        ],
        onLongPress: () {
          _showItemDetailsDialog(context, item);
        },
        color: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.hovered)) {
              return CustomColor.purple50;
            }
            return null;
          },
        ),
      );
    }).toList();
  }

  void _showItemDetailsDialog(BuildContext context, NodeItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Node Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${item.id}'),
              Text('CPU: ${item.cpu}'),
              Text('RAM: ${item.ram}'),
              Text('SDR Service: ${item.services}'),
              Text('SDR Device: ${item.deviceSDR ?? 'N/A'}'),
              Text('Location: ${"${item.location} at lab E3.1 - UIT"}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Đóng hộp thoại
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    socket?.dispose();
    super.dispose();
  }

  Future<void> sendDownloadRequest(String service, String nodeId) async {
    Dio dio = Dio();
    String servicerx;
    if (service == 'FM Receiver') {
      servicerx = 'fm-rx';
    } else if (service == 'Wifi Receiver') {
      servicerx = 'wifi-rx';
    } else {
      servicerx = '';
    }

    try {
      // Send request to download a specific file
      Response response = await dio.post(
        "${BaseURLs.development.url}/downloads",
        data: {
          'service': servicerx,
          'nodeId': nodeId
        }, // Pass single file name as data
      );
      log(servicerx);
      print(response.data);
      // Handle response from server if necessary
    } catch (e) {
      print('Error sending download request: $e');
      // Handle error if occurs
    }
  }

  Future<void> sendDownloadAllRequest(String service) async {
    Dio dio = Dio();
    Map<String, String> servicesRx = {};

    selectedNodes.forEach((nodeId, isSelected) {
      String service = selectedServices[nodeId] ?? '';
      String servicerx;
      if (service == 'FM Receiver') {
        servicerx = 'fm-rx';
      } else if (service == 'Wifi Receiver') {
        servicerx = 'wifi-rx';
      } else {
        servicerx = '';
      }
      servicesRx[nodeId] = servicerx;
    });

    try {
      // Gửi yêu cầu download tất cả các dịch vụ đã chọn
      Response response = await dio.post(
        "${BaseURLs.development.url}/downloadAll",
        data: {
          'services': servicesRx,
        },
      );

      print(response.data);
      // Xử lý phản hồi từ server nếu cần thiết
    } catch (e) {
      print('Error sending download all request: $e');
      // Xử lý lỗi nếu có
    }
  }
}
