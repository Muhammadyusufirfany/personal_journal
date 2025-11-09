import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';

class AddNotePage extends StatefulWidget {
  final Note? note;
  const AddNotePage({super.key, this.note});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final _titleCtl = TextEditingController();
  final _contentCtl = TextEditingController();
  DateTime _selected = DateTime.now();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final DateFormat _fmt = DateFormat('dd MMM yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleCtl.text = widget.note!.title;
      _contentCtl.text = widget.note!.content;
      _selected = widget.note!.dateTime;
      if (widget.note!.imagePath != null) {
        _imageFile = File(widget.note!.imagePath!);
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _pickDateTime() async {
    if (!mounted) return;
    final date = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selected),
    );
    if (time == null || !mounted) return;
    setState(() {
      _selected =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _save() {
    final title = _titleCtl.text.trim();
    final content = _contentCtl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Judul tidak boleh kosong')));
      return;
    }
    final id = widget.note?.id ?? const Uuid().v4();
    final note = Note(
        id: id,
        title: title,
        content: content,
        dateTime: _selected,
        imagePath: _imageFile?.path);
    Navigator.pop(context, note);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.note == null ? 'Tambah Catatan' : 'Edit Catatan')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView(
            children: [
              TextField(
                  controller: _titleCtl,
                  decoration: const InputDecoration(labelText: 'Judul')),
              const SizedBox(height: 12),
              TextField(
                  controller: _contentCtl,
                  decoration: const InputDecoration(labelText: 'Isi'),
                  maxLines: 6),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('Waktu: ${_fmt.format(_selected)}')),
                  TextButton(
                      onPressed: _pickDateTime,
                      child: const Text('Pilih Waktu'))
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_imageFile != null)
                    Expanded(
                        child: Image.file(_imageFile!,
                            height: 160, fit: BoxFit.cover))
                  else
                    const Expanded(
                        child: SizedBox(
                            height: 160,
                            child: Center(child: Text('Tidak ada foto')))),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Pilih Foto dari Galeri')),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _save, child: const Text('Simpan'))
            ],
          ),
        ),
      ),
    );
  }
}
