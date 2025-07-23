import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class EnhancedNote extends Equatable {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final bool isPinned;
  final bool isFavorite;
  final bool isArchived;
  final String colorTag;
  final List<String> tags;
  final List<ChecklistItem> checklist;
  final DateTime? reminderDate;
  final String noteType; // 'text', 'checklist', 'voice'
  final String? voiceNotePath;

  const EnhancedNote({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.isPinned = false,
    this.isFavorite = false,
    this.isArchived = false,
    this.colorTag = 'default',
    this.tags = const [],
    this.checklist = const [],
    this.reminderDate,
    this.noteType = 'text',
    this.voiceNotePath,
  });

  factory EnhancedNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EnhancedNote(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      isPinned: data['isPinned'] ?? false,
      isFavorite: data['isFavorite'] ?? false,
      isArchived: data['isArchived'] ?? false,
      colorTag: data['colorTag'] ?? 'default',
      tags: List<String>.from(data['tags'] ?? []),
      checklist: (data['checklist'] as List<dynamic>?)
              ?.map((item) => ChecklistItem.fromMap(item))
              .toList() ??
          [],
      reminderDate: data['reminderDate'] != null
          ? (data['reminderDate'] as Timestamp).toDate()
          : null,
      noteType: data['noteType'] ?? 'text',
      voiceNotePath: data['voiceNotePath'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
      'isPinned': isPinned,
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'colorTag': colorTag,
      'tags': tags,
      'checklist': checklist.map((item) => item.toMap()).toList(),
      'reminderDate': reminderDate != null ? Timestamp.fromDate(reminderDate!) : null,
      'noteType': noteType,
      'voiceNotePath': voiceNotePath,
    };
  }

  EnhancedNote copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    bool? isPinned,
    bool? isFavorite,
    bool? isArchived,
    String? colorTag,
    List<String>? tags,
    List<ChecklistItem>? checklist,
    DateTime? reminderDate,
    String? noteType,
    String? voiceNotePath,
  }) {
    return EnhancedNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      colorTag: colorTag ?? this.colorTag,
      tags: tags ?? this.tags,
      checklist: checklist ?? this.checklist,
      reminderDate: reminderDate ?? this.reminderDate,
      noteType: noteType ?? this.noteType,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        createdAt,
        updatedAt,
        userId,
        isPinned,
        isFavorite,
        isArchived,
        colorTag,
        tags,
        checklist,
        reminderDate,
        noteType,
        voiceNotePath,
      ];
}

class ChecklistItem extends Equatable {
  final String id;
  final String text;
  final bool isCompleted;
  final DateTime createdAt;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, text, isCompleted, createdAt];
}
