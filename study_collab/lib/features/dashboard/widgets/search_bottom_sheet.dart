import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_providers.dart';
import 'session_card.dart';

class SearchBottomSheet extends StatefulWidget {
  const SearchBottomSheet({super.key});

  @override
  State<SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  final _controller = TextEditingController();
  String _activeFilter = 'All';
  List<StudySession> _results = [];

  static const _filters = ['All', 'Subject', 'Hostname', '#Hashtag'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_results.isEmpty && _controller.text.isEmpty) {
      _results = context.read<SessionsProvider>().sessions;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String query) {
    // Smart filter: auto-switch chip based on prefix
    if (query.startsWith('#') && _activeFilter != '#Hashtag') {
      setState(() => _activeFilter = '#Hashtag');
    } else if (query.startsWith('@') && _activeFilter != 'Hostname') {
      setState(() => _activeFilter = 'Hostname');
    }
    _applyFilter(query);
  }

  void _applyFilter(String query) {
    final provider = context.read<SessionsProvider>();
    final q = query.toLowerCase();

    List<StudySession> results;
    switch (_activeFilter) {
      case 'Subject':
        results = q.isEmpty
            ? provider.sessions
            : provider.sessions
                .where((s) => s.subject.toLowerCase().contains(q))
                .toList();
        break;
      case 'Hostname':
        final hostQ = q.startsWith('@') ? q.substring(1) : q;
        results = hostQ.isEmpty
            ? provider.sessions
            : provider.sessions
                .where((s) => s.hostName.toLowerCase().contains(hostQ))
                .toList();
        break;
      case '#Hashtag':
        final tagQ = q.startsWith('#') ? q.substring(1) : q;
        results = tagQ.isEmpty
            ? provider.sessions
            : provider.sessions
                .where((s) =>
                    s.hashtags.any((h) => h.toLowerCase().contains(tagQ)))
                .toList();
        break;
      default:
        results = provider.search(query);
    }

    setState(() => _results = results);
  }

  void _setFilter(String filter) {
    setState(() => _activeFilter = filter);

    // Insert prefix character when switching to special filter modes
    if (filter == '#Hashtag' && !_controller.text.startsWith('#')) {
      _controller.text = '#';
      _controller.selection =
          TextSelection.fromPosition(const TextPosition(offset: 1));
    } else if (filter == 'Hostname' && !_controller.text.startsWith('@')) {
      _controller.text = '@';
      _controller.selection =
          TextSelection.fromPosition(const TextPosition(offset: 1));
    } else if ((filter == 'All' || filter == 'Subject') &&
        (_controller.text.startsWith('#') || _controller.text.startsWith('@'))) {
      _controller.clear();
    }

    _applyFilter(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
              child: Row(
                children: [
                  Text('Search Sessions', style: tt.displaySmall),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.hint,
                  ),
                ],
              ),
            ),
            // Search input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onTextChanged,
                decoration: const InputDecoration(
                  hintText: 'Search by title, #hashtag, @host...',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
            ),
            // Filter chips
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final f = _filters[i];
                  final isActive = f == _activeFilter;
                  return FilterChip(
                    label: Text(f),
                    selected: isActive,
                    onSelected: (_) => _setFilter(f),
                    selectedColor: AppColors.secondary,
                    checkmarkColor: AppColors.accent,
                    labelStyle: TextStyle(
                      color: isActive ? AppColors.accent : AppColors.hint,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: isActive ? AppColors.accent : AppColors.border,
                    ),
                    backgroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.border),
            // Results
            Flexible(
              child: _results.isEmpty
                  ? _NoResults(query: _controller.text)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _results.length,
                      itemBuilder: (context, i) =>
                          SessionCard(session: _results[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 56, color: AppColors.disabled),
            const SizedBox(height: 16),
            Text(
              query.isEmpty ? 'Start typing to search' : 'No sessions found',
              style: tt.titleLarge?.copyWith(color: AppColors.hint),
            ),
            if (query.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Try a different keyword or filter',
                style: tt.bodyMedium?.copyWith(color: AppColors.hint),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
