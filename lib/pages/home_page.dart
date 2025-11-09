import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../models/note.dart';
import '../services/storage_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Note> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await StorageService.readNotes();
    setState(() {
      _notes = notes.reversed.toList(); // show newest first
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.book, size: 80, color: Colors.indigo),
              SizedBox(height: 20),
              Text(
                "Selamat Datang di Personal Journal",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                "Belum ada catatan. Buat catatan baru pada tab Notes.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotes,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: note.imagePath != null
                  ? Icon(
                      note.imagePath!.endsWith('.mp4')
                          ? Icons.videocam
                          : Icons.photo,
                      color: Colors.indigo,
                    )
                  : const Icon(Icons.note, color: Colors.indigo),
              title: Text(note.title),
              subtitle: Text(
                note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                DateFormat('dd/MM/yyyy').format(note.dateTime),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => NoteDetailPage(note: note),
              )),
            ),
          );
        },
      ),
    );
  }
}

class NoteDetailPage extends StatefulWidget {
  final Note note;

  const NoteDetailPage({Key? key, required this.note}) : super(key: key);

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.note.imagePath != null &&
        widget.note.imagePath!.toLowerCase().endsWith('.mp4')) {
      _videoController =
          VideoPlayerController.file(File(widget.note.imagePath!))
            ..initialize().then((_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.note.imagePath;
    final isVideo = path != null && path.toLowerCase().endsWith('.mp4');

    return Scaffold(
      appBar: AppBar(title: Text(widget.note.title)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (path != null) ...[
                    Center(
                      child: isVideo
                          ? (_videoController != null &&
                                  _videoController!.value.isInitialized
                              ? AspectRatio(
                                  aspectRatio:
                                      _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                )
                              : const SizedBox(
                                  height: 200,
                                  child: Center(
                                      child: CircularProgressIndicator())))
                          : Image.file(File(path)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(widget.note.content,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  Text(
                    'Tersimpan: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.note.dateTime)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isVideo && _videoController != null
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                });
              },
              child: Icon(_videoController!.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow),
            )
          : null,
    );
  }
}
