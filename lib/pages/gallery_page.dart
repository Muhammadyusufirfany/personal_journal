import 'dart:io';
import 'package:flutter/material.dart';
import '../models/note.dart';

class GalleryPage extends StatelessWidget {
  final List<Note> notes;
  const GalleryPage({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    final imgs = notes.where((n) => n.imagePath != null).toList();
    if (imgs.isEmpty)
      return const Center(child: Text('Belum ada foto di galeri'));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8),
          itemCount: imgs.length,
          itemBuilder: (ctx, i) {
            final n = imgs[i];
            return GestureDetector(
              onTap: () => showDialog(
                  context: context,
                  builder: (_) =>
                      Dialog(child: Image.file(File(n.imagePath!)))),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(n.imagePath!), fit: BoxFit.cover)),
            );
          },
        ),
      ),
    );
  }
}
