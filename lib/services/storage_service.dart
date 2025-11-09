import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';

class StorageService {
  static const String fileName = 'notes_data.json';

  // Mendapatkan direktori aplikasi
  static Future<Directory> _appDir() async {
    return await getApplicationDocumentsDirectory();
  }

  // Path file
  static Future<File> _localFile() async {
    final dir = await _appDir();
    return File('${dir.path}/$fileName');
  }

  // Menyimpan list note ke file
  static Future<void> saveNotes(List<Note> notes) async {
    final file = await _localFile();
    final List<String> jsonList = notes.map((n) => n.toJson()).toList();
    await file.writeAsString(jsonList.join('\n'));
  }

  // Membaca note dari file
  static Future<List<Note>> readNotes() async {
    try {
      final file = await _localFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      final lines = content.split('\n');
      final notes = lines.map((l) => Note.fromJson(l)).toList();
      return notes;
    } catch (e) {
      return [];
    }
  }
}
