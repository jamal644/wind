import 'package:flutter/material.dart';
import 'package:youtube_messenger_app/models/enhanced_note_model.dart';
import 'package:youtube_messenger_app/core/theme/app_theme.dart';
import 'package:youtube_messenger_app/core/utils/color_utils.dart';

class ChecklistWidget extends StatefulWidget {
  final List<ChecklistItem> checklist;
  final Function(List<ChecklistItem>) onChecklistChanged;

  const ChecklistWidget({
    super.key,
    required this.checklist,
    required this.onChecklistChanged,
  });

  @override
  State<ChecklistWidget> createState() => _ChecklistWidgetState();
}

class _ChecklistWidgetState extends State<ChecklistWidget> {
  final TextEditingController _newItemController = TextEditingController();
  late List<ChecklistItem> _items;

  @override
  void initState() {
    super.initState();
    debugPrint('ChecklistWidget initState with ${widget.checklist.length} items');
    _items = List.from(widget.checklist);
    if (_items.isEmpty) {
      debugPrint('No checklist items found, adding default item');
      _addNewItem();
    } else {
      debugPrint('Initial checklist items:');
      for (var i = 0; i < _items.length; i++) {
        debugPrint('  Item $i: ${_items[i].text} (completed: ${_items[i].isCompleted})');
      }
    }
  }
  
  @override
  void didUpdateWidget(ChecklistWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('ChecklistWidget didUpdateWidget');
    if (!_areListsEqual(oldWidget.checklist, widget.checklist)) {
      debugPrint('Checklist items changed from parent');
      setState(() {
        _items = List.from(widget.checklist);
      });
    }
  }
  
  bool _areListsEqual(List<ChecklistItem> list1, List<ChecklistItem> list2) {
    if (list1.length != list2.length) return false;
    for (var i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id ||
          list1[i].text != list2[i].text ||
          list1[i].isCompleted != list2[i].isCompleted) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('ChecklistWidget built with ${_items.length} items');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress indicator
        if (_items.isNotEmpty) ...[
          _buildProgressIndicator(),
          const SizedBox(height: 16),
        ],

        // Checklist items
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          onReorder: _reorderItems,
          itemBuilder: (context, index) {
            final item = _items[index];
            return _buildChecklistItem(item, index);
          },
        ),

        const SizedBox(height: 12),

        // Add new item
        _buildAddItemField(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final completedCount = _items.where((item) => item.isCompleted).length;
    final totalCount = _items.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorUtils.whiteOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.checklist, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'Progress: $completedCount/$totalCount completed',
                style: AppTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[600],
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: AppTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(ChecklistItem item, int index) {
    return Container(
      key: ValueKey(item.id),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorUtils.whiteOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => _toggleItem(index),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.isCompleted ? Colors.green[600] : Colors.white,
                border: Border.all(
                  color: item.isCompleted ? Colors.green[600]! : Colors.grey[400]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: item.isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 12),

          // Text field
          Expanded(
            child: TextFormField(
              initialValue: item.text,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                color: item.isCompleted ? Colors.grey[600] : Colors.black87,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Add item...',
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) => _updateItemText(index, value),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),

          // Delete button
          if (_items.length > 1)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.grey[600]),
              onPressed: () => _deleteItem(index),
              iconSize: 20,
            ),

          // Drag handle
          Icon(Icons.drag_handle, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildAddItemField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorUtils.whiteOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.add, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _newItemController,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Add new item...',
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _addNewItem(value.trim());
                  _newItemController.clear();
                }
              },
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleItem(int index) {
    setState(() {
      _items[index] = _items[index].copyWith(
        isCompleted: !_items[index].isCompleted,
      );
    });
    _notifyChange();
  }

  void _updateItemText(int index, String text) {
    _items[index] = _items[index].copyWith(text: text);
    _notifyChange();
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    _notifyChange();
  }

  void _addNewItem([String? text]) {
    final newItem = ChecklistItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text ?? '',
      createdAt: DateTime.now(),
    );

    setState(() {
      _items.add(newItem);
    });
    _notifyChange();
  }

  void _reorderItems(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
    _notifyChange();
  }

  void _notifyChange() {
    debugPrint('ChecklistWidget: Notifying change with ${_items.length} items');
    for (var i = 0; i < _items.length; i++) {
      debugPrint('  Item $i: ${_items[i].text} (completed: ${_items[i].isCompleted})');
    }
    widget.onChecklistChanged(_items);
  }

  @override
  void dispose() {
    _newItemController.dispose();
    super.dispose();
  }
}
