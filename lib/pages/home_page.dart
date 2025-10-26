import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../services/storage_service.dart';
import 'add_note_page.dart';
import 'gallery_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<Note> _notes = [];
  late TabController _tabController;
  final DateFormat _fmt = DateFormat('dd MMM yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await StorageService.readNotes();
    setState(() {
      _notes = notes;
    });
  }

  Future<void> _saveNotes() async {
    await StorageService.saveNotes(_notes);
  }

  void _addOrUpdateNote(Note note, {bool isUpdate = false}) {
    setState(() {
      if (isUpdate) {
        final idx = _notes.indexWhere((n) => n.id == note.id);
        if (idx != -1) _notes[idx] = note;
      } else {
        _notes.insert(0, note);
      }
    });
    _saveNotes();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan disimpan')));
  }

  void _deleteNote(String id) {
    setState(() {
      _notes.removeWhere((n) => n.id == id);
    });
    _saveNotes();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan dihapus')));
  }

  void _openAddNote() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddNotePage(note: null)));
    if (result is Note) {
      _addOrUpdateNote(result);
    }
  }

  void _openEditNote(Note note) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddNotePage(note: note)));
    if (result is Note) {
      _addOrUpdateNote(result, isUpdate: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Journal'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                showDialog(context: context, builder: (_) => AlertDialog(
                  title: const Text('Konfirmasi'),
                  content: const Text('Hapus semua catatan?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                    TextButton(onPressed: () {
                      setState(() { _notes.clear(); });
                      _saveNotes();
                      Navigator.pop(context);
                    }, child: const Text('Hapus')),
                  ],
                ));
              }
            },
            itemBuilder: (ctx) => [const PopupMenuItem(value: 'clear', child: Text('Hapus semua'))],
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Home', icon: Icon(Icons.home)), Tab(text: 'Tambah', icon: Icon(Icons.note_add)), Tab(text: 'Galeri', icon: Icon(Icons.photo))],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomeTab(),
          Center(child: ElevatedButton.icon(onPressed: _openAddNote, icon: const Icon(Icons.add), label: const Text('Tambah Catatan'))),
          GalleryPage(notes: _notes),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddNote,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _notes.isEmpty
            ? const Center(child: Text('Belum ada catatan. Tekan + untuk menambah.'))
            : ListView.builder(
                itemCount: _notes.length,
                itemBuilder: (ctx, i) {
                  final n = _notes[i];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      onTap: () => _openEditNote(n),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            if (n.imagePath != null)
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(File(n.imagePath!), fit: BoxFit.cover),
                                ),
                              )
                            else
                              Container(width: 72, height: 72, alignment: Alignment.center, child: const Icon(Icons.note, size: 36)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Text(n.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_fmt.format(n.dateTime), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      PopupMenuButton<String>(
                                        onSelected: (val) {
                                          if (val == 'edit') _openEditNote(n);
                                          if (val == 'delete') {
                                            showDialog(context: context, builder: (_) => AlertDialog(
                                              title: const Text('Konfirmasi'),
                                              content: const Text('Hapus catatan ini?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                                                TextButton(onPressed: () {
                                                  _deleteNote(n.id);
                                                  Navigator.pop(context);
                                                }, child: const Text('Hapus')),
                                              ],
                                            ));
                                          }
                                        },
                                        itemBuilder: (ctx) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Hapus'))],
                                      )
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
