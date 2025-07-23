import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_messenger_app/models/note_model.dart';

class NotesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notes';

  // Get all notes for a user as a stream
  Stream<List<NoteModel>> getNotesStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NoteModel.fromFirestore(doc))
            .toList());
  }

  // Get a single note
  Future<NoteModel?> getNote(String noteId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(noteId).get();
      if (doc.exists) {
        return NoteModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get note: $e');
    }
  }

  // Add a new note
  Future<String> addNote(NoteModel note) async {
    try {
      final docRef = await _firestore.collection(_collection).add(note.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add note: $e');
    }
  }

  // Update an existing note
  Future<void> updateNote(NoteModel note) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(note.id)
          .update(note.toFirestore());
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  // Delete a note
  Future<void> deleteNote(String noteId) async {
    try {
      await _firestore.collection(_collection).doc(noteId).delete();
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }

  // Batch operations for better performance
  Future<void> batchUpdateNotes(List<NoteModel> notes) async {
    try {
      final batch = _firestore.batch();
      
      for (final note in notes) {
        final docRef = _firestore.collection(_collection).doc(note.id);
        batch.update(docRef, note.toFirestore());
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update notes: $e');
    }
  }

  // Get notes by filter (for offline support)
  Future<List<NoteModel>> getNotesByFilter({
    required String userId,
    bool? isPinned,
    bool? isFavorite,
    bool? isArchived,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId);

      if (isPinned != null) {
        query = query.where('isPinned', isEqualTo: isPinned);
      }
      if (isFavorite != null) {
        query = query.where('isFavorite', isEqualTo: isFavorite);
      }
      if (isArchived != null) {
        query = query.where('isArchived', isEqualTo: isArchived);
      }

      query = query.orderBy('updatedAt', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => NoteModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get filtered notes: $e');
    }
  }

  // Search notes (for when real-time search is not needed)
  Future<List<NoteModel>> searchNotes({
    required String userId,
    required String searchQuery,
    int limit = 50,
  }) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation. For production, consider using
      // Algolia, Elasticsearch, or Cloud Functions for advanced search
      
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isArchived', isEqualTo: false)
          .orderBy('updatedAt', descending: true)
          .limit(limit * 2) // Get more to filter locally
          .get();

      final notes = snapshot.docs
          .map((doc) => NoteModel.fromFirestore(doc))
          .toList();

      // Filter locally for search
      final query = searchQuery.toLowerCase();
      return notes.where((note) {
        final titleMatch = note.title.toLowerCase().contains(query);
        final contentMatch = note.content.toLowerCase().contains(query);
        final tagsMatch = note.tags.any((tag) => tag.toLowerCase().contains(query));
        return titleMatch || contentMatch || tagsMatch;
      }).take(limit).toList();
    } catch (e) {
      throw Exception('Failed to search notes: $e');
    }
  }

  // Export notes as JSON
  Future<Map<String, dynamic>> exportNotesToJson(String userId) async {
    try {
      final notes = await getNotesByFilter(
        userId: userId,
        limit: 1000, // Export all notes
      );

      return {
        'exportDate': DateTime.now().toIso8601String(),
        'userId': userId,
        'notesCount': notes.length,
        'notes': notes.map((note) => note.toFirestore()).toList(),
      };
    } catch (e) {
      throw Exception('Failed to export notes: $e');
    }
  }
}
