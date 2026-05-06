import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_providers.dart';

// ── Subject data ──────────────────────────────────────────────────────────────

class _SubjectOption {
  final String name;
  final Color color;
  const _SubjectOption(this.name, this.color);
}

const _kSubjects = [
  _SubjectOption('Computer Science', Color(0xFF5186CD)),
  _SubjectOption('Mathematics', Color(0xFFE67E22)),
  _SubjectOption('Physics', Color(0xFFE74C3C)),
  _SubjectOption('Chemistry', Color(0xFF27AE60)),
  _SubjectOption('Literature', Color(0xFF8E44AD)),
  _SubjectOption('Economics', Color(0xFF16A085)),
  _SubjectOption('Biology', Color(0xFF2ECC71)),
  _SubjectOption('Engineering', Color(0xFF2C3E50)),
  _SubjectOption('History', Color(0xFF795548)),
  _SubjectOption('Psychology', Color(0xFFE91E63)),
  _SubjectOption('Other', Color(0xFF888888)),
];

// ── SessionForm ───────────────────────────────────────────────────────────────

class SessionForm extends StatefulWidget {
  final StudySession? initialSession;
  final VoidCallback? onDelete;

  const SessionForm({super.key, this.initialSession, this.onDelete});

  bool get isEditing => initialSession != null;

  @override
  State<SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends State<SessionForm> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _tagInputCtrl = TextEditingController();
  final _tagFocus = FocusNode();

  String _visSegment = 'public';
  bool _requiresApproval = false;
  bool _obscurePass = true;

  _SubjectOption _subject = _kSubjects.first;
  final List<String> _tags = [];

  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  int _capacity = 10;
  String? _timeError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = now.add(const Duration(days: 1));
    _startTime = const TimeOfDay(hour: 14, minute: 0);
    _endTime = const TimeOfDay(hour: 16, minute: 0);
    _prefill();
  }

  void _prefill() {
    final s = widget.initialSession;
    if (s == null) return;
    _titleCtrl.text = s.title;
    _descCtrl.text = s.description ?? '';
    _locationCtrl.text = s.location;
    if (s.visibility == SessionVisibility.private) {
      _visSegment = 'private';
    } else {
      _visSegment = 'public';
      _requiresApproval = s.visibility == SessionVisibility.approval;
    }
    final found = _kSubjects.where((o) => o.name == s.subject).firstOrNull;
    _subject = found ?? _kSubjects.last;
    _tags.addAll(s.hashtags);
    _date = s.date;
    _startTime = TimeOfDay.fromDateTime(s.startTime);
    _endTime = TimeOfDay.fromDateTime(s.endTime);
    _capacity = s.capacity;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _passwordCtrl.dispose();
    _tagInputCtrl.dispose();
    _tagFocus.dispose();
    super.dispose();
  }

  // ── Derived ───────────────────────────────────────────────────────────────

  SessionVisibility get _visibility {
    if (_visSegment == 'private') return SessionVisibility.private;
    return _requiresApproval ? SessionVisibility.approval : SessionVisibility.public;
  }

  bool get _timeValid {
    final s = _startTime.hour * 60 + _startTime.minute;
    final e = _endTime.hour * 60 + _endTime.minute;
    return e > s;
  }

  String get _durationLabel {
    final s = _startTime.hour * 60 + _startTime.minute;
    final e = _endTime.hour * 60 + _endTime.minute;
    final diff = e - s;
    if (diff <= 0) return '';
    final hrs = diff ~/ 60;
    final mins = diff % 60;
    if (hrs == 0) return '$mins mins';
    if (mins == 0) return '${hrs}h';
    return '${hrs}h ${mins}mins';
  }

  int get _minCapacity {
    final joined = widget.initialSession?.joined ?? 1;
    return joined > 2 ? joined : 2;
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _addTag(String raw) {
    final tag = raw.trim().replaceAll('#', '').toLowerCase();
    if (tag.isEmpty || _tags.contains(tag)) {
      _tagInputCtrl.clear();
      return;
    }
    setState(() {
      _tags.add(tag);
      _tagInputCtrl.clear();
    });
  }

  Future<void> _pickDate() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CalendarSheet(
        selectedDay: _date,
        onDaySelected: (d) {
          setState(() => _date = d);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _pickStartTime() async {
    final t = await showTimePicker(context: context, initialTime: _startTime);
    if (t != null) setState(() { _startTime = t; _timeError = null; });
  }

  Future<void> _pickEndTime() async {
    final t = await showTimePicker(context: context, initialTime: _endTime);
    if (t != null) setState(() { _endTime = t; _timeError = null; });
  }

  bool _validate() {
    final formOk = _formKey.currentState!.validate();
    if (!_timeValid) {
      setState(() => _timeError = 'End time must be after start time');
      return false;
    }
    setState(() => _timeError = null);
    return formOk;
  }

  void _submit() {
    if (!_validate()) return;
    final startDt = DateTime(_date.year, _date.month, _date.day,
        _startTime.hour, _startTime.minute);
    final endDt = DateTime(_date.year, _date.month, _date.day,
        _endTime.hour, _endTime.minute);
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final session = StudySession(
      id: widget.initialSession?.id ?? const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      subject: _subject.name,
      subjectColor: _subject.color,
      hostName: user?.name ?? 'You',
      hostAvatar: user?.avatar ?? '',
      hostId: user?.id ?? 'current-user',
      date: _date,
      startTime: startDt,
      endTime: endDt,
      location: _locationCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      capacity: _capacity,
      joined: widget.initialSession?.joined ?? 1,
      visibility: _visibility,
      hashtags: List.from(_tags),
      members: widget.initialSession?.members ?? [],
      requests: widget.initialSession?.requests ?? [],
      myStatus: widget.initialSession?.myStatus ?? JoinStatus.host,
    );
    final provider = context.read<SessionsProvider>();
    if (widget.isEditing) {
      provider.updateSession(session);
    } else {
      provider.addSession(session);
    }
    context.pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVisibilitySection(tt),
            const SizedBox(height: 24),
            _buildTitleSection(),
            const SizedBox(height: 20),
            _buildSubjectSection(tt),
            const SizedBox(height: 20),
            _buildHashtagSection(),
            const SizedBox(height: 20),
            _buildDescriptionSection(),
            const SizedBox(height: 20),
            _buildDateSection(tt),
            const SizedBox(height: 20),
            _buildTimeSection(tt),
            const SizedBox(height: 20),
            _buildLocationSection(),
            const SizedBox(height: 20),
            _buildCapacitySection(tt),
            const SizedBox(height: 32),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────────

  Widget _buildVisibilitySection(TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Session Visibility'),
        const SizedBox(height: 10),
        SegmentedButton<String>(
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
          ),
          segments: const [
            ButtonSegment(
              value: 'public',
              icon: Icon(Icons.public_outlined, size: 16),
              label: Text('Public'),
            ),
            ButtonSegment(
              value: 'private',
              icon: Icon(Icons.lock_outline, size: 16),
              label: Text('Private'),
            ),
          ],
          selected: {_visSegment},
          onSelectionChanged: (v) =>
              setState(() => _visSegment = v.first),
          showSelectedIcon: false,
        ),
        if (_visSegment == 'public') ...[
          const SizedBox(height: 10),
          _RadioTile(
            title: 'No Approval Required',
            subtitle: 'Anyone can join instantly',
            selected: !_requiresApproval,
            icon: Icons.group_outlined,
            onTap: () => setState(() => _requiresApproval = false),
          ),
          const SizedBox(height: 6),
          _RadioTile(
            title: 'Host Approval Required',
            subtitle: 'You review and approve join requests',
            selected: _requiresApproval,
            icon: Icons.admin_panel_settings_outlined,
            onTap: () => setState(() => _requiresApproval = true),
          ),
        ],
        if (_visSegment == 'private') ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePass,
            validator: (v) {
              if (_visSegment == 'private' && (v?.trim().isEmpty ?? true)) {
                return 'Password is required for private sessions';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Session password',
              prefixIcon: const Icon(Icons.key_outlined, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Session Title *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleCtrl,
          textCapitalization: TextCapitalization.sentences,
          validator: (v) =>
              (v?.trim().isEmpty ?? true) ? 'Title is required' : null,
          decoration: const InputDecoration(
              hintText: 'e.g. CS101 Final Exam Prep'),
        ),
      ],
    );
  }

  Widget _buildSubjectSection(TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Subject *'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey(_subject.name),
          initialValue: _subject.name,
          isExpanded: true,
          decoration: const InputDecoration(hintText: 'Select a subject'),
          items: _kSubjects
              .map((s) => DropdownMenuItem(
                    value: s.name,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: s.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Text(s.name, style: tt.bodyMedium),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() =>
                  _subject = _kSubjects.firstWhere((s) => s.name == val));
            }
          },
        ),
      ],
    );
  }

  Widget _buildHashtagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Hashtags'),
        const SizedBox(height: 8),
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags
                .map((t) => _HashtagChip(
                      tag: t,
                      onRemove: () => setState(() => _tags.remove(t)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _tagInputCtrl,
          focusNode: _tagFocus,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'Type a tag and press Enter or Space',
            prefixIcon: Icon(Icons.tag, size: 18),
          ),
          onSubmitted: (v) {
            _addTag(v);
            _tagFocus.requestFocus();
          },
          onChanged: (v) {
            if (v.endsWith(' ') && v.trim().isNotEmpty) _addTag(v);
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Description'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Briefly describe what you'll be studying...",
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection(TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Date *'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.hint),
                const SizedBox(width: 10),
                Text(DateFormat('EEE, MMMM d, y').format(_date),
                    style: tt.bodyMedium),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.hint),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSection(TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Time *'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _TimeTile(
                    label: 'Start Time',
                    time: _startTime,
                    onTap: _pickStartTime)),
            const SizedBox(width: 12),
            Expanded(
                child: _TimeTile(
                    label: 'End Time',
                    time: _endTime,
                    onTap: _pickEndTime)),
          ],
        ),
        if (_timeError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(_timeError!,
                style: const TextStyle(
                    color: AppColors.error, fontSize: 12)),
          )
        else if (_timeValid && _durationLabel.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.timelapse_outlined,
                    size: 14, color: AppColors.accent),
                const SizedBox(width: 4),
                Text(
                  'Duration: $_durationLabel',
                  style: tt.bodyMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Location *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _locationCtrl,
          validator: (v) =>
              (v?.trim().isEmpty ?? true) ? 'Location is required' : null,
          decoration: const InputDecoration(
            hintText: 'e.g. Library Room 203',
            prefixIcon:
                Icon(Icons.location_on_outlined, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildCapacitySection(TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Participant Capacity'),
        const SizedBox(height: 8),
        Row(
          children: [
            _StepperBtn(
              icon: Icons.remove,
              enabled: _capacity > _minCapacity,
              onTap: () => setState(() => _capacity--),
            ),
            const SizedBox(width: 20),
            Text('$_capacity',
                style: tt.displayMedium
                    ?.copyWith(color: AppColors.text)),
            const SizedBox(width: 20),
            _StepperBtn(
              icon: Icons.add,
              enabled: true,
              onTap: () => setState(() => _capacity++),
            ),
            const SizedBox(width: 12),
            Text('people',
                style:
                    tt.bodyMedium?.copyWith(color: AppColors.hint)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [5, 10, 15, 20]
              .map((q) => GestureDetector(
                    onTap: () => setState(() => _capacity += q),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: AppColors.accent),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('+$q',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _submit,
          child:
              Text(widget.isEditing ? 'Save Changes' : 'Create Session'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => context.pop(),
          child: const Text('Cancel'),
        ),
        if (widget.onDelete != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            onPressed: widget.onDelete,
            child: const Text('Delete Session'),
          ),
        ],
      ],
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w600),
      );
}

class _RadioTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _RadioTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondary.withValues(alpha: 0.5)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: selected ? AppColors.accent : AppColors.hint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color:
                          selected ? AppColors.accent : AppColors.text,
                    ),
                  ),
                  Text(subtitle,
                      style: tt.labelSmall
                          ?.copyWith(color: AppColors.hint)),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.border,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _HashtagChip extends StatelessWidget {
  final String tag;
  final VoidCallback onRemove;

  const _HashtagChip({required this.tag, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: const TextStyle(
              color: Color(0xFF5186CD),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close,
                size: 14, color: Color(0xFF5186CD)),
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeTile(
      {required this.label,
      required this.time,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    tt.labelSmall?.copyWith(color: AppColors.hint)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time_outlined,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(time.format(context), style: tt.titleLarge),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperBtn(
      {required this.icon,
      required this.enabled,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? AppColors.secondary : AppColors.disabled,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? AppColors.accent.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Icon(icon,
            size: 20,
            color:
                enabled ? AppColors.accent : AppColors.hint),
      ),
    );
  }
}

// ── Calendar Bottom Sheet ─────────────────────────────────────────────────────

class _CalendarSheet extends StatefulWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const _CalendarSheet(
      {required this.selectedDay, required this.onDaySelected});

  @override
  State<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<_CalendarSheet> {
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedDay;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin:
                    const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text('Pick a Date', style: tt.displaySmall),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close,
                        size: 20, color: AppColors.hint),
                  ),
                ],
              ),
            ),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now()
                  .add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) =>
                  isSameDay(day, widget.selectedDay),
              onDaySelected: (selected, focused) {
                setState(() => _focusedDay = focused);
                widget.onDaySelected(selected);
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
                outsideDaysVisible: false,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
