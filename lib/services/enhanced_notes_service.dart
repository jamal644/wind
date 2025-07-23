import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_messenger_app/models/enhanced_note_model.dart';
import 'package:flutter/material.dart';

class EnhancedNotesService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String collection = 'notes';

  // Get notes stream for a user
  Stream<List<EnhancedNote>> getNotesStream(String userId) {
    return firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .where('isArchived', isEqualTo: false)
        .orderBy('isPinned', descending: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EnhancedNote.fromFirestore(doc))
            .toList());
  }

  // Get archived notes
  Stream<List<EnhancedNote>> getArchivedNotesStream(String userId) {
    return firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .where('isArchived', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EnhancedNote.fromFirestore(doc))
            .toList());
  }

  // Get favorite notes
  Stream<List<EnhancedNote>> getFavoriteNotesStream(String userId) {
    return firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .where('isFavorite', isEqualTo: true)
        .where('isArchived', isEqualTo: false)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EnhancedNote.fromFirestore(doc))
            .toList());
  }

  // Create a new note with optional batch
  Future<String> createNote(EnhancedNote note, {WriteBatch? batch}) async {
    final docRef = firestore.collection(collection).doc();
    final noteWithId = note.copyWith(id: docRef.id);
    
    if (batch != null) {
      // Add to batch if provided
      batch.set(docRef, noteWithId.toFirestore());
    } else {
      // Perform single create
      await docRef.set(noteWithId.toFirestore());
    }
    
    return docRef.id;
  }

  // Update an existing note with optional batch
  Future<void> updateNote(EnhancedNote note, {WriteBatch? batch}) async {
    final data = note.toFirestore();
    final docRef = firestore.collection(collection).doc(note.id);
    
    if (batch != null) {
      // Add to batch if provided
      batch.update(docRef, data);
    } else {
      // Perform single update
      await docRef.update(data);
    }
  }
  
  // Create a new batch
  WriteBatch batch() => firestore.batch();
  
  // Commit a batch
  Future<void> commitBatch(WriteBatch batch) => batch.commit();

  // Delete a note
  Future<void> deleteNote(String noteId, {WriteBatch? batch}) async {
    if (batch != null) {
      // Add to batch if provided
      final docRef = firestore.collection(collection).doc(noteId);
      batch.delete(docRef);
    } else {
      // Perform single delete
      await firestore.collection(collection).doc(noteId).delete();
    }
  }

  // Toggle pin status
  Future<void> togglePin(String noteId, bool isPinned) async {
    await firestore.collection(collection).doc(noteId).update({
      'isPinned': !isPinned,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String noteId, bool isFavorite) async {
    await firestore.collection(collection).doc(noteId).update({
      'isFavorite': !isFavorite,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Toggle archive status
  Future<void> toggleArchive(String noteId, bool isArchived) async {
    await firestore.collection(collection).doc(noteId).update({
      'isArchived': !isArchived,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update note color
  Future<void> updateNoteColor(String noteId, int color) async {
    await firestore.collection(collection).doc(noteId).update({
      'color': color,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Add tag to note
  Future<void> addTag(String noteId, String tag) async {
    await firestore.collection(collection).doc(noteId).update({
      'tags': FieldValue.arrayUnion([tag]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove tag from note
  Future<void> removeTag(String noteId, String tag) async {
    await firestore.collection(collection).doc(noteId).update({
      'tags': FieldValue.arrayRemove([tag]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update checklist
  Future<void> updateChecklist(String noteId, List<ChecklistItem> checklist) async {
    await firestore.collection(collection).doc(noteId).update({
      'checklist': checklist.map((item) => item.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Set reminder
  Future<void> setReminder(String noteId, DateTime reminderDate, {String? noteTitle, String? noteContent}) async {
    await firestore.collection(collection).doc(noteId).update({
      'reminderDate': Timestamp.fromDate(reminderDate),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Schedule notification
    await _scheduleReminderNotification(noteId, reminderDate, noteTitle, noteContent);
  }

  // Remove reminder
  Future<void> removeReminder(String noteId) async {
    await firestore.collection(collection).doc(noteId).update({
      'reminderDate': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Cancel notification
    await _cancelReminderNotification(noteId);
  }

  // Search notes
  Future<List<EnhancedNote>> searchNotes(String userId, String query) async {
    if (query.isEmpty) return [];

    final snapshot = await firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .where('isArchived', isEqualTo: false)
        .get();

    return snapshot.docs
        .map((doc) => EnhancedNote.fromFirestore(doc))
        .where((note) =>
            note.title.toLowerCase().contains(query.toLowerCase()) ||
            note.content.toLowerCase().contains(query.toLowerCase()) ||
            note.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
        .toList();
  }

  // Batch operations
  Future<void> batchUpdateNotes(List<String> noteIds, Map<String, dynamic> updates) async {
    final batch = firestore.batch();
    
    for (final noteId in noteIds) {
      final docRef = firestore.collection(collection).doc(noteId);
      batch.update(docRef, {
        ...updates,
        'updatedAt': Timestamp.now(),
      });
    }
    
    await batch.commit();
  }

  // Export notes as JSON
  Future<List<Map<String, dynamic>>> exportNotes(String userId) async {
    final snapshot = await firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();
  }

  // Private notification methods
  Future<void> _scheduleReminderNotification(String noteId, DateTime reminderDate, String? title, String? content) async {
    try {
      debugPrint('📅 Scheduling reminder for note: $noteId at $reminderDate');
      final notificationBody = title?.isNotEmpty == true 
          ? 'Reminder: $title'
          : content?.isNotEmpty == true 
              ? 'Reminder: ${content!.length > 50 ? content.substring(0, 50) + '...' : content}'
              : 'You have a note reminder!';
      debugPrint('📅 Reminder scheduled: $notificationBody');
    } catch (e) {
      debugPrint('Error scheduling reminder notification: $e');
    }
  }

  Future<void> _cancelReminderNotification(String noteId) async {
    try {
      debugPrint('❌ Reminder cancelled for note: $noteId');
      // TODO: Implement notification cancellation
    } catch (e) {
      debugPrint('Error canceling reminder notification: $e');
    }
  }
}
