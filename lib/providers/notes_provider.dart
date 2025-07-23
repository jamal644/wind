import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_messenger_app/models/note_model.dart';
import 'package:youtube_messenger_app/services/notes_service.dart';

class NotesProvider with ChangeNotifier {
  final NotesService _notesService = NotesService();
  
  List<NoteModel> _notes = [];
  List<NoteModel> _filteredNotes = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, pinned, favorites, archived
  StreamSubscription<List<NoteModel>>? _notesSubscription;

  // Getters
  List<NoteModel> get notes => _filteredNotes;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;

  // Initialize notes stream for a user
  void initializeNotes(String userId) {
    _setLoading(true);
    _notesSubscription?.cancel();
    
    _notesSubscription = _notesService.getNotesStream(userId).listen(
      (notes) {
        _notes = notes;
        _applyFilters();
        _setLoading(false);
      },
      onError: (error) {
        debugPrint('Error loading notes: $error');
        _setLoading(false);
      },
    );
  }

  // Search notes
  void searchNotes(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  // Set filter
  void setFilter(String filter) {
    _selectedFilter = filter;
    _applyFilters();
  }

  // Apply filters and search
  void _applyFilters() {
    List<NoteModel> filtered = List.from(_notes);

    // Apply status filter
    switch (_selectedFilter) {
      case 'pinned':
        filtered = filtered.where((note) => note.isPinned && !note.isArchived).toList();
        break;
      case 'favorites':
        filtered = filtered.where((note) => note.isFavorite && !note.isArchived).toList();
        break;
      case 'archived':
        filtered = filtered.where((note) => note.isArchived).toList();
        break;
      default: // 'all'
        filtered = filtered.where((note) => !note.isArchived).toList();
        break;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((note) {
        final titleMatch = note.title.toLowerCase().contains(_searchQuery);
        final contentMatch = note.content.toLowerCase().contains(_searchQuery);
        final tagsMatch = note.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
        return titleMatch || contentMatch || tagsMatch;
      }).toList();
    }

    // Sort notes: pinned first, then by updated date
    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    _filteredNotes = filtered;
    notifyListeners();
  }

  // Add note
  Future<void> addNote(NoteModel note) async {
    try {
      await _notesService.addNote(note);
    } catch (e) {
      debugPrint('Error adding note: $e');
      rethrow;
    }
  }

  // Update note
  Future<void> updateNote(NoteModel note) async {
    try {
      final updatedNote = note.copyWith(updatedAt: DateTime.now());
      await _notesService.updateNote(updatedNote);
    } catch (e) {
      debugPrint('Error updating note: $e');
      rethrow;
    }
  }

  // Delete note
  Future<void> deleteNote(String noteId) async {
    try {
      await _notesService.deleteNote(noteId);
    } catch (e) {
      debugPrint('Error deleting note: $e');
      rethrow;
    }
  }

  // Toggle pin status
  Future<void> togglePin(NoteModel note) async {
    try {
      final updatedNote = note.copyWith(
        isPinned: !note.isPinned,
        updatedAt: DateTime.now(),
      );
      await _notesService.updateNote(updatedNote);
    } catch (e) {
      debugPrint('Error toggling pin: $e');
      rethrow;
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(NoteModel note) async {
    try {
      final updatedNote = note.copyWith(
        isFavorite: !note.isFavorite,
        updatedAt: DateTime.now(),
      );
      await _notesService.updateNote(updatedNote);
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }

  // Toggle archive status
  Future<void> toggleArchive(NoteModel note) async {
    try {
      final updatedNote = note.copyWith(
        isArchived: !note.isArchived,
        updatedAt: DateTime.now(),
      );
      await _notesService.updateNote(updatedNote);
    } catch (e) {
      debugPrint('Error toggling archive: $e');
      rethrow;
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _notesSubscription?.cancel();
    _notes.clear();
    _filteredNotes.clear();
    _searchQuery = '';
    _selectedFilter = 'all';
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    super.dispose();
  }
}
