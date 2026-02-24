import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isFavorite': isFavorite,
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    isFavorite: json['isFavorite'] as bool? ?? false,
  );
}

class NotesService {
  static const String _storageKey = 'notes_list';

  Future<List<Note>> loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null) return [];

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map((item) => Note.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveNotes(List<Note> notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        notes.map((note) => note.toJson()).toList(),
      );
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addNote(Note note) async {
    final notes = await loadNotes();
    notes.add(note);
    await saveNotes(notes);
  }

  Future<void> updateNote(Note note) async {
    final notes = await loadNotes();
    final index = notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      notes[index] = note;
      await saveNotes(notes);
    }
  }

  Future<void> deleteNote(String id) async {
    final notes = await loadNotes();
    notes.removeWhere((n) => n.id == id);
    await saveNotes(notes);
  }

  Future<void> toggleFavorite(String id) async {
    final notes = await loadNotes();
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      final note = notes[index];
      notes[index] = Note(
        id: note.id,
        title: note.title,
        content: note.content,
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
        isFavorite: !note.isFavorite,
      );
      await saveNotes(notes);
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Thông tin sinh viên - Có thể thay đổi
  static const String studentName = 'Nông Lan Anh';
  static const String studentId = '2351060417';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Note',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9C6FB1), // Soft purple
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF9C6FB1),
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotesService _notesService = NotesService();
  late Future<List<Note>> _notesFuture;
  final TextEditingController _searchController = TextEditingController();
  List<Note> _allNotes = [];
  List<Note> _filteredNotes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchController.addListener(_filterNotes);
  }

  void _loadNotes() {
    _notesFuture = _notesService.loadNotes().then((notes) {
      _allNotes = notes;
      _filterNotes();
      return notes;
    });
  }

  void _filterNotes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredNotes = _allNotes;
      } else {
        _filteredNotes = _allNotes
            .where((note) => note.title.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showNoteEditSheet(BuildContext context, {Note? note}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditNoteBottomSheet(
        note: note,
        onSave: () {
          _loadNotes();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Note>>(
      future: _notesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF5F1FF), Color(0xFFFFECF8)],
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF9C6FB1)),
              ),
            ),
          );
        }

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF5F1FF), Color(0xFFFFECF8)],
              ),
            ),
            child: Column(
              children: [
                // Custom AppBar (Always Visible)
                Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16 + MediaQuery.of(context).padding.top,
                    20,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.spa, color: Color(0xFF9C6FB1), size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Smart Note',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6B4C7A),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  '${MyApp.studentName} • ${MyApp.studentId}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Rest of the content
                Expanded(
                  child: _allNotes.isEmpty && _searchController.text.isEmpty
                      ? _buildSimpleEmptyState()
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              // Search Bar
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(
                                          0xFF9C6FB1,
                                        ).withOpacity(0.1),
                                        blurRadius: 12,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: 'Tìm kiếm ghi chú...',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: Color(0xFF9C6FB1),
                                        size: 22,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: Color(
                                            0xFF9C6FB1,
                                          ).withOpacity(0.25),
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: Color(
                                            0xFF9C6FB1,
                                          ).withOpacity(0.25),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: Color(0xFF9C6FB1),
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.95),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                    style: TextStyle(
                                      color: Color(0xFF6B4C7A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),
                              // Notes Grid or Empty State
                              if (_filteredNotes.isEmpty)
                                _buildEmptyState()
                              else
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: GridView.builder(
                                    physics: NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 16,
                                          crossAxisSpacing: 16,
                                          childAspectRatio: 0.82,
                                        ),
                                    itemCount: _filteredNotes.length,
                                    itemBuilder: (context, index) {
                                      final note = _filteredNotes[index];
                                      return _buildNoteCard(note, index);
                                    },
                                  ),
                                ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _showNoteEditSheet(context);
            },
            child: const Icon(Icons.add, size: 28),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF9C6FB1).withOpacity(0.1),
                  Color(0xFFF39FBD).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Center(
              child: Icon(
                _allNotes.isEmpty ? Icons.note_outlined : Icons.search_off,
                size: 60,
                color: Color(0xFF9C6FB1),
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            _allNotes.isEmpty
                ? 'Bạn chưa có ghi chú nào'
                : 'Không tìm thấy ghi chú',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B4C7A),
            ),
          ),
          SizedBox(height: 8),
          Text(
            _allNotes.isEmpty
                ? 'Hãy tạo ghi chú đầu tiên của bạn'
                : 'Thử tìm kiếm với từ khóa khác',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9C6FB1).withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF9C6FB1).withOpacity(0.15),
                  Color(0xFFF39FBD).withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Center(
              child: Icon(
                Icons.note_outlined,
                size: 60,
                color: Color(0xFF9C6FB1),
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Bạn chưa có ghi chú nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B4C7A),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Hãy tạo ghi chú đầu tiên của bạn',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9C6FB1).withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note, int index) {
    final gradients = [
      [Color(0xFFFFD6E8), Color(0xFFF5D4E6)], // Pink
      [Color(0xFFE6D5FF), Color(0xFFF1E6FF)], // Purple
      [Color(0xFFD4F1FF), Color(0xFFE6F4FF)], // Blue
      [Color(0xFFFFE8D6), Color(0xFFFFF1E6)], // Peach
    ];

    final List<Color> cardGradient = gradients[index % 4];

    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Color(0xFFFF6B9D),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xóa ghi chú'),
            content: const Text('Bạn có chắc chắn muốn xóa ghi chú này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        if (result == true) {
          await _notesService.deleteNote(note.id);
          _loadNotes();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ghi chú đã được xóa')),
            );
          }
        }

        return result ?? false;
      },
      child: GestureDetector(
        onTap: () {
          _showNoteEditSheet(context, note: note);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF9C6FB1).withOpacity(0.12),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: cardGradient,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Decorative dot
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(0xFF9C6FB1).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await _notesService.toggleFavorite(note.id);
                            _loadNotes();
                          },
                          child: Icon(
                            note.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_outline,
                            size: 18,
                            color: note.isFavorite
                                ? Color(0xFFFF6B9D)
                                : Color(0xFF9C6FB1).withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    // Title
                    Text(
                      note.title.isEmpty ? 'Ghi chú không tiêu đề' : note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Color(0xFF6B4C7A),
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 8),
                    // Content
                    Text(
                      note.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF6B4C7A).withOpacity(0.7),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    Spacer(),
                    // Timestamp
                    Text(
                      DateFormat('dd/MM HH:mm').format(note.updatedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9C6FB1).withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EditNoteBottomSheet extends StatefulWidget {
  final Note? note;
  final VoidCallback onSave;

  const EditNoteBottomSheet({super.key, this.note, required this.onSave});

  @override
  State<EditNoteBottomSheet> createState() => _EditNoteBottomSheetState();
}

class _EditNoteBottomSheetState extends State<EditNoteBottomSheet> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final NotesService _notesService = NotesService();
  late Note _currentNote;
  bool _isNew = false;

  @override
  void initState() {
    super.initState();
    _isNew = widget.note == null;

    if (_isNew) {
      _currentNote = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '',
        content: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } else {
      _currentNote = widget.note!;
    }

    _titleController = TextEditingController(text: _currentNote.title);
    _contentController = TextEditingController(text: _currentNote.content);
  }

  Future<void> _saveNote() async {
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      Navigator.pop(context);
      return;
    }

    _currentNote = Note(
      id: _currentNote.id,
      title: _titleController.text,
      content: _contentController.text,
      createdAt: _currentNote.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      if (_isNew) {
        await _notesService.addNote(_currentNote);
      } else {
        await _notesService.updateNote(_currentNote);
      }

      if (!mounted) return;
      widget.onSave();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lỗi khi lưu ghi chú')));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F1FF), Color(0xFFFFECF8)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle Bar
                Container(
                  margin: EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Color(0xFF9C6FB1).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Close Button (Save & Close)
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _saveNote,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF9C6FB1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            size: 22,
                            color: Color(0xFF9C6FB1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Header
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        _isNew ? 'Ghi chú mới' : 'Chỉnh sửa ghi chú',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B4C7A),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Input
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Tiêu đề ghi chú',
                          hintStyle: TextStyle(
                            color: Color(0xFF9C6FB1).withOpacity(0.4),
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B4C7A),
                          letterSpacing: 0.3,
                        ),
                        maxLines: null,
                      ),
                      SizedBox(height: 16),
                      // Content Input
                      TextField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          hintText: 'Ghi lại những điều bạn muốn nhớ...',
                          hintStyle: TextStyle(
                            color: Color(0xFF9C6FB1).withOpacity(0.3),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF6B4C7A),
                          height: 1.5,
                        ),
                        maxLines: null,
                        minLines: 10,
                      ),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
