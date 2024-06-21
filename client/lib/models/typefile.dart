class Type {
  static const String image = 'image';
  static const String audio = 'audio';
  static const String video = 'video';
  static const String text = 'text';
  static const String pdf = 'pdf';
  static const String word = 'word';
  static const String excel = 'excel';
  static const String powerpoint = 'powerpoint';
  static const String csv = 'csv';
  static const String zip = 'zip';
  static const String rar = 'rar';
  static const String apk = 'apk';
  static const String exe = 'exe';
  static const String html = 'html';
  static const String css = 'css';
  static const String js = 'js';
  static const String py = 'py';
  static const String unknown = 'unknown';
}

class FileType {
  static String getType(String fileName) {
    // Tách phần mở rộng của tên file
    List<String> parts = fileName.split('.');
    if (parts.length > 1) {
      // Lấy phần mở rộng cuối cùng
      String extension = parts.last.toLowerCase();
      // Xác định loại file dựa trên phần mở rộng
      switch (extension) {
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
        case 'bmp':
          return Type.image;
        case 'mp3':
        case 'wav':
        case 'ogg':
        case 'flac':
          return Type.audio;
        case 'mp4':
        case 'avi':
        case 'mov':
        case 'mkv':
          return Type.video;
        case 'txt':
        case 'log':
          return Type.text;
        case 'pdf':
          return Type.pdf;
        case 'doc':
        case 'docx':
          return Type.word;
        case 'xls':
        case 'xlsx':
          return Type.excel;
        case 'ppt':
        case 'pptx':
          return Type.powerpoint;
        case 'csv':
          return Type.csv;
        case 'zip':
          return Type.zip;
        case 'rar':
          return Type.rar;
        case 'apk':
          return Type.apk;
        case 'exe':
          return Type.exe;
        case 'html':
        case 'htm':
          return Type.html;
        case 'css':
          return Type.css;
        case 'js':
          return Type.js;
        case 'py':
          return Type.py;
      }
    }
    return Type.unknown;
  }

  static String getTypeString(String type) {
    switch (type) {
      case Type.image:
        return 'Image';
      case Type.audio:
        return 'Audio';
      case Type.video:
        return 'Video';
      case Type.text:
        return 'Text';
      case Type.pdf:
        return 'PDF';
      case Type.word:
        return 'Word';
      case Type.excel:
        return 'Excel';
      case Type.powerpoint:
        return 'PowerPoint';
      case Type.csv:
        return 'CSV';
      case Type.zip:
        return 'ZIP';
      case Type.rar:
        return 'RAR';
      case Type.apk:
        return 'APK';
      case Type.exe:
        return 'EXE';
      case Type.html:
        return 'HTML';
      case Type.css:
        return 'CSS';
      case Type.js:
        return 'JS';
      case Type.py:
        return 'Python';
      case Type.unknown:
        return 'Unknown';
      default:
        return '';
    }
  }
}
