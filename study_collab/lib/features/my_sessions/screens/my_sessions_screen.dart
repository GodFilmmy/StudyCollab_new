import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_providers.dart';
import '../../dashboard/widgets/search_bottom_sheet.dart';
import '../../dashboard/widgets/session_card.dart';

class MySessionsScreen extends StatefulWidget {
  const MySessionsScreen({super.key});

  @override
  State<MySessionsScreen> createState() => _MySessionsScreenState();
}

class _MySessionsScreenState extends State<MySessionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _subjectFilter;
  DateTimeRange? _dateRange;
  String? _dateRangeLabel;

  static const _indicatorColor = Color(0xFF5186CD);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SearchBottomSheet(),
    );
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDateRange: _dateRange,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _dateRange = range;
        final fmt = (DateTime d) =>
            '${d.month}/${d.day}';
        _dateRangeLabel =
            '${fmt(range.start)} – ${fmt(range.end)}';
      });
    }
  }

  List<StudySession> _applyFilters(List<StudySession> src) {
    var list = src;
    if (_subjectFilter != null) {
      list = list.where((s) => s.subject == _subjectFilter).toList();
    }
    if (_dateRange != null) {
      list = list.where((s) {
        final d = s.date;
        return !d.isBefore(_dateRange!.start) &&
            !d.isAfter(_dateRange!.end);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<SessionsProvider>().sessions;
    final now = DateTime.now();

    final upcoming = _applyFilters(all
        .where((s) =>
            (s.myStatus == JoinStatus.joined ||
                s.myStatus == JoinStatus.pending) &&
            s.endTime.isAfter(now))
        .toList());

    final completed = _applyFilters(all
        .where((s) =>
            (s.myStatus == JoinStatus.joined ||
                s.myStatus == JoinStatus.pending) &&
            s.endTime.isBefore(now))
        .toList());

    final mine = _applyFilters(
        all.where((s) => s.myStatus == JoinStatus.host).toList());

    final subjects =
        all.map((s) => s.subject).toSet().toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Text('My Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: _openSearch,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _indicatorColor,
          labelColor: _indicatorColor,
          unselectedLabelColor: AppColors.hint,
          labelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          tabs: [
            Tab(text: 'Upcoming (${upcoming.length})'),
            Tab(text: 'Completed (${completed.length})'),
            Tab(text: 'Mine (${mine.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          _FilterRow(
            subjects: subjects,
            activeSubject: _subjectFilter,
            dateRangeLabel: _dateRangeLabel,
            onSubjectTap: (s) => setState(
                () => _subjectFilter = _subjectFilter == s ? null : s),
            onDateRangeTap: _pickDateRange,
            onClearDate: () => setState(
                () { _dateRange = null; _dateRangeLabel = null; }),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SessionList(
                  sessions: upcoming,
                  emptyIcon: Icons.upcoming_outlined,
                  emptyTitle: 'No upcoming sessions',
                  emptyBody:
                      'Sessions you join will appear here',
                ),
                _SessionList(
                  sessions: completed,
                  emptyIcon: Icons.check_circle_outline,
                  emptyTitle: 'No completed sessions yet',
                  emptyBody:
                      'Completed sessions will show up here',
                ),
                _SessionList(
                  sessions: mine,
                  emptyIcon: Icons.add_circle_outline,
                  emptyTitle: 'No sessions created',
                  emptyBody:
                      'Tap + to create your first session!',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter row ────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final List<String> subjects;
  final String? activeSubject;
  final String? dateRangeLabel;
  final ValueChanged<String> onSubjectTap;
  final VoidCallback onDateRangeTap;
  final VoidCallback onClearDate;

  const _FilterRow({
    required this.subjects,
    required this.activeSubject,
    required this.dateRangeLabel,
    required this.onSubjectTap,
    required this.onDateRangeTap,
    required this.onClearDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Date range chip
            FilterChip(
              avatar: const Icon(Icons.date_range_outlined, size: 15),
              label: Text(dateRangeLabel ?? 'Date Range'),
              selected: dateRangeLabel != null,
              onSelected: (_) => onDateRangeTap(),
              selectedColor: AppColors.secondary,
              checkmarkColor: AppColors.accent,
              deleteIcon: dateRangeLabel != null
                  ? const Icon(Icons.close, size: 14)
                  : null,
              onDeleted: dateRangeLabel != null ? onClearDate : null,
              labelStyle: TextStyle(
                fontSize: 12,
                color: dateRangeLabel != null
                    ? AppColors.accent
                    : AppColors.hint,
              ),
              side: BorderSide(
                color: dateRangeLabel != null
                    ? AppColors.accent
                    : AppColors.border,
              ),
              backgroundColor: AppColors.surface,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            ...subjects.map((s) {
              final active = s == activeSubject;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(s),
                  selected: active,
                  onSelected: (_) => onSubjectTap(s),
                  selectedColor: AppColors.secondary,
                  checkmarkColor: AppColors.accent,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: active ? AppColors.accent : AppColors.hint,
                  ),
                  side: BorderSide(
                    color:
                        active ? AppColors.accent : AppColors.border,
                  ),
                  backgroundColor: AppColors.surface,
                  visualDensity: VisualDensity.compact,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Session list ──────────────────────────────────────────────────────────────

class _SessionList extends StatelessWidget {
  final List<StudySession> sessions;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyBody;

  const _SessionList({
    required this.sessions,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyBody,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(40),
              ),
              child:
                  Icon(emptyIcon, size: 36, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(emptyTitle,
                style: tt.displaySmall
                    ?.copyWith(color: AppColors.text)),
            const SizedBox(height: 6),
            Text(emptyBody,
                style:
                    tt.bodyMedium?.copyWith(color: AppColors.hint),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: sessions.length,
      itemBuilder: (ctx, i) => SessionCard(session: sessions[i]),
    );
  }
}
