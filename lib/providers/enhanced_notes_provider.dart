import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_messenger_app/models/enhanced_note_model.dart';
import 'package:youtube_messenger_app/services/enhanced_notes_service.dart';

class EnhancedNotesProvider extends ChangeNotifier {
  final EnhancedNotesService _notesService = EnhancedNotesService();

  List<EnhancedNote> _notes = [];
  List<EnhancedNote> _archivedNotes = [];
  List<EnhancedNote> _favoriteNotes = [];
  List<EnhancedNote> _searchResults = [];

  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  String _currentFilter = 'all'; // 'all', 'pinned', 'favorites', 'archived'
  String _currentView = 'grid'; // 'grid', 'list'

  StreamSubscription<List<EnhancedNote>>? _notesSubscription;
  StreamSubscription<List<EnhancedNote>>? _archivedSubscription;
  StreamSubscription<List<EnhancedNote>>? _favoritesSubscription;

  Timer? _searchDebounceTimer;

  // Getters
  List<EnhancedNote> get notes => _notes;
  List<EnhancedNote> get archivedNotes => _archivedNotes;
  List<EnhancedNote> get favoriteNotes => _favoriteNotes;
  List<EnhancedNote> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  String get currentFilter => _currentFilter;
  String get currentView => _currentView;

  // Get filtered notes based on current filter
  List<EnhancedNote> get filteredNotes {
    if (_isSearching && _searchQuery.isNotEmpty) {
      return _searchResults;
    }

    switch (_currentFilter) {
      case 'pinned':
        return _notes.where((note) => note.isPinned).toList();
      case 'favorites':
        return _favoriteNotes;
      case 'archived':
        return _archivedNotes;
      default:
        return _notes;
    }
  }

  // Initialize notes streams for a user
  void initializeNotes(String userId) {
    _setLoading(true);

    // Listen to main notes
    _notesSubscription = _notesService.getNotesStream(userId).listen(
      (notes) {
        _notes = notes;
        _setLoading(false);
        notifyListeners();
      },
      onError: (error) {
        _setLoading(false);
        debugPrint('Error loading notes: $error');
      },
    );

    // Listen to archived notes
    _archivedSubscription = _notesService.getArchivedNotesStream(userId).listen(
      (archivedNotes) {
        _archivedNotes = archivedNotes;
        notifyListeners();
      },
    );

    // Listen to favorite notes
    _favoritesSubscription =
        _notesService.getFavoriteNotesStream(userId).listen(
      (favoriteNotes) {
        _favoriteNotes = favoriteNotes;
        notifyListeners();
      },
    );
  }

  // Create a new note with optional batch
  Future<void> createNote(EnhancedNote note, {WriteBatch? batch}) async {
    try {
      if (batch != null) {
        // Add to batch if provided
        await _notesService.createNote(note, batch: batch);
      } else {
        // Create a new batch for single operation
        final batch = _notesService.batch();
        await _notesService.createNote(note, batch: batch);
        await _notesService.commitBatch(batch);
      }
    } catch (e) {
      debugPrint('Error creating note: $e');
      rethrow;
    }
  }

  Timer? _saveDebounceTimer;
  WriteBatch? _currentBatch;
  
  // Start a new batch for multiple operations
  WriteBatch startBatch() {
    _currentBatch?.commit().catchError((e) {
      debugPrint('Error committing batch: $e');
    });
    return _currentBatch = _notesService.batch();
  }
  
  // Commit the current batch
  Future<void> commitBatch() async {
    if (_currentBatch != null) {
      await _notesService.commitBatch(_currentBatch!);
      _currentBatch = null;
    }
  }
  
  // Update an existing note with debounce for better performance during typing
  Future<void> updateNote(EnhancedNote note, {WriteBatch? batch}) async {
    try {
      // Cancel any pending updates for this note
      _saveDebounceTimer?.cancel();
      
      // Use a Completer to handle the async operation
      final completer = Completer<void>();
      
      // Create a debounced update
      _saveDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
        try {
          final updatedNote = note.copyWith(updatedAt: DateTime.now());
          
          WriteBatch targetBatch;
          bool shouldCommit = false;
          
          if (batch != null) {
            // Use the provided batch
            targetBatch = batch;
          } else if (_currentBatch != null) {
            // Use the current batch
            targetBatch = _currentBatch!;
          } else {
            // Create a new batch for single operation
            targetBatch = _notesService.batch();
            shouldCommit = true;
          }
          
          // Add to batch
          await _notesService.updateNote(updatedNote, batch: targetBatch);
          
          // Commit if this was a new batch
          if (shouldCommit) {
            await _notesService.commitBatch(targetBatch);
          }
          
          if (!completer.isCompleted) {
            completer.complete();
          }
        } catch (e, stackTrace) {
          debugPrint('Error in debounced note update: $e');
          debugPrint('Stack trace: $stackTrace');
          
          if (!completer.isCompleted) {
            completer.completeError(e, stackTrace);
          }
          
          // Show error to user
          // Log the error for debugging
          debugPrint('Error in debounced note update: $e');
          debugPrint('Stack trace: $stackTrace');
          
          // The error will be handled by the caller which has access to context
        }
      });
      
      // Return the future that completes when the save is done
      return completer.future;
    } catch (e) {
      debugPrint('Error queuing note update: $e');
      rethrow;
    }
  }

  // Delete a note
  Future<void> deleteNote(String noteId) async {
    try {
      await _notesService.deleteNote(noteId);
    } catch (e) {
      debugPrint('Error deleting note: $e');
      rethrow;
    }
  }

  // Toggle pin status
  Future<void> togglePin(String noteId, bool isPinned) async {
    try {
      await _notesService.togglePin(noteId, !isPinned);
    } catch (e) {
      debugPrint('Error toggling pin: $e');
      rethrow;
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String noteId, bool isFavorite) async {
    try {
      await _notesService.toggleFavorite(noteId, !isFavorite);
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }

  // Toggle archive status
  Future<void> toggleArchive(String noteId, bool isArchived) async {
    try {
      await _notesService.toggleArchive(noteId, !isArchived);
    } catch (e) {
      debugPrint('Error toggling archive: $e');
      rethrow;
    }
  }

  // Update note color
  Future<void> updateNoteColor(String noteId, int color) async {
    try {
      await _notesService.updateNoteColor(noteId, color);
    } catch (e) {
      debugPrint('Error updating note color: $e');
      rethrow;
    }
  }

  // Add tag to note
  Future<void> addTag(String noteId, String tag) async {
    try {
      await _notesService.addTag(noteId, tag);
    } catch (e) {
      debugPrint('Error adding tag: $e');
      rethrow;
    }
  }

  // Remove tag from note
  Future<void> removeTag(String noteId, String tag) async {
    try {
      await _notesService.removeTag(noteId, tag);
    } catch (e) {
      debugPrint('Error removing tag: $e');
      rethrow;
    }
  }

  // Update checklist
  Future<void> updateChecklist(
      String noteId, List<ChecklistItem> checklist) async {
    try {
      await _notesService.updateChecklist(noteId, checklist);
    } catch (e) {
      debugPrint('Error updating checklist: $e');
      rethrow;
    }
  }

  // Set reminder
  Future<void> setReminder(String noteId, DateTime reminderDate) async {
    try {
      // Find the note to get title and content for notification
      final note = _notes.firstWhere((n) => n.id == noteId,
          orElse: () => _archivedNotes.firstWhere((n) => n.id == noteId,
              orElse: () => _favoriteNotes.firstWhere((n) => n.id == noteId)));

      await _notesService.setReminder(
        noteId,
        reminderDate,
        noteTitle: note.title.isNotEmpty ? note.title : null,
        noteContent: note.content.isNotEmpty ? note.content : null,
      );
    } catch (e) {
      debugPrint('Error setting reminder: $e');
      rethrow;
    }
  }

  // Remove reminder
  Future<void> removeReminder(String noteId) async {
    try {
      await _notesService.removeReminder(noteId);
    } catch (e) {
      debugPrint('Error removing reminder: $e');
      rethrow;
    }
  }

  // Search notes with debounce
  void searchNotes(String query, String userId) {
    _searchQuery = query;
    _isSearching = query.isNotEmpty;

    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    if (query.isEmpty) {
      _searchResults.clear();
      _isSearching = false;
      notifyListeners();
      return;
    }

    // Debounce search for 300ms
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await _notesService.searchNotes(userId, query);
        _searchResults = results;
        notifyListeners();
      } catch (e) {
        debugPrint('Error searching notes: $e');
      }
    });

    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _isSearching = false;
    _searchResults.clear();
    _searchDebounceTimer?.cancel();
    notifyListeners();
  }

  // Set filter
  void setFilter(String filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  // Toggle view between grid and list
  void toggleView() {
    _currentView = _currentView == 'grid' ? 'list' : 'grid';
    notifyListeners();
  }

  // Batch operations
  Future<void> batchArchive(List<String> noteIds) async {
    try {
      await _notesService.batchUpdateNotes(noteIds, {'isArchived': true});
    } catch (e) {
      debugPrint('Error batch archiving: $e');
      rethrow;
    }
  }

  Future<void> batchDelete(List<String> noteIds) async {
    try {
      for (final noteId in noteIds) {
        await _notesService.deleteNote(noteId);
      }
    } catch (e) {
      debugPrint('Error batch deleting: $e');
      rethrow;
    }
  }

  // Export notes
  Future<List<Map<String, dynamic>>> exportNotes(String userId) async {
    try {
      return await _notesService.exportNotes(userId);
    } catch (e) {
      debugPrint('Error exporting notes: $e');
      rethrow;
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Dispose
  @override
  void dispose() {
    _notesSubscription?.cancel();
    _archivedSubscription?.cancel();
    _favoritesSubscription?.cancel();
    _searchDebounceTimer?.cancel();
    _saveDebounceTimer?.cancel();
    super.dispose();
  }
}
