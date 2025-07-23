import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_messenger_app/models/enhanced_note_model.dart';
import 'package:youtube_messenger_app/providers/enhanced_notes_provider.dart';
import 'package:youtube_messenger_app/core/theme/app_theme.dart';
import 'package:youtube_messenger_app/core/utils/color_utils.dart';

class NoteCard extends StatelessWidget {
  final EnhancedNote note;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(bool) onSelectionChanged;

  const NoteCard({
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
        decoration: BoxDecoration(
          color: AppTheme.getNoteColor(note.colorTag),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppTheme.primaryColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: ColorUtils.blackOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: const BoxConstraints(
          minHeight: 120, // Ensure minimum height
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.all(12.0), // Slightly reduced padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with pin and favorite icons
                      Row(
                        children: [
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
                          const Spacer(),
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
                        ],
                      ),

                      if (note.isPinned ||
                          note.isFavorite ||
                          note.reminderDate != null ||
                          note.noteType != 'text')
                        const SizedBox(height: 8),

                      // Title
                      if (note.title.isNotEmpty) ...[
                        Text(
                          note.title,
                          style: AppTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Content with flexible height
                      Flexible(
                        child: note.noteType == 'checklist' &&
                                note.checklist.isNotEmpty
                            ? _buildChecklistPreview()
                            : Text(
                                note.content,
                                style: AppTheme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.black87,
                                ),
                                maxLines: 5, // Reduced from 6 to 5
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),

                      // Tags with limited height and scroll
                      if (note.tags.isNotEmpty) ...[
                        const SizedBox(height: 4), // Reduced spacing
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxHeight: 32), // Limit height
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: note.tags
                                  .take(3)
                                  .map((tag) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical:
                                                1), // Reduced vertical padding
                                        decoration: BoxDecoration(
                                          color: Color.alphaBlend(
                                              Colors.black.withAlpha(
                                                  (0.5 * 255).round()),
                                              Colors.transparent),
                                          borderRadius: BorderRadius.circular(
                                              6), // Slightly smaller radius
                                        ),
                                        child: Text(
                                          '#$tag',
                                          style: AppTheme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: Colors.black87,
                                            fontSize: 10,
                                            height: 1.2, // Tighter line height
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 4), // Reduced spacing

                      // Date with smaller font and tighter spacing
                      Text(
                        _formatDate(note.updatedAt),
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 10, // Smaller font
                          height: 1.1, // Tighter line height
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection overlay
                if (isSelectionMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppTheme.primaryColor : Colors.white,
                        border: Border.all(
                          color:
                              isSelected ? AppTheme.primaryColor : Colors.grey,
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
                  ),

                // Quick actions on hover/long press - positioned absolutely
                Positioned(
                  bottom: 4, // Moved up slightly
                  right: 4, // Moved in slightly
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildQuickAction(
                          icon: note.isPinned
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                          onPressed: () => _togglePin(context),
                          color: note.isPinned
                              ? AppTheme.primaryColor
                              : Colors.grey[600],
                          iconSize: 18, // Slightly smaller icons
                        ),
                        const SizedBox(width: 2), // Reduced spacing
                        _buildQuickAction(
                          icon: note.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          onPressed: () => _toggleFavorite(context),
                          color: note.isFavorite
                              ? Colors.red[400]
                              : Colors.grey[600],
                          iconSize: 18, // Slightly smaller icons
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChecklistPreview() {
    final completedCount =
        note.checklist.where((item) => item.isCompleted).length;
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
          ],
        ),
        const SizedBox(height: 4),

        // Progress bar
        LinearProgressIndicator(
          value: totalCount > 0 ? completedCount / totalCount : 0,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
        ),
        const SizedBox(height: 8),

        // First few checklist items
        ...note.checklist.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(
                    item.isCompleted
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 16,
                    color:
                        item.isCompleted ? Colors.green[600] : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.text,
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.black87,
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),

        if (note.checklist.length > 3)
          Text(
            '+${note.checklist.length - 3} more items',
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
    double iconSize = 16,
  }) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(icon, size: iconSize, color: color),
        ),
      ),
    );
  }

  void _togglePin(BuildContext context) {
    context.read<EnhancedNotesProvider>().togglePin(note.id, note.isPinned);
  }

  void _toggleFavorite(BuildContext context) {
    context
        .read<EnhancedNotesProvider>()
        .toggleFavorite(note.id, note.isFavorite);
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
