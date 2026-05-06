import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_providers.dart';
import '../widgets/search_bottom_sheet.dart';
import '../widgets/session_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedMockSessions());
  }

  void _seedMockSessions() {
    final provider = context.read<SessionsProvider>();
    if (provider.sessions.isNotEmpty) return;

    final now = DateTime.now();

    final sessions = [
      StudySession(
        id: 'mock-1',
        title: 'CS101 Final Exam Prep',
        subject: 'Computer Science',
        subjectColor: const Color(0xFF5186CD),
        hostName: 'Alex Johnson',
        hostAvatar: '',
        hostId: 'host-1',
        date: now.add(const Duration(days: 2)),
        startTime: DateTime(now.year, now.month, now.day + 2, 14, 0),
        endTime: DateTime(now.year, now.month, now.day + 2, 17, 0),
        location: 'Library Room 203',
        description:
            'Preparing for the final exam covering algorithms, data structures, and complexity theory.',
        capacity: 8,
        joined: 5,
        visibility: SessionVisibility.public,
        hashtags: ['algorithms', 'cs101', 'exam'],
        myStatus: JoinStatus.notJoined,
      ),
      StudySession(
        id: 'mock-2',
        title: 'Calculus II Study Group',
        subject: 'Mathematics',
        subjectColor: const Color(0xFFE67E22),
        hostName: 'Priya Sharma',
        hostAvatar: '',
        hostId: 'host-2',
        date: now.add(const Duration(days: 1)),
        startTime: DateTime(now.year, now.month, now.day + 1, 10, 0),
        endTime: DateTime(now.year, now.month, now.day + 1, 12, 0),
        location: 'Engineering Block B, Room 101',
        description:
            'Working through integration techniques and series convergence. Bring your practice sets!',
        capacity: 6,
        joined: 2,
        visibility: SessionVisibility.approval,
        hashtags: ['calculus', 'math', 'integration'],
        myStatus: JoinStatus.notJoined,
      ),
      StudySession(
        id: 'mock-3',
        title: 'Quantum Mechanics Deep Dive',
        subject: 'Physics',
        subjectColor: const Color(0xFFE74C3C),
        hostName: 'Dr. Tanaka',
        hostAvatar: '',
        hostId: 'host-3',
        date: now.add(const Duration(days: 3)),
        startTime: DateTime(now.year, now.month, now.day + 3, 15, 30),
        endTime: DateTime(now.year, now.month, now.day + 3, 17, 30),
        location: 'Physics Lab 4',
        description:
            'Private session covering wave functions and Schrödinger equation. Password required.',
        capacity: 5,
        joined: 3,
        visibility: SessionVisibility.private,
        hashtags: ['quantum', 'physics'],
        myStatus: JoinStatus.notJoined,
      ),
      StudySession(
        id: 'mock-4',
        title: 'Organic Chemistry Review',
        subject: 'Chemistry',
        subjectColor: const Color(0xFF27AE60),
        hostName: 'Sara Müller',
        hostAvatar: '',
        hostId: 'host-4',
        date: now.add(const Duration(days: 4)),
        startTime: DateTime(now.year, now.month, now.day + 4, 13, 0),
        endTime: DateTime(now.year, now.month, now.day + 4, 15, 0),
        location: 'Science Building 2F',
        description: 'Reviewing reaction mechanisms and functional groups.',
        capacity: 10,
        joined: 7,
        visibility: SessionVisibility.public,
        hashtags: ['chemistry', 'organic', 'review'],
        myStatus: JoinStatus.joined,
      ),
      StudySession(
        id: 'mock-5',
        title: 'Contemporary Literature Circle',
        subject: 'Literature',
        subjectColor: const Color(0xFF8E44AD),
        hostName: 'Mei Lin',
        hostAvatar: '',
        hostId: 'host-5',
        date: now.add(const Duration(days: 5)),
        startTime: DateTime(now.year, now.month, now.day + 5, 16, 0),
        endTime: DateTime(now.year, now.month, now.day + 5, 18, 0),
        location: 'Humanities Lounge',
        capacity: 8,
        joined: 4,
        visibility: SessionVisibility.approval,
        hashtags: ['literature', 'reading', 'discussion'],
        myStatus: JoinStatus.pending,
      ),
      StudySession(
        id: 'mock-6',
        title: 'Microeconomics Problem Set',
        subject: 'Economics',
        subjectColor: const Color(0xFF16A085),
        hostName: 'You',
        hostAvatar: '',
        hostId: 'current-user',
        date: now.add(const Duration(days: 6)),
        startTime: DateTime(now.year, now.month, now.day + 6, 9, 0),
        endTime: DateTime(now.year, now.month, now.day + 6, 11, 0),
        location: 'Social Sciences, Room 305',
        description:
            'Working on supply-demand models and market equilibrium problem sets.',
        capacity: 6,
        joined: 2,
        visibility: SessionVisibility.public,
        hashtags: ['economics', 'microecon'],
        myStatus: JoinStatus.host,
      ),
    ];

    for (final s in sessions) {
      provider.addSession(s);
    }
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() {});
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _openSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SearchBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final auth = context.watch<AuthProvider>();
    final sessions = context.watch<SessionsProvider>().sessions;
    final unreadCount = context.watch<NotificationsProvider>().unreadCount;
    final firstName = auth.currentUser?.name.split(' ').first ?? 'Student';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_greeting()}, $firstName 👋',
              style: tt.displaySmall,
            ),
            Text(
              'Find your next study session',
              style: tt.bodyMedium?.copyWith(color: AppColors.hint),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: badges.Badge(
              badgeContent: Text(
                '$unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              showBadge: unreadCount > 0,
              position: badges.BadgePosition.topEnd(top: -4, end: -4),
              badgeStyle: const badges.BadgeStyle(
                badgeColor: AppColors.accent,
                padding: EdgeInsets.all(4),
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push('/notifications'),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar trigger
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: GestureDetector(
              onTap: _openSearch,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.hint, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Search sessions, #hashtags, @hosts...',
                      style:
                          tt.bodyMedium?.copyWith(color: AppColors.hint),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Session list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.accent,
              child: sessions.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) =>
                          SessionCard(session: sessions[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return ListView(
      // ListView enables pull-to-refresh even on empty state
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  size: 48,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No sessions yet',
                style: tt.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to create a study session\nand start collaborating!',
                style: tt.bodyMedium?.copyWith(color: AppColors.hint),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
