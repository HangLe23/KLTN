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
  List<NodeItem> items = []; // Danh sách các item thiết bị
  IO.Socket? socket;
  final Map<String, String> _specialStatuses = {};
  final Map<String, String> _specialStatusesUpdate = {};

  @override
  void initState() {
    super.initState();
    setupSocket();
    NodeService().nodes = items;
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
      final services = data['services'];
      //print('Received info message: $infoMessage');
      // Xử lý chuỗi service
      String displayService;
      switch (services) {
        case 'fm':
          displayService = 'FM Receiver';
          break;
        case 'wifi':
          displayService = 'Wifi Receiver';
          break;
        case '0':
          displayService = 'No service running';
          break;
        default:
          displayService = 'Unknown service';
      }
      setState(() {
        items.add(NodeItem(
          id: id,
          services: displayService,
          cpu: cpu,
          gpu: gpu,
          ram: ram,
          deviceSDR: sdr,
        ));
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
        return 'File $file has completed downloading but has not been checked';
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
        return 'Updated successfully';
      case 'fail':
        return 'Updated failed';
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
            ],
          ),
          const DividerWidget(),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columnSpacing: 120,
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
                      'Services',
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
                  // DataColumn(
                  //   label: Text(
                  //     'Run time',
                  //     style: TextStyles.titleTable,
                  //   ),
                  // ),
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
        cells: [
          DataCell(Text('$index', style: TextStyles.textTable)),
          DataCell(Text(item.id ?? '', style: TextStyles.textTable)),
          DataCell(Text(item.services ?? '', style: TextStyles.textTable)),
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
          // DataCell(
          //   progressStringUpdate.contains('Run time:')
          //       ? Text(progressStringUpdate, style: TextStyles.textTable)
          //       : const Text(''),
          // )
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
          NodeService().nodes = items;
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
}
