class PendingFile {
  final bool isDirectory;
  final String filePath;
  final List<String> directories;

  const PendingFile({
    required this.isDirectory,
    required this.filePath,
    required this.directories,
  });

  @override
  String toString() {
    return 'PendingFile{isDirectory: $isDirectory, filePath: $filePath, directories: $directories}';
  }
}
