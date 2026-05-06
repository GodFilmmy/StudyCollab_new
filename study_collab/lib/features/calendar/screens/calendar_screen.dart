import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_providers.dart';
import '../../dashboard/widgets/session_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<StudySession> _sessionsForDay(List<StudySession> all, DateTime day) =>
      all.where((s) => isSameDay(s.date, day)).toList();

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<SessionsProvider>().sessions;
    final selected = _selectedDay != null
        ? _sessionsForDay(sessions, _selectedDay!)
        : <StudySession>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Text('Calendar'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SegmentedButton<CalendarFormat>(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((s) =>
                    s.contains(WidgetState.selected)
                        ? AppColors.secondary
                        : AppColors.surface),
                foregroundColor: WidgetStateProperty.resolveWith((s) =>
                    s.contains(WidgetState.selected)
                        ? AppColors.accent
                        : AppColors.hint),
                side: WidgetStateProperty.all(
                    const BorderSide(color: AppColors.border)),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: const [
                ButtonSegment(
                  value: CalendarFormat.month,
                  label: Text('Month', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: CalendarFormat.week,
                  label: Text('Week', style: TextStyle(fontSize: 12)),
                ),
              ],
              selected: {_calendarFormat},
              onSelectionChanged: (v) =>
                  setState(() => _calendarFormat = v.first),
              showSelectedIcon: false,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: TableCalendar<StudySession>(
              firstDay:
                  DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) =>
                  isSameDay(_selectedDay, day),
              eventLoader: (day) => _sessionsForDay(sessions, day),
              onDaySelected: (selected, focused) => setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              }),
              onFormatChanged: (f) =>
                  setState(() => _calendarFormat = f),
              onPageChanged: (f) =>
                  setState(() => _focusedDay = f),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent),
                ),
                todayTextStyle: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
                outsideDaysVisible: false,
              ),
              calendarBuilders: CalendarBuilders<StudySession>(
                defaultBuilder: (context, day, _) {
                  final daySessions = _sessionsForDay(sessions, day);
                  final hasPersonal = daySessions.any((s) =>
                      s.myStatus == JoinStatus.joined ||
                      s.myStatus == JoinStatus.host);
                  if (!hasPersonal) return null;
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return const SizedBox.shrink();
                  final colors = events
                      .take(3)
                      .map((e) => e.subjectColor)
                      .toSet()
                      .toList();
                  return Positioned(
                    bottom: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: colors
                          .map((c) => Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 1),
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                ),
                              ))
                          .toList(),
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _selectedDay == null
                ? const _NoDateSelected()
                : selected.isEmpty
                    ? _NoSessionsDay(date: _selectedDay!)
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: selected.length,
                        itemBuilder: (context, i) =>
                            SessionCard(session: selected[i]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        onPressed: () =>
            context.push('/create-session', extra: _selectedDay),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NoDateSelected extends StatelessWidget {
  const _NoDateSelected();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.touch_app_outlined,
              size: 52, color: AppColors.disabled),
          const SizedBox(height: 12),
          Text(
            'Tap a day to see sessions',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.hint),
          ),
        ],
      ),
    );
  }
}

class _NoSessionsDay extends StatelessWidget {
  final DateTime date;
  const _NoSessionsDay({required this.date});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy_outlined,
              size: 52, color: AppColors.disabled),
          const SizedBox(height: 12),
          Text(
            'No sessions on ${DateFormat('MMMM d').format(date)}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.hint),
          ),
        ],
      ),
    );
  }
}
