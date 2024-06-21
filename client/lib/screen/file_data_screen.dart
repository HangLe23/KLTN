import 'package:client/index.dart';
import 'package:flutter/material.dart';

class FileDetailsView extends StatefulWidget {
  const FileDetailsView({Key? key, required this.fileData}) : super(key: key);

  final FileData fileData;

  @override
  State<FileDetailsView> createState() => _FileDetailsViewState();
}

class _FileDetailsViewState extends State<FileDetailsView> {
  //late TextEditingController name;
  //late TextEditingController iteration;
  // TextEditingController sdr = TextEditingController();
  String? sdr;
  String? script;
  int? iteration;

  @override
  void initState() {
    super.initState();
    //name = TextEditingController(text: widget.fileData.fileName);
    updateSdrAndScript();
    //iteration = TextEditingController();
    //iteration.addListener(_updateSdrAndScript);
  }

  void updateSdrAndScript() {
    final fileName = widget.fileData.fileName.toLowerCase();
    setState(() {
      if (fileName.contains('lime')) {
        sdr = 'LimeSDR';
      } else if (fileName.contains('b200')) {
        sdr = 'USRP B200 mini';
      } else {
        sdr = null;
      }

      if (sdr != null) {
        if (fileName.contains('fm')) {
          script = 'Dịch vụ phát sóng FM của thiết bị $sdr';
        } else if (fileName.contains('wifi')) {
          script = 'Dịch vụ thu wifi của thiết bị $sdr';
        } else {
          script = null;
        }
      } else {
        script = null;
      }
    });
  }

  @override
  void dispose() {
    //iteration.removeListener(_updateSdrAndScript);
    //iteration.dispose();
    //name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 800,
      width: 600,
      color: CustomColor.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              const SizedBox(width: 20),
              Text(
                'File Name:',
                style: TextStyles.infoFile,
              ),
              const SizedBox(width: 50),
              Text(
                widget.fileData.fileName.toString(),
                style: TextStyles.inter15,
              ),
            ],
          ),
          const DividerWidget(),
          // const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 20),
              Text(
                'Type: ',
                style: TextStyles.infoFile,
              ),
              const SizedBox(width: 50),
              Text(
                'Python',
                style: TextStyles.inter15,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const SizedBox(width: 20),
              Text(
                'Size: ',
                style: TextStyles.infoFile,
              ),
              const SizedBox(width: 50),
              Text(
                widget.fileData.size.toString(),
                style: TextStyles.inter15,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const SizedBox(width: 20),
              Text(
                'Date Upload: ',
                style: TextStyles.infoFile,
              ),
              const SizedBox(width: 50),
              Text(
                widget.fileData.dateUpload.toString(),
                style: TextStyles.inter15,
              ),
            ],
          ),
          const DividerWidget(),
          Row(
            children: [
              const SizedBox(width: 20),
              Text(
                'Iteration: ',
                style: TextStyles.infoFile,
              ),
              const SizedBox(width: 50),
              // TextFieldWidget(
              //   textedit: iteration,
              //   //hint: hint,
              // )
              Text(
                widget.fileData.iteration.toString(),
                style: TextStyles.inter15,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const SizedBox(width: 20),
              Text(
                'SDR Devices: ',
                style: TextStyles.infoFile,
              ),
              const SizedBox(width: 50),
              // TextFieldWidget(
              //   textedit: sdr,
              //   //hint: hint,
              // )
              Text(
                sdr ?? '',
                style: TextStyles.inter15,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const SizedBox(width: 20),
              Text(
                'Decription: ',
                style: TextStyles.infoFile,
              ),
              const SizedBox(width: 50),
              Text(
                script ?? '',
                style: TextStyles.inter15,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
