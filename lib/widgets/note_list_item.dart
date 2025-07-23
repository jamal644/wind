import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_messenger_app/models/enhanced_note_model.dart';
import 'package:youtube_messenger_app/providers/enhanced_notes_provider.dart';
import 'package:youtube_messenger_app/core/theme/app_theme.dart';
import 'package:youtube_messenger_app/core/utils/color_utils.dart';

class NoteListItem extends StatelessWidget {
  final EnhancedNote note;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(bool) onSelectionChanged;

  const NoteListItem({
    super.key,
    required this.note,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.getNoteColor(note.colorTag),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppTheme.primaryColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection checkbox
              if (isSelectionMode) ...[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
              ],

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icons and date
                    Row(
                      children: [
                        // Status icons
                        if (note.isPinned)
                          Icon(
                            Icons.push_pin,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        if (note.isFavorite)
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color: Colors.red[400],
                          ),
                        if (note.reminderDate != null)
                          Icon(
                            Icons.alarm,
                            size: 16,
                            color: Colors.orange[600],
                          ),
                        if (note.noteType == 'checklist')
                          Icon(
                            Icons.checklist,
                            size: 16,
                            color: Colors.blue[600],
                          ),
                        if (note.noteType == 'voice')
                          Icon(
                            Icons.mic,
                            size: 16,
                            color: Colors.purple[600],
                          ),
                        
                        const Spacer(),
                        
                        // Date
                        Text(
                          _formatDate(note.updatedAt),
                          style: AppTheme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Title
                    if (note.title.isNotEmpty) ...[
                      Text(
                        note.title,
                        style: AppTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Content preview
                    if (note.noteType == 'checklist' && note.checklist.isNotEmpty)
                      _buildChecklistPreview()
                    else
                      Text(
                        note.content,
                        style: AppTheme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    // Tags
                    if (note.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: note.tags.take(5).map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ColorUtils.blackOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$tag',
                            style: AppTheme.textTheme.bodySmall?.copyWith(
                              color: Colors.black87,
                              fontSize: 10,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Quick actions
              if (!isSelectionMode) ...[
                const SizedBox(width: 12),
                Column(
                  children: [
                    _buildQuickAction(
                      icon: note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      onPressed: () => _togglePin(context),
                      color: note.isPinned ? AppTheme.primaryColor : Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    _buildQuickAction(
                      icon: note.isFavorite ? Icons.favorite : Icons.favorite_border,
                      onPressed: () => _toggleFavorite(context),
                      color: note.isFavorite ? Colors.red[400] : Colors.grey[600],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistPreview() {
    final completedCount = note.checklist.where((item) => item.isCompleted).length;
    final totalCount = note.checklist.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress indicator
        Row(
          children: [
            Icon(Icons.checklist, size: 16, color: Colors.blue[600]),
            const SizedBox(width: 4),
            Text(
              '$completedCount/$totalCount completed',
              style: AppTheme.textTheme.bodySmall?.copyWith(
                color: Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: totalCount > 0 ? completedCount / totalCount : 0,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        // First checklist item
        if (note.checklist.isNotEmpty)
          Row(
            children: [
              Icon(
                note.checklist.first.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                size: 16,
                color: note.checklist.first.isCompleted ? Colors.green[600] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  note.checklist.first.text,
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.black87,
                    decoration: note.checklist.first.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        
        if (note.checklist.length > 1)
          Text(
            '+${note.checklist.length - 1} more items',
            style: AppTheme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: ColorUtils.whiteOpacity(0.8),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: color ?? Colors.grey[600],
        ),
      ),
    );
  }

  void _togglePin(BuildContext context) {
    context.read<EnhancedNotesProvider>().togglePin(note.id, note.isPinned);
  }

  void _toggleFavorite(BuildContext context) {
    context.read<EnhancedNotesProvider>().toggleFavorite(note.id, note.isFavorite);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
