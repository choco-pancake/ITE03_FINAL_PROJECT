import 'package:flutter/material.dart';

import 'widgets/professor_sidebar.dart';

// Professor Evaluation: "Modification Requests"
// File: lib/screens/professor_evaluation_screen.dart

// ───────────────────────── Colors ─────────────────────────

class _C {
  static const primary = Color(0xFF1E40AF);
  static const primarySoft = Color(0xFFEFF6FF);
  static const pageBg = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const text = Color(0xFF0F172A);
  static const body = Color(0xFF1E293B);
  static const muted = Color(0xFF64748B);
}

// ───────────────────────── Models ─────────────────────────

enum _Status { pending, underReview, approved, rejected }

extension _StatusX on _Status {
  String get label => switch (this) {
    _Status.pending => 'Pending',
    _Status.underReview => 'Under review',
    _Status.approved => 'Approved',
    _Status.rejected => 'Rejected',
  };

  Color get color => switch (this) {
    _Status.pending => const Color(0xFFE0A800), // yellow
    _Status.underReview => const Color(0xFF2563EB), // blue
    _Status.approved => const Color(0xFF16A34A), // green
    _Status.rejected => const Color(0xFFDC2626), // red
  };
}

class _HistoryEntry {
  final DateTime date;
  final String action;
  final String? remarks;
  _HistoryEntry(this.date, this.action, [this.remarks]);
}

class _Request {
  final String studentName;
  final String studentId;
  final String program;
  final String title;
  final String field;
  final String currentValue;
  final String requestedValue;
  final List<String> attachments;
  final DateTime submitted;
  _Status status;
  String remarks;
  final List<_HistoryEntry> history;

  _Request({
    required this.studentName,
    required this.studentId,
    required this.program,
    required this.title,
    required this.field,
    required this.currentValue,
    required this.requestedValue,
    required this.submitted,
    this.attachments = const [],
    this.status = _Status.pending,
    this.remarks = '',
  }) : history = [_HistoryEntry(submitted, 'Request submitted')];

  String get initials {
    final parts = studentName.trim().split(' ');
    return parts.length == 1
        ? parts.first[0]
        : '${parts.first[0]}${parts.last[0]}';
  }
}

String _fmtDate(DateTime d) {
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${m[d.month - 1]} ${d.day}, ${d.year}';
}

// Sample data: replace with your API / database call.
List<_Request> _sampleRequests() => [
  _Request(
    studentName: 'Maria Santos',
    studentId: '2023-0142',
    program: 'BSIT 3',
    title: 'Change of surname',
    field: 'Last name',
    currentValue: 'Santos',
    requestedValue: 'Santos-Reyes',
    submitted: DateTime(2026, 11, 3),
    attachments: ['marriage_certificate.pdf'],
  ),
  _Request(
    studentName: 'John Dela Cruz',
    studentId: '2023-0388',
    program: 'BSIT 3',
    title: 'Correct midterm score',
    field: 'Midterm exam score',
    currentValue: '78',
    requestedValue: '87',
    submitted: DateTime(2026, 11, 5),
    attachments: ['exam_paper_scan.jpg', 'recount_request.pdf'],
    status: _Status.underReview,
  ),
  _Request(
    studentName: 'Angela Ramos',
    studentId: '2022-0911',
    program: 'BSCS 4',
    title: 'Update section',
    field: 'Section',
    currentValue: 'BSCS 4-B',
    requestedValue: 'BSCS 4-A',
    submitted: DateTime(2026, 10, 28),
  ),
  _Request(
    studentName: 'Paolo Mendoza',
    studentId: '2024-0057',
    program: 'BSIT 2',
    title: 'Correct birth date',
    field: 'Date of birth',
    currentValue: 'Mar 12, 2005',
    requestedValue: 'Mar 21, 2005',
    submitted: DateTime(2026, 10, 20),
    attachments: ['birth_certificate.pdf'],
    status: _Status.approved,
    remarks: 'Verified against the PSA copy.',
  ),
  _Request(
    studentName: 'Kyla Bautista',
    studentId: '2023-0620',
    program: 'BSIT 3',
    title: 'Late activity score',
    field: 'Activity 4 score',
    currentValue: '0',
    requestedValue: '90',
    submitted: DateTime(2026, 10, 15),
    status: _Status.rejected,
    remarks: 'Submitted after the posted deadline.',
  ),
];

// ───────────────────────── Shared widgets ─────────────────────────

class _Centered extends StatelessWidget {
  final Widget child;
  const _Centered({required this.child});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: child,
    ),
  );
}

class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Panel({required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.border),
    ),
    child: child,
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: _C.text,
      ),
    ),
  );
}

class _Avatar extends StatelessWidget {
  final String initials;
  final double radius;
  const _Avatar(this.initials, {this.radius = 22});

  // Swap the child for a NetworkImage when you have real profile pictures.
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: _C.primary,
    child: Text(
      initials,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: radius * 0.65,
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final _Status status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: status.color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status.label,
      style: TextStyle(
        color: status.color,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );
}

InputDecoration _fieldDecoration(String hint, {Widget? prefix}) {
  OutlineInputBorder border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: c),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _C.muted, fontSize: 14),
    prefixIcon: prefix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: border(_C.border),
    disabledBorder: border(_C.border),
    focusedBorder: border(_C.primary),
    border: border(_C.border),
  );
}

// ───────────────────────── Requests list ─────────────────────────

enum _Sort { newest, oldest, nameAZ, nameZA }

class ProfessorEvaluationScreen extends StatefulWidget {
  const ProfessorEvaluationScreen({super.key});

  @override
  State<ProfessorEvaluationScreen> createState() =>
      _ProfessorEvaluationScreenState();
}

class _ProfessorEvaluationScreenState extends State<ProfessorEvaluationScreen> {
  final List<_Request> _requests = _sampleRequests();
  final _searchCtrl = TextEditingController();
  final Set<_Status> _filters = {};
  _Sort _sort = _Sort.newest;

  bool get _hasActiveFilter =>
      _filters.isNotEmpty || _searchCtrl.text.isNotEmpty;

  List<_Request> get _visible {
    final q = _searchCtrl.text.trim().toLowerCase();
    final list = _requests.where((r) {
      final matchesFilter = _filters.isEmpty || _filters.contains(r.status);
      final matchesSearch =
          q.isEmpty ||
          r.studentName.toLowerCase().contains(q) ||
          r.title.toLowerCase().contains(q);
      return matchesFilter && matchesSearch;
    }).toList();

    list.sort(
      (a, b) => switch (_sort) {
        _Sort.newest => b.submitted.compareTo(a.submitted),
        _Sort.oldest => a.submitted.compareTo(b.submitted),
        _Sort.nameAZ => a.studentName.compareTo(b.studentName),
        _Sort.nameZA => b.studentName.compareTo(a.studentName),
      },
    );
    return list;
  }

  int _count(_Status s) => _requests.where((r) => r.status == s).length;

  void _clearFilters() => setState(() {
    _filters.clear();
    _searchCtrl.clear();
    _sort = _Sort.newest;
  });

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;

    return Scaffold(
      backgroundColor: _C.pageBg,
      body: Row(
        children: [
          const ProfessorSidebar(
            currentDestination: ProfessorNavDestination.evaluation,
          ),
          Expanded(
            child: _Centered(
              child: Column(
                children: [
                  // Title
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Modification Requests',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _C.text,
                        ),
                      ),
                    ),
                  ),

                  // Search + sort
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() {}),
                            decoration: _fieldDecoration(
                              'Search by student or request',
                              prefix: const Icon(Icons.search, color: _C.muted),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        PopupMenuButton<_Sort>(
                          tooltip: 'Sort',
                          initialValue: _sort,
                          offset: const Offset(0, 52),
                          onSelected: (v) => setState(() => _sort = v),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: _Sort.newest,
                              child: Text('Date submitted: newest'),
                            ),
                            PopupMenuItem(
                              value: _Sort.oldest,
                              child: Text('Date submitted: oldest'),
                            ),
                            PopupMenuItem(
                              value: _Sort.nameAZ,
                              child: Text('Student name: A to Z'),
                            ),
                            PopupMenuItem(
                              value: _Sort.nameZA,
                              child: Text('Student name: Z to A'),
                            ),
                          ],
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _C.border),
                            ),
                            child: const Icon(
                              Icons.swap_vert,
                              color: _C.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status filters with totals
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in _Status.values)
                            _FilterPill(
                              status: s,
                              count: _count(s),
                              selected: _filters.contains(s),
                              onTap: () => setState(
                                () => _filters.contains(s)
                                    ? _filters.remove(s)
                                    : _filters.add(s),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Result count + clear filter
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 14, 0),
                    child: Row(
                      children: [
                        Text(
                          '${items.length} ${items.length == 1 ? 'request' : 'requests'}',
                          style: const TextStyle(color: _C.muted, fontSize: 13),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _hasActiveFilter ? _clearFilters : null,
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Clear filter'),
                        ),
                      ],
                    ),
                  ),

                  // List or empty state
                  Expanded(
                    child: items.isEmpty
                        ? const _EmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => _RequestCard(
                              request: items[i],
                              onView: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _RequestDetailsScreen(
                                    request: items[i],
                                    onChanged: () => setState(() {}),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final _Status status;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill({
    required this.status,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: selected ? status.color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? status.color : _C.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: status.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              status.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _C.body,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: status.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inbox_outlined, size: 56, color: _C.border),
        SizedBox(height: 10),
        Text(
          'No requests found',
          style: TextStyle(fontSize: 16, color: _C.muted),
        ),
      ],
    ),
  );
}

class _RequestCard extends StatelessWidget {
  final _Request request;
  final VoidCallback onView;
  const _RequestCard({required this.request, required this.onView});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(request.initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.studentName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _C.body,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.title,
                      style: const TextStyle(fontSize: 13, color: _C.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _StatusBadge(request.status),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _C.border),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: _C.muted,
              ),
              const SizedBox(width: 6),
              Text(
                'Submitted ${_fmtDate(request.submitted)}',
                style: const TextStyle(fontSize: 12, color: _C.muted),
              ),
              const Spacer(),
              TextButton(
                onPressed: onView,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View details'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Request details ─────────────────────────

class _RequestDetailsScreen extends StatefulWidget {
  final _Request request;
  final VoidCallback onChanged;
  const _RequestDetailsScreen({required this.request, required this.onChanged});

  @override
  State<_RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<_RequestDetailsScreen> {
  late final TextEditingController _remarksCtrl;

  _Request get r => widget.request;
  bool get _decided =>
      r.status == _Status.approved || r.status == _Status.rejected;

  @override
  void initState() {
    super.initState();
    _remarksCtrl = TextEditingController(text: r.remarks);
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );

  void _markUnderReview() {
    setState(() {
      r.status = _Status.underReview;
      r.history.add(_HistoryEntry(DateTime.now(), 'Marked as under review'));
    });
    widget.onChanged();
  }

  void _submitRemarks() {
    final text = _remarksCtrl.text.trim();
    setState(() {
      r.remarks = text;
      r.history.add(_HistoryEntry(DateTime.now(), 'Remarks added', text));
    });
    widget.onChanged();
    _toast('Remarks saved');
  }

  Future<void> _decide(_Status decision) async {
    final approving = decision == _Status.approved;
    final hasRemarks = _remarksCtrl.text.trim().isNotEmpty;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ConfirmDialog(
        title: approving ? 'Approve this request?' : 'Decline this request?',
        message:
            'The student will be notified of your decision${hasRemarks ? ' along with your remarks.' : '.'}',
        confirmColor: decision.color,
      ),
    );
    if (confirmed != true || !mounted) return;

    final remarks = _remarksCtrl.text.trim();
    setState(() {
      r.status = decision;
      r.remarks = remarks;
      r.history
        ..add(
          _HistoryEntry(
            DateTime.now(),
            approving ? 'Approved' : 'Declined',
            remarks.isEmpty ? null : remarks,
          ),
        )
        ..add(_HistoryEntry(DateTime.now(), 'Notification sent to student'));
    });
    widget.onChanged();
    _toast(
      '${approving ? 'Approved' : 'Declined'}. ${r.studentName} has been notified.',
    );
  }

  ButtonStyle _decisionStyle(Color color) => FilledButton.styleFrom(
    backgroundColor: color,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        leading: const BackButton(color: _C.muted),
        title: const Text(
          'Request Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _C.text,
          ),
        ),
      ),
      body: _Centered(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            // Student information
            _Panel(
              child: Row(
                children: [
                  _Avatar(r.initials, radius: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.studentName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _C.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${r.studentId}  ·  ${r.program}',
                          style: const TextStyle(color: _C.muted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Submitted ${_fmtDate(r.submitted)}',
                          style: const TextStyle(fontSize: 12, color: _C.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(r.status),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Current value vs requested change
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(r.title),
                  Text(
                    'Field: ${r.field}',
                    style: const TextStyle(color: _C.muted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ValueBox(
                          label: 'Current value',
                          value: r.currentValue,
                          background: const Color(0xFFF1F5F9),
                          accent: _C.muted,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: _C.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: _C.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _ValueBox(
                          label: 'Requested change',
                          value: r.requestedValue,
                          background: _C.primarySoft,
                          accent: _C.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Attached files (optional)
            if (r.attachments.isNotEmpty) ...[
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Attached files'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final f in r.attachments)
                          ActionChip(
                            avatar: const Icon(Icons.attach_file, size: 16),
                            label: Text(f),
                            backgroundColor: _C.pageBg,
                            side: const BorderSide(color: _C.border),
                            onPressed: () => _toast('Opening $f'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Review actions
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Review'),
                  if (r.status == _Status.pending) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _markUnderReview,
                        icon: const Icon(Icons.rate_review_outlined, size: 18),
                        label: const Text('Mark as under review'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: _remarksCtrl,
                    enabled: !_decided,
                    maxLines: 3,
                    onChanged: (_) => setState(() {}),
                    decoration: _fieldDecoration(
                      'Add comments or remarks (optional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _C.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _decided || _remarksCtrl.text.trim().isEmpty
                          ? null
                          : _submitRemarks,
                      child: const Text('Submit remarks'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: _decisionStyle(_Status.approved.color),
                          onPressed: _decided
                              ? null
                              : () => _decide(_Status.approved),
                          child: const Text('Approve'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: _decisionStyle(_Status.rejected.color),
                          onPressed: _decided
                              ? null
                              : () => _decide(_Status.rejected),
                          child: const Text('Decline'),
                        ),
                      ),
                    ],
                  ),
                  if (_decided) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: r.status.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'This request was ${r.status.label.toLowerCase()}. The student has been notified.',
                        style: TextStyle(
                          color: r.status.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // History timeline
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('History'),
                  for (var i = 0; i < r.history.length; i++)
                    _TimelineRow(
                      entry: r.history[r.history.length - 1 - i],
                      isLast: i == r.history.length - 1,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueBox extends StatelessWidget {
  final String label;
  final String value;
  final Color background;
  final Color accent;
  const _ValueBox({
    required this.label,
    required this.value,
    required this.background,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: accent,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _C.text,
          ),
        ),
      ],
    ),
  );
}

class _TimelineRow extends StatelessWidget {
  final _HistoryEntry entry;
  final bool isLast;
  const _TimelineRow({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 5),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: _C.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: _C.border)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.action,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _C.body,
                    ),
                  ),
                  Text(
                    _fmtDate(entry.date),
                    style: const TextStyle(fontSize: 12, color: _C.muted),
                  ),
                  if (entry.remarks != null && entry.remarks!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Remarks: ${entry.remarks}',
                        style: const TextStyle(color: _C.muted),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Confirmation dialog ─────────────────────────

class _ConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final Color confirmColor;
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmColor,
  });

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  bool _choiceMade = false; // disables both buttons once a choice is made

  void _choose(bool value) {
    setState(() => _choiceMade = true);
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _C.text,
        ),
      ),
      content: Text(widget.message, style: const TextStyle(color: _C.muted)),
      actions: [
        TextButton(
          onPressed: _choiceMade ? null : () => _choose(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: widget.confirmColor),
          onPressed: _choiceMade ? null : () => _choose(true),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
