import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youtube_messenger_app/providers/auth_provider.dart'
    as AppAuthProvider;
import 'package:youtube_messenger_app/providers/enhanced_notes_provider.dart';
import 'package:youtube_messenger_app/models/enhanced_note_model.dart';
import 'package:youtube_messenger_app/core/theme/app_theme.dart';
import 'package:youtube_messenger_app/widgets/note_card.dart';
import 'package:youtube_messenger_app/widgets/note_list_item.dart';
import 'package:youtube_messenger_app/widgets/app_logo.dart';
import 'package:youtube_messenger_app/screens/notes/add_edit_note_screen.dart';
import 'package:youtube_messenger_app/screens/settings/settings_screen.dart';

class EnhancedNotesHomeScreen extends StatefulWidget {
  const EnhancedNotesHomeScreen({super.key});

  @override
  State<EnhancedNotesHomeScreen> createState() =>
      _EnhancedNotesHomeScreenState();
}

class _EnhancedNotesHomeScreenState extends State<EnhancedNotesHomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  bool _isSelectionMode = false;
  Set<String> _selectedNoteIds = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeNotes();
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();
  }

  void _initializeNotes() {
    final authProvider = context.read<AppAuthProvider.AuthProvider>();
    if (authProvider.user != null) {
      context
          .read<EnhancedNotesProvider>()
          .initializeNotes(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          _buildSearchBar(),
          _buildFilterChips(),
          _buildNotesContent(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: _isSelectionMode ? _buildSelectionBottomBar() : null,
    );
  }

  Widget _buildSliverAppBar() {
    return Consumer<AppAuthProvider.AuthProvider>(
      builder: (context, authProvider, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return SliverAppBar(
          expandedHeight: 120,
          floating: true,
          pinned: true,
          backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
            title: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppLogo(size: 32, showText: true, color: Colors.blue),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome back, ${_getDisplayName(authProvider.user)}!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Consumer<EnhancedNotesProvider>(
              builder: (context, notesProvider, child) {
                return IconButton(
                  icon: Icon(
                    notesProvider.currentView == 'grid'
                        ? Icons.view_list
                        : Icons.grid_view,
                    color: Colors.black87,
                  ),
                  onPressed: () => notesProvider.toggleView(),
                );
              },
            ),
            if (_isSelectionMode)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black87),
                onPressed: _exitSelectionMode,
              )
            else
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black87),
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 18),
                        SizedBox(width: 8),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download, size: 18),
                        SizedBox(width: 8),
                        Text('Export Notes'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18),
                        SizedBox(width: 8),
                        Text('Sign Out'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search notes, tags, or content...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      context.read<EnhancedNotesProvider>().clearSearch();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          onChanged: (query) {
            final authProvider = context.read<AppAuthProvider.AuthProvider>();
            if (authProvider.user != null) {
              context
                  .read<EnhancedNotesProvider>()
                  .searchNotes(query, authProvider.user!.uid);
            }
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SliverToBoxAdapter(
      child: Consumer<EnhancedNotesProvider>(
        builder: (context, notesProvider, child) {
          return Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All', 'all', notesProvider),
                _buildFilterChip('Pinned', 'pinned', notesProvider),
                _buildFilterChip('Favorites', 'favorites', notesProvider),
                _buildFilterChip('Archived', 'archived', notesProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
      String label, String value, EnhancedNotesProvider provider) {
    final isSelected = provider.currentFilter == value;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => provider.setFilter(value),
        backgroundColor: Colors.grey[100],
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildNotesContent() {
    return Consumer2<AppAuthProvider.AuthProvider, EnhancedNotesProvider>(
      builder: (context, authProvider, notesProvider, child) {
        if (notesProvider.isLoading) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
          );
        }

        final notes = notesProvider.filteredNotes;

        if (notes.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(notesProvider),
          );
        }

        return notesProvider.currentView == 'grid'
            ? _buildGridView(notes, notesProvider)
            : _buildListView(notes, notesProvider);
      },
    );
  }

  Widget _buildEmptyState(EnhancedNotesProvider provider) {
    String message;
    IconData icon;

    switch (provider.currentFilter) {
      case 'pinned':
        message = 'No pinned notes yet';
        icon = Icons.push_pin;
        break;
      case 'favorites':
        message = 'No favorite notes yet';
        icon = Icons.favorite;
        break;
      case 'archived':
        message = 'No archived notes yet';
        icon = Icons.archive;
        break;
      default:
        message = provider.isSearching ? 'No notes found' : 'No notes yet';
        icon = provider.isSearching ? Icons.search_off : Icons.note_add;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.textTheme.headlineMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          if (!provider.isSearching && provider.currentFilter == 'all') ...[
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create your first note',
              style: AppTheme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridView(
      List<EnhancedNote> notes, EnhancedNotesProvider provider) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final note = notes[index];
            return NoteCard(
              note: note,
              isSelected: _selectedNoteIds.contains(note.id),
              isSelectionMode: _isSelectionMode,
              onTap: () => _handleNoteTap(note),
              onLongPress: () => _handleNoteLongPress(note),
              onSelectionChanged: (selected) =>
                  _handleNoteSelection(note.id, selected),
            );
          },
          childCount: notes.length,
        ),
      ),
    );
  }

  Widget _buildListView(
      List<EnhancedNote> notes, EnhancedNotesProvider provider) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final note = notes[index];
            return NoteListItem(
              note: note,
              isSelected: _selectedNoteIds.contains(note.id),
              isSelectionMode: _isSelectionMode,
              onTap: () => _handleNoteTap(note),
              onLongPress: () => _handleNoteLongPress(note),
              onSelectionChanged: (selected) =>
                  _handleNoteSelection(note.id, selected),
            );
          },
          childCount: notes.length,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabAnimation,
      child: FloatingActionButton(
        onPressed: _createNewNote,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSelectionBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomBarAction(Icons.archive, 'Archive', _archiveSelected),
          _buildBottomBarAction(Icons.delete, 'Delete', _deleteSelected),
          _buildBottomBarAction(Icons.push_pin, 'Pin', _pinSelected),
          _buildBottomBarAction(Icons.favorite, 'Favorite', _favoriteSelected),
        ],
      ),
    );
  }

  Widget _buildBottomBarAction(
      IconData icon, String label, VoidCallback onPressed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: AppTheme.primaryColor),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: AppTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  // Event handlers
  void _handleNoteTap(EnhancedNote note) {
    if (_isSelectionMode) {
      _handleNoteSelection(note.id, !_selectedNoteIds.contains(note.id));
    } else {
      _editNote(note);
    }
  }

  void _handleNoteLongPress(EnhancedNote note) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedNoteIds.add(note.id);
      });
    }
  }

  void _handleNoteSelection(String noteId, bool selected) {
    setState(() {
      if (selected) {
        _selectedNoteIds.add(noteId);
      } else {
        _selectedNoteIds.remove(noteId);
      }

      if (_selectedNoteIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedNoteIds.clear();
    });
  }

  void _createNewNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditNoteScreen(),
      ),
    );
  }

  void _editNote(EnhancedNote note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditNoteScreen(note: note),
      ),
    );
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
      case 'export':
        await _exportNotes();
        break;
      case 'logout':
        await context.read<AppAuthProvider.AuthProvider>().signOut();
        break;
    }
  }

  Future<void> _exportNotes() async {
    try {
      final authProvider = context.read<AppAuthProvider.AuthProvider>();
      if (authProvider.user != null) {
        final notes = await context
            .read<EnhancedNotesProvider>()
            .exportNotes(authProvider.user!.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${notes.length} notes'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to export notes'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Selection actions
  Future<void> _archiveSelected() async {
    try {
      await context
          .read<EnhancedNotesProvider>()
          .batchArchive(_selectedNoteIds.toList());
      _exitSelectionMode();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notes archived'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to archive notes'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notes'),
        content: Text(
            'Are you sure you want to delete ${_selectedNoteIds.length} notes?'),
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
        await context
            .read<EnhancedNotesProvider>()
            .batchDelete(_selectedNoteIds.toList());
        _exitSelectionMode();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes deleted'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete notes'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pinSelected() async {
    // Implementation for batch pin operation
    _exitSelectionMode();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pin feature coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Future<void> _favoriteSelected() async {
    // Implementation for batch favorite operation
    _exitSelectionMode();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Favorite feature coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  String _getDisplayName(User? user) {
    if (user == null) return 'User';

    // If displayName is available, use first name
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!.split(' ').first;
    }

    // If no displayName, extract username from email
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!.split('@').first;
    }

    return 'User';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }
}
