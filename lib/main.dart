import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/note_page.dart';
import 'pages/gallery_page.dart';

void main() {
  runApp(const PersonalJournalApp());
}

class PersonalJournalApp extends StatefulWidget {
  const PersonalJournalApp({super.key});

  @override
  State<PersonalJournalApp> createState() => _PersonalJournalAppState();
}

class _PersonalJournalAppState extends State<PersonalJournalApp> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const NotePage(),
    const GalleryPage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Journal + Media',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Personal Journal"),
          centerTitle: true,
        ),
        body: SafeArea(child: _pages[_selectedIndex]),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.indigo,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.note), label: "Notes"),
            BottomNavigationBarItem(icon: Icon(Icons.photo), label: "Gallery"),
          ],
        ),
      ),
    );
  }
}
