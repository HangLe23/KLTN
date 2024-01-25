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
