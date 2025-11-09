import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../models/note.dart';
import '../services/storage_service.dart';

class NotePage extends StatefulWidget {
  const NotePage({super.key});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _mediaFile;
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await StorageService.readNotes();
    setState(() {
      _notes = notes;
    });
  }

  Future<void> _takePicture() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _mediaFile = File(photo.path);
        _isVideo = false;
        _videoController?.dispose();
        _videoController = null;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _mediaFile = File(image.path);
        _isVideo = false;
        _videoController?.dispose();
        _videoController = null;
      });
    }
  }

  Future<void> _recordVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      final videoFile = File(video.path);
      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();

      setState(() {
        _mediaFile = videoFile;
        _isVideo = true;
        _videoController?.dispose();
        _videoController = controller;
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      final videoFile = File(video.path);
      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();

      setState(() {
        _mediaFile = videoFile;
        _isVideo = true;
        _videoController?.dispose();
        _videoController = controller;
      });
    }
  }

  void _toggleVideo() {
    if (_videoController != null) {
      setState(() {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
      });
    }
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan konten catatan harus diisi!')),
      );
      return;
    }

    String? mediaPath;
    if (_mediaFile != null) {
      final dir = await getApplicationDocumentsDirectory();
      final extension = _isVideo ? '.mp4' : '.jpg';
      final fileName =
          'media_${DateTime.now().millisecondsSinceEpoch}$extension';
      mediaPath = p.join(dir.path, fileName);
      await _mediaFile!.copy(mediaPath);
    }

    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      content: _contentController.text,
      dateTime: DateTime.now(),
      imagePath: mediaPath,
    );

    _notes.add(note);
    await StorageService.saveNotes(_notes);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan berhasil tersimpan!')));

    // Reset form
    _titleController.clear();
    _contentController.clear();
    setState(() {
      _mediaFile = null;
      _isVideo = false;
      _videoController?.dispose();
      _videoController = null;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: "Judul Catatan",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Tulis Catatan",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: _takePicture,
                      icon: const Icon(Icons.camera_alt),
                      tooltip: 'Ambil Foto',
                    ),
                    IconButton(
                      onPressed: _recordVideo,
                      icon: const Icon(Icons.videocam),
                      tooltip: 'Rekam Video',
                    ),
                    IconButton(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      tooltip: 'Pilih Foto dari Galeri',
                    ),
                    IconButton(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.video_library),
                      tooltip: 'Pilih Video dari Galeri',
                    ),
                  ],
                ),
                if (_mediaFile != null) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: _isVideo
                        ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                VideoPlayer(_videoController!),
                                IconButton(
                                  icon: Icon(
                                    _videoController!.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                  onPressed: _toggleVideo,
                                ),
                              ],
                            ),
                          )
                        : Image.file(_mediaFile!),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _saveNote,
                      icon: const Icon(Icons.save),
                      label: const Text("Simpan Catatan"),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _loadNotes,
                      icon: const Icon(Icons.download),
                      label: const Text("Muat"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Daftar catatan
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Catatan Tersimpan:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              final note = _notes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(note.title),
                  subtitle: Text(
                    note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(note.dateTime),
                    style: const TextStyle(fontSize: 12),
                  ),
                  leading: note.imagePath != null
                      ? Icon(
                          note.imagePath!.endsWith('.mp4')
                              ? Icons.video_file
                              : Icons.image,
                          color: Colors.indigo,
                        )
                      : const Icon(Icons.note, color: Colors.indigo),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
