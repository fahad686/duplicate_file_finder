class FileTypes {
  static const images = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
  static const videos = ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv'];
  static const audio = ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma'];
  static const documents = [
    '.pdf',
    '.doc',
    '.docx',
    '.xls',
    '.xlsx',
    '.ppt',
    '.pptx',
    '.txt',
    '.csv',
  ];
  static const archives = ['.zip', '.rar', '.7z'];

  static List<String> all() => [
        ...images,
        ...videos,
        ...audio,
        ...documents,
        ...archives,
      ];
}
