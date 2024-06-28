import 'dart:developer';

import 'package:client/apis/api_client/base_url.dart';
import 'package:client/index.dart';
import 'package:client/screen/node_service.dart';
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

  @override
  void initState() {
    super.initState();
    setupSocket();
  }

  void setupSocket() {
    socket = IO.io(BaseURLs.development.url,
        IO.OptionBuilder().setTransports(['websocket']).build());

    socket?.onConnect((_) {
      print('Connected to socket');
    });

    socket?.on('infoMessage', (data) {
      final id = data['id'];
      final cpu = data['cpu'];
      final gpu = data['gpu'];
      final ram = data['ram'];
      final sdr = data['sdr'];
      String displaySDR;
      switch (sdr) {
        case 'lime':
          displaySDR = 'Lime SDR';
          break;
        case 'b200':
          displaySDR = 'USRP B200 mini';
          break;
        default:
          displaySDR = 'Unknown sdr device';
      }
      setState(() {
        items.add(NodeItem(
          id: id,
          services: '',
          cpu: cpu,
          gpu: gpu,
          ram: ram,
          deviceSDR: displaySDR,
        ));
        selectedNodes[id] = false;
      });
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
              IconButton(
                onPressed: () {
                  _addNode('', '', '', '', '', '');
                },
                icon: CustomIcons.add,
              ),
              const SizedBox(width: 100),
              ElevatedButton(
                onPressed: () {
                  // selectedNodes.forEach((nodeId, isSelected) {
                  //   if (isSelected) {
                  //     String service = selectedServices[nodeId] ?? '';
                  //     sendDownloadRequest(service, nodeId);
                  //   }
                  // });
                  List<String> selectedNodeIds = selectedNodes.entries
                      .where((entry) => entry.value)
                      .map((entry) => entry.key)
                      .toList();

                  // Nếu chỉ có một node được chọn, gửi yêu cầu download cho node đó
                  if (selectedNodeIds.length == 1) {
                    String nodeId = selectedNodeIds.first;
                    String service = selectedServices[nodeId] ?? '';
                    sendDownloadRequest(service, nodeId);
                  } else if (selectedNodeIds.length > 1) {
                    String service =
                        selectedServices[selectedNodeIds.first] ?? '';
                    sendDownloadAllRequest(service);
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
      final progressString = _specialStatuses[item.id] ?? '';
      final progressStringUpdate = _specialStatusesUpdate[item.id] ?? '';
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
              onChanged: (value) {
                setState(() {
                  selectedServices[item.id ?? ''] = value;
                  item.services = value!;
                });
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
                          value: item.progress ?? 0.0,
                          backgroundColor: Colors.grey,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      Center(
                        child:
                            Text(progressString, style: TextStyles.textTable),
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
          title: Text('Node Details - ID: ${item.id}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${item.id}'),
              Text('CPU: ${item.cpu}'),
              Text('GPU: ${item.gpu}'),
              Text('RAM: ${item.ram}'),
              Text('Services: ${item.services}'),
              Text('SDR Device: ${item.deviceSDR ?? 'N/A'}'),
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

  void _addNode(String id, String cpu, String gpu, String ram, String services,
      String? sdr) async {
    try {
      // Khởi tạo Dio
      Dio dio = Dio();

      // Thực hiện yêu cầu HTTP POST đến máy chủ
      var response = await dio.post(
        "${BaseURLs.development.url}/addNode", // Địa chỉ của máy chủ
      );

      // Kiểm tra mã trạng thái của phản hồi
      if (response.statusCode == 200) {
        // Thêm item vào danh sách nếu yêu cầu thành công
        setState(() {
          items.add(NodeItem(
              id: id,
              services: services,
              cpu: cpu,
              gpu: gpu,
              ram: ram,
              deviceSDR: sdr));
          selectedNodes[id] = false;
        });
      } else {
        // Xử lý lỗi nếu yêu cầu không thành công
        print('Failed to add node: ${response.statusCode}');
      }
    } catch (e) {
      // Xử lý lỗi nếu có lỗi trong quá trình gửi yêu cầu
      print('Error adding node: $e');
    }
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
