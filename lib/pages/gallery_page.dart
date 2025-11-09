import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/note.dart';
import '../services/storage_service.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
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
      _notes = notes;
      _loading = false;
    });
  }

  List<Note> get _mediaNotes =>
      _notes.where((n) => n.imagePath != null).toList();

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final media = _mediaNotes;
    if (media.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Belum ada koleksi kegiatan dengan media. Simpan foto/ video pada catatan untuk menambah galeri.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotes,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: media.length,
        itemBuilder: (context, index) {
          final note = media[index];
          final path = note.imagePath!;
          final isVideo = path.toLowerCase().endsWith('.mp4');
          return GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => _GalleryDetailPage(note: note),
            )),
            child: Card(
              clipBehavior: Clip.hardEdge,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: isVideo
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              // For video we show a thumbnail by showing a first frame via VideoPlayer (initialized lazily)
                              _VideoThumbnail(path: path),
                              Container(
                                color: Colors.black26,
                              ),
                            ],
                          )
                        : Image.file(
                            File(path),
                            fit: BoxFit.cover,
                          ),
                  ),
                  if (isVideo)
                    const Positioned(
                      right: 6,
                      top: 6,
                      child: Icon(Icons.videocam, color: Colors.white70),
                    ),
                  Positioned(
                    left: 6,
                    bottom: 6,
                    right: 6,
                    child: Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 6),
                      child: Text(
                        note.title,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GalleryDetailPage extends StatefulWidget {
  final Note note;

  const _GalleryDetailPage({required this.note});

  @override
  State<_GalleryDetailPage> createState() => _GalleryDetailPageState();
}

class _GalleryDetailPageState extends State<_GalleryDetailPage> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.note.imagePath != null &&
        widget.note.imagePath!.toLowerCase().endsWith('.mp4')) {
      _controller = VideoPlayerController.file(File(widget.note.imagePath!))
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
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
            child: Center(
              child: path == null
                  ? const Text('Tidak ada media untuk item ini')
                  : isVideo
                      ? (_controller != null && _controller!.value.isInitialized
                          ? AspectRatio(
                              aspectRatio: _controller!.value.aspectRatio,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  VideoPlayer(_controller!),
                                  VideoProgressIndicator(_controller!,
                                      allowScrubbing: true),
                                ],
                              ),
                            )
                          : const CircularProgressIndicator())
                      : Image.file(File(path), fit: BoxFit.contain),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.note.content),
                const SizedBox(height: 8),
                Text(
                  widget.note.dateTime.toLocal().toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: isVideo && _controller != null
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  if (_controller!.value.isPlaying) {
                    _controller!.pause();
                  } else {
                    _controller!.play();
                  }
                });
              },
              child: Icon(_controller!.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow),
            )
          : null,
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  final String path;

  const _VideoThumbnail({required this.path});

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        // pause immediately, we only want a frozen frame
        _controller?.pause();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(color: Colors.black12);
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller!.value.size.width,
        height: _controller!.value.size.height,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}
