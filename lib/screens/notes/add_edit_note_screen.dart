import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:youtube_messenger_app/core/utils/async_utils.dart';
import 'package:youtube_messenger_app/models/enhanced_note_model.dart';
import 'package:youtube_messenger_app/providers/enhanced_notes_provider.dart';
import 'package:youtube_messenger_app/providers/auth_provider.dart';
import 'package:youtube_messenger_app/core/theme/app_theme.dart';
import 'package:youtube_messenger_app/widgets/color_picker_widget.dart';
import 'package:youtube_messenger_app/widgets/checklist_widget.dart';
import 'package:youtube_messenger_app/widgets/tags_widget.dart';
import 'package:youtube_messenger_app/widgets/reminder_widget.dart';

class AddEditNoteScreen extends StatefulWidget {
  final EnhancedNote? note;

  const AddEditNoteScreen({super.key, this.note});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen>
    with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();

  late AnimationController _saveAnimationController;
  late Animation<double> _saveAnimation;

  String _selectedColor = 'default';
  List<String> _tags = [];
  List<ChecklistItem> _checklist = [];
  DateTime? _reminderDate;
  String _noteType = 'text';
  bool _isPinned = false;
  bool _isFavorite = false;
  bool _isLoading = false;
  bool _isSaving = false;
  Timer? _debounceTimer;
  static const _saveDebounceTime = Duration(milliseconds: 800);

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeNote();
    debugPrint('AddEditNoteScreen initialized with note: ${widget.note?.id ?? 'new'}');
    debugPrint('Note type: $_noteType');
    debugPrint('Initial checklist items: ${_checklist.length}');
    if (widget.note != null) {
      debugPrint('Note checklist items from Firestore: ${widget.note!.checklist.length}');
      for (var i = 0; i < widget.note!.checklist.length; i++) {
        debugPrint('  Item $i: ${widget.note!.checklist[i].text} (${widget.note!.checklist[i].isCompleted})');
      }
    }
  }

  void _initializeAnimations() {
    _saveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _saveAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _saveAnimationController, curve: Curves.easeInOut),
    );
  }

  void _initializeNote() {
    if (_isEditing) {
      final note = widget.note!;
      debugPrint('Initializing note with ID: ${note.id}');
      _titleController.text = note.title;
      _contentController.text = note.content;
      _selectedColor = note.colorTag;
      _tags = List.from(note.tags);
      _checklist = List.from(note.checklist);
      _reminderDate = note.reminderDate;
      _isPinned = note.isPinned;
      _isFavorite = note.isFavorite;
      
      // Ensure note type is set correctly based on checklist content
      if (note.checklist.isNotEmpty) {
        _noteType = 'checklist';
        debugPrint('Note has checklist content, forcing note type to: checklist');
      } else {
        _noteType = note.noteType;
      }
      
      // Debug: Log the loaded checklist
      debugPrint('Loaded ${_checklist.length} checklist items for note ${note.id}');
      for (var i = 0; i <_checklist.length; i++) {
        debugPrint('  Loaded item $i: ${_checklist[i].text} (completed: ${_checklist[i].isCompleted})');
      }
      
      // If it's a checklist note but has no items, add a default one
      if (_noteType == 'checklist' && _checklist.isEmpty) {
        debugPrint('Empty checklist note, adding default item');
        _checklist = [
          ChecklistItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: '',
            isCompleted: false,
            createdAt: DateTime.now(),
          ),
        ];
      }
    } else {
      debugPrint('Initializing new note');
      // For new notes, initialize with default values
      _noteType = 'text';
      _checklist = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getNoteColor(_selectedColor),
      appBar: _buildAppBar(),
      resizeToAvoidBottomInset: false, // Prevent layout issues with keyboard
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.getNoteColor(_selectedColor),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: _handleBack,
      ),
      title: Text(
        _isEditing ? 'Edit Note' : 'New Note',
        style: AppTheme.textTheme.titleLarge?.copyWith(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        // Pin toggle
        IconButton(
          icon: Icon(
            _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            color: _isPinned ? AppTheme.primaryColor : Colors.black87,
          ),
          onPressed: () => setState(() => _isPinned = !_isPinned),
        ),
        
        // Favorite toggle
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red[400] : Colors.black87,
          ),
          onPressed: () => setState(() => _isFavorite = !_isFavorite),
        ),

        // More options
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  const Icon(Icons.archive, size: 18),
                  const SizedBox(width: 8),
                  Text(_isEditing && widget.note!.isArchived ? 'Unarchive' : 'Archive'),
                ],
              ),
            ),
            if (_isEditing)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.share, size: 18),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SafeArea(
      bottom: false, // Let the bottom bar handle the safe area
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title input
          TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            style: AppTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            decoration: const InputDecoration(
              hintText: 'Title',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),

          const SizedBox(height: 16),

          // Note type selector
          _buildNoteTypeSelector(),

          const SizedBox(height: 16),

          // Content based on note type
          _noteType == 'checklist' 
              ? ChecklistWidget(
                  key: const ValueKey('checklist-widget'),
                  checklist: _checklist,
                  onChecklistChanged: (checklist) {
                    debugPrint('Checklist changed: ${checklist.length} items');
                    setState(() => _checklist = checklist);
                  },
                )
              : TextField(
                  key: const ValueKey('content-text-field'),
                  controller: _contentController,
                  focusNode: _contentFocusNode,
                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                    color: Colors.black87,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Start writing...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),

          const SizedBox(height: 24),

          // Tags
          TagsWidget(
            tags: _tags,
            onTagsChanged: (tags) => setState(() => _tags = tags),
          ),

          const SizedBox(height: 24),

          // Reminder
          ReminderWidget(
            reminderDate: _reminderDate,
            onReminderChanged: (date) => setState(() => _reminderDate = date),
          ),

          const SizedBox(height: 24),

          // Color picker
          ColorPickerWidget(
            selectedColor: _selectedColor,
            onColorChanged: (color) => setState(() => _selectedColor = color),
          ),

          const SizedBox(height: 16), // Reduced space since we'll use SafeArea
        ],
      ),
    ));
  }

  Widget _buildNoteTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note Type',
          style: AppTheme.textTheme.titleSmall?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildTypeChip('Text', 'text', Icons.text_fields),
            const SizedBox(width: 8),
            _buildTypeChip('Checklist', 'checklist', Icons.checklist),
            const SizedBox(width: 8),
            _buildTypeChip('Voice', 'voice', Icons.mic),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeChip(String label, String type, IconData icon) {
    final isSelected = _noteType == type;
    return GestureDetector(
      onTap: () {
        debugPrint('Note type changed from $_noteType to $type');
        setState(() {
          _noteType = type;
          // If switching to checklist type and no items exist, add a default one
          if (type == 'checklist' && _checklist.isEmpty) {
            debugPrint('Initializing new checklist');
            _checklist = [
              ChecklistItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                text: '',
                isCompleted: false,
                createdAt: DateTime.now(),
              ),
            ];
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.textTheme.bodySmall?.copyWith(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(Colors.white.withAlpha((0.9 * 255).round()), Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Color.alphaBlend(Colors.black.withAlpha((0.1 * 255).round()), Colors.transparent),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Word count
          Text(
            '${_getWordCount()} words',
            style: AppTheme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),

          const Spacer(),

          // Save button
          ScaleTransition(
            scale: _saveAnimation,
            child: ElevatedButton.icon(
              onPressed: (_isLoading || _isSaving) ? null : _saveNote,
              icon: (_isLoading || _isSaving)
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const SizedBox.shrink(),
              label: Text(
                _isLoading ? 'Saving...' : 'Save',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getWordCount() {
    final text = _titleController.text + ' ' + _contentController.text;
    return text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  Future<void> _handleBack() async {
    if (_isSaving) {
      // Don't allow back navigation while saving
      return;
    }
    // Try to pop the current route
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      // If we can't pop, maybe we're the only route
      navigator.maybePop();
    }
  }

  // Removed unsaved changes dialog to allow free back navigation

  Future<void> _saveNote() async {
    // Prevent multiple simultaneous saves
    if (_isSaving) {
      debugPrint('Save already in progress, ignoring duplicate save request');
      return;
    }
    
    // Cancel any pending debounce
    _debounceTimer?.cancel();
    
    if (!mounted) return;
    
    // Set saving state immediately to prevent multiple saves
    setState(() {
      _isSaving = true;
      _isLoading = true;
    });
    
    try {
      debugPrint('Starting save process...');
      final stopwatch = Stopwatch()..start();
      
      // Process checklist in background
      final processedChecklist = await _processChecklistInBackground();
      debugPrint('Checklist processed in ${stopwatch.elapsedMilliseconds}ms');
      
      // Validate note content
      if (!await _validateNoteContent(processedChecklist)) {
        debugPrint('Validation failed, not saving');
        return;
      }
      
      // Play save animation (don't await to prevent blocking)
      unawaitedFuture(_saveAnimationController.forward().then((_) => _saveAnimationController.reverse()));
      
      debugPrint('Saving note to Firestore...');
      await _saveNoteToFirestore(processedChecklist);
      debugPrint('Note saved successfully in ${stopwatch.elapsedMilliseconds}ms');
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Note ${_isEditing ? 'updated' : 'saved'} successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Pop back to previous screen on success
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      
    } catch (e, stackTrace) {
      debugPrint('Error in save process: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        // Show error message with retry option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save note: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () {
                // Retry the save operation
                _saveNote();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isLoading = false;
        });
      }
    }
  }
  
  Future<List<ChecklistItem>> _processChecklistInBackground() async {
    // Process checklist in a separate isolate for better performance
    return await compute(_processChecklist, _checklist);
  }
  
  static List<ChecklistItem> _processChecklist(List<ChecklistItem> checklist) {
    // Filter out empty items
    final validChecklist = checklist.where((item) => item.text.trim().isNotEmpty).toList();
    
    // Log the changes if any items were filtered
    if (validChecklist.length != checklist.length) {
      debugPrint('Filtered out ${checklist.length - validChecklist.length} empty checklist items');
    }
    
    return validChecklist;
  }
  
  Future<bool> _validateNoteContent(List<ChecklistItem> validChecklist) async {
    // Check if note has any content
    if (_titleController.text.trim().isEmpty && 
        _contentController.text.trim().isEmpty &&
        validChecklist.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add some content to save the note'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }
    return true;
  }
  
  Future<void> _saveNoteToFirestore(List<ChecklistItem> validChecklist) async {
    if (!mounted) return;
    
    final authProvider = context.read<AuthProvider>();
    final notesProvider = context.read<EnhancedNotesProvider>();
    
    if (authProvider.user == null) {
      throw Exception('User not authenticated');
    }
    
    final now = DateTime.now();
    final note = EnhancedNote(
      id: _isEditing ? widget.note!.id : '',
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      createdAt: _isEditing ? widget.note!.createdAt : now,
      updatedAt: now,
      userId: authProvider.user!.uid,
      isPinned: _isPinned,
      isFavorite: _isFavorite,
      isArchived: _isEditing ? widget.note!.isArchived : false,
      colorTag: _selectedColor,
      tags: _tags,
      checklist: validChecklist,
      reminderDate: _reminderDate,
      noteType: _noteType,
    );
    
    debugPrint('Saving note with ID: ${note.id}');
    
    try {
      if (_isEditing) {
        debugPrint('Updating existing note...');
        await notesProvider.updateNote(note);
      } else {
        debugPrint('Creating new note...');
        await notesProvider.createNote(note);
      }
      
      debugPrint('Note saved successfully');
    } catch (e, stackTrace) {
      debugPrint('Error saving note: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'archive':
        await _toggleArchive();
        break;
      case 'delete':
        await _deleteNote();
        break;
      case 'share':
        _shareNote();
        break;
    }
  }

  void _handleTextChanged() {
    // Auto-save after a delay if the note has been edited
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(_saveDebounceTime, () {
      if (mounted) {
        _saveNote();
      }
    });
  }

  Future<void> _toggleArchive() async {
    if (!_isEditing) return;

    try {
      await context.read<EnhancedNotesProvider>().toggleArchive(
        widget.note!.id,
        widget.note!.isArchived,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.note!.isArchived ? 'Note unarchived' : 'Note archived'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNote() async {
    if (!_isEditing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<EnhancedNotesProvider>().deleteNote(widget.note!.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note deleted'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting note: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _shareNote() {
    // TODO: Implement actual sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final note = widget.note;
    if (note != null) {
      _noteType = note.noteType;
      _isPinned = note.isPinned;
      _isFavorite = note.isFavorite;
      _selectedColor = note.colorTag;
      _tags = List<String>.from(note.tags);
      _checklist = note.checklist.map((item) => ChecklistItem.fromMap(item.toMap())).toList();
      _reminderDate = note.reminderDate;
    }
    debugPrint('AddEditNoteScreen didChangeDependencies called');
    debugPrint('Current note type: $_noteType');
    debugPrint('Current checklist items: ${_checklist.length}');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _saveAnimationController.dispose();
    super.dispose();
  }
}
