class FileData {
  final String id;
  final String fileName;
  final String size;
  final String dateUpload;
  final int iteration;
  final String checksum;
  //final String group;

  FileData(
      {required this.id,
      required this.fileName,
      required this.size,
      required this.dateUpload,
      required this.iteration,
      required this.checksum
      //required this.group,
      });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'size': size,
      'dateUpload': dateUpload,
      'iteration': iteration,
      'checksum': checksum
      //'group': group,
    };
  }

  static FileData fromJson(Map<String, dynamic> json) {
    return FileData(
        id: json['id'],
        fileName: json['fileName'],
        size: json['size'],
        dateUpload: json['dateUpload'],
        iteration: json['iteration'],
        checksum: json['cheacksum']
        //group: json['group'],
        );
  }
}
