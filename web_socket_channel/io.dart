import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// File I/O utilities for reading, writing, and managing files
class FileIO {
  /// Read a text file asynchronously
  static Future<String> readTextFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('File does not exist', filePath);
      }
      return await file.readAsString();
    } catch (e) {
      throw FileSystemException('Failed to read file: $e', filePath);
    }
  }

  /// Read a text file synchronously
  static String readTextFileSync(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw FileSystemException('File does not exist', filePath);
      }
      return file.readAsStringSync();
    } catch (e) {
      throw FileSystemException('Failed to read file: $e', filePath);
    }
  }

  /// Write text to file asynchronously
  static Future<void> writeTextFile(String filePath, String content, {bool append = false}) async {
    try {
      final file = File(filePath);
      
      // Create directory if it doesn't exist
      await file.parent.create(recursive: true);
      
      if (append) {
        await file.writeAsString(content, mode: FileMode.append);
      } else {
        await file.writeAsString(content);
      }
    } catch (e) {
      throw FileSystemException('Failed to write file: $e', filePath);
    }
  }

  /// Write text to file synchronously
  static void writeTextFileSync(String filePath, String content, {bool append = false}) {
    try {
      final file = File(filePath);
      
      // Create directory if it doesn't exist
      file.parent.createSync(recursive: true);
      
      if (append) {
        file.writeAsStringSync(content, mode: FileMode.append);
      } else {
        file.writeAsStringSync(content);
      }
    } catch (e) {
      throw FileSystemException('Failed to write file: $e', filePath);
    }
  }

  /// Read binary file as bytes
  static Future<Uint8List> readBinaryFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('File does not exist', filePath);
      }
      return await file.readAsBytes();
    } catch (e) {
      throw FileSystemException('Failed to read binary file: $e', filePath);
    }
  }

  /// Write binary data to file
  static Future<void> writeBinaryFile(String filePath, Uint8List data) async {
    try {
      final file = File(filePath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data);
    } catch (e) {
      throw FileSystemException('Failed to write binary file: $e', filePath);
    }
  }

  /// Read JSON file and parse it
  static Future<Map<String, dynamic>> readJsonFile(String filePath) async {
    try {
      final content = await readTextFile(filePath);
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      throw FileSystemException('Failed to read JSON file: $e', filePath);
    }
  }

  /// Write JSON data to file
  static Future<void> writeJsonFile(String filePath, Map<String, dynamic> data, {bool prettyPrint = true}) async {
    try {
      String jsonString;
      if (prettyPrint) {
        const encoder = JsonEncoder.withIndent('  ');
        jsonString = encoder.convert(data);
      } else {
        jsonString = jsonEncode(data);
      }
      await writeTextFile(filePath, jsonString);
    } catch (e) {
      throw FileSystemException('Failed to write JSON file: $e', filePath);
    }
  }

  /// Check if file exists
  static Future<bool> fileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Check if directory exists
  static Future<bool> directoryExists(String dirPath) async {
    try {
      return await Directory(dirPath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Create directory recursively
  static Future<void> createDirectory(String dirPath) async {
    try {
      await Directory(dirPath).create(recursive: true);
    } catch (e) {
      throw FileSystemException('Failed to create directory: $e', dirPath);
    }
  }

  /// Delete file
  static Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw FileSystemException('Failed to delete file: $e', filePath);
    }
  }

  /// Delete directory
  static Future<void> deleteDirectory(String dirPath, {bool recursive = false}) async {
    try {
      final directory = Directory(dirPath);
      if (await directory.exists()) {
        await directory.delete(recursive: recursive);
      }
    } catch (e) {
      throw FileSystemException('Failed to delete directory: $e', dirPath);
    }
  }

  /// Get file size in bytes
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('File does not exist', filePath);
      }
      return await file.length();
    } catch (e) {
      throw FileSystemException('Failed to get file size: $e', filePath);
    }
  }

  /// List files in directory
  static Future<List<FileSystemEntity>> listDirectory(String dirPath, {bool recursive = false}) async {
    try {
      final directory = Directory(dirPath);
      if (!await directory.exists()) {
        throw FileSystemException('Directory does not exist', dirPath);
      }
      
      return await directory.list(recursive: recursive).toList();
    } catch (e) {
      throw FileSystemException('Failed to list directory: $e', dirPath);
    }
  }

  /// Copy file
  static Future<void> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw FileSystemException('Source file does not exist', sourcePath);
      }
      
      final destFile = File(destinationPath);
      await destFile.parent.create(recursive: true);
      await sourceFile.copy(destinationPath);
    } catch (e) {
      throw FileSystemException('Failed to copy file: $e', sourcePath);
    }
  }

  /// Move/rename file
  static Future<void> moveFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw FileSystemException('Source file does not exist', sourcePath);
      }
      
      final destFile = File(destinationPath);
      await destFile.parent.create(recursive: true);
      await sourceFile.rename(destinationPath);
    } catch (e) {
      throw FileSystemException('Failed to move file: $e', sourcePath);
    }
  }
}

/// Directory utilities
class DirectoryIO {
  /// Get current working directory
  static String getCurrentDirectory() {
    return Directory.current.path;
  }

  /// Get user's home directory
  static String? getHomeDirectory() {
    return Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  }

  /// Get temporary directory
  static String getTempDirectory() {
    return Directory.systemTemp.path;
  }

  /// Get application documents directory path
  static Future<String> getDocumentsDirectory() async {
    final home = getHomeDirectory();
    if (home != null) {
      if (Platform.isWindows) {
        return '$home\\Documents';
      } else {
        return '$home/Documents';
      }
    }
    return getTempDirectory();
  }

  /// Create timestamped directory name
  static String createTimestampedDirName(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp';
  }
}

/// Stream-based file operations
class StreamIO {
  /// Read file as stream
  static Stream<List<int>> readFileStream(String filePath) {
    final file = File(filePath);
    return file.openRead();
  }

  /// Write stream to file
  static Future<void> writeFileStream(String filePath, Stream<List<int>> stream) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    
    final sink = file.openWrite();
    try {
      await sink.addStream(stream);
    } finally {
      await sink.close();
    }
  }

  /// Read text file line by line
  static Stream<String> readLinesStream(String filePath) {
    final file = File(filePath);
    return file.openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
  }
}

/// Log file utilities
class LogIO {
  static String? _logFilePath;
  
  /// Initialize log file
  static void initLogFile(String filePath) {
    _logFilePath = filePath;
  }

  /// Write log entry
  static Future<void> log(String message, {String level = 'INFO'}) async {
    if (_logFilePath == null) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] [$level] $message\n';
    
    try {
      await FileIO.writeTextFile(_logFilePath!, logEntry, append: true);
    } catch (e) {
      print('Failed to write log: $e');
    }
  }

  /// Log info message
  static Future<void> info(String message) => log(message, level: 'INFO');
  
  /// Log warning message
  static Future<void> warn(String message) => log(message, level: 'WARN');
  
  /// Log error message
  static Future<void> error(String message) => log(message, level: 'ERROR');
  
  /// Log debug message
  static Future<void> debug(String message) => log(message, level: 'DEBUG');

  /// Clear log file
  static Future<void> clearLog() async {
    if (_logFilePath != null) {
      await FileIO.writeTextFile(_logFilePath!, '');
    }
  }

  /// Read recent log entries
  static Future<List<String>> getRecentLogs({int maxLines = 100}) async {
    if (_logFilePath == null) return [];
    
    try {
      final lines = await StreamIO.readLinesStream(_logFilePath!).toList();
      return lines.length > maxLines 
          ? lines.sublist(lines.length - maxLines)
          : lines;
    } catch (e) {
      return [];
    }
  }
}

/// Configuration file manager
class ConfigIO {
  final String _configPath;
  Map<String, dynamic> _config = {};

  ConfigIO(this._configPath);

  /// Load configuration from file
  Future<void> load() async {
    try {
      if (await FileIO.fileExists(_configPath)) {
        _config = await FileIO.readJsonFile(_configPath);
      }
    } catch (e) {
      print('Failed to load config: $e');
      _config = {};
    }
  }

  /// Save configuration to file
  Future<void> save() async {
    try {
      await FileIO.writeJsonFile(_configPath, _config);
    } catch (e) {
      print('Failed to save config: $e');
    }
  }

  /// Get configuration value
  T? get<T>(String key, [T? defaultValue]) {
    return _config[key] as T? ?? defaultValue;
  }

  /// Set configuration value
  void set<T>(String key, T value) {
    _config[key] = value;
  }

  /// Remove configuration key
  void remove(String key) {
    _config.remove(key);
  }

  /// Check if key exists
  bool contains(String key) {
    return _config.containsKey(key);
  }

  /// Get all configuration keys
  Iterable<String> get keys => _config.keys;

  /// Clear all configuration
  void clear() {
    _config.clear();
  }
}