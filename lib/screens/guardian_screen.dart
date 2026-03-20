import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

enum DoseStatus { taken, pending, missed }

class GuardianScreen extends StatefulWidget {
  const GuardianScreen({super.key});

  @override
  State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen> {
  static const Color _teal = Color(0xFF2E7D6E);

  // Demo/required labels.
  static const String _patientName = 'Ramabai Patil';
  static const String _relationship = 'Mother';

  // Expected dose schedule for "Today" rendering.
  // (Statuses are derived from `dose_logs` when available.)
  final List<_ExpectedDose> _expectedToday = [
    _ExpectedDose('Metformin 500mg', const TimeOfDay(hour: 8, minute: 5)),
    _ExpectedDose('Amlodipine 5mg', const TimeOfDay(hour: 8, minute: 5)),
    _ExpectedDose('Ecosprin 75mg', const TimeOfDay(hour: 21, minute: 5)),
  ];

  // Realtime channel.
  RealtimeChannel? _channel;

  bool _isLoading = true;
  String _lastActiveText = '—';
  double _weeklyAdherence = 0.0; // 0..1

  List<_TodayDoseRow> _todayRows = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _fetchAndCompute();
    _subscribeToDoseLogs();
  }

  Future<List<Map<String, dynamic>>> _fetchDoseLogsRows() async {
    // We use `select('*')` to be resilient to column naming differences
    // (the UI will attempt to interpret whatever timestamp/status fields exist).
    final result =
        await supabase.from('dose_logs').select('*').limit(500);

    return (result as List<dynamic>).cast<Map<String, dynamic>>();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      // Heuristic: treat seconds as 10 digits and ms as 13 digits.
      if (value.toString().length <= 10) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static DoseStatus _normalizeStatus(dynamic row) {
    final rawStatus = row['status'] ??
        row['dose_status'] ??
        row['taken_status'] ??
        row['state'];

    if (rawStatus is String) {
      final v = rawStatus.toLowerCase().trim();
      if (v == 'taken' || v == 'completed' || v == 'yes') {
        return DoseStatus.taken;
      }
      if (v == 'missed' || v == 'no' || v == 'failed') {
        return DoseStatus.missed;
      }
      if (v == 'pending' || v == 'scheduled' || v == 'upcoming') {
        return DoseStatus.pending;
      }
    }

    final taken = row['taken'] ?? row['is_taken'] ?? row['dose_taken'];
    if (taken == true) return DoseStatus.taken;
    if (taken == false) return DoseStatus.pending;

    // Default to pending when we can't infer.
    return DoseStatus.pending;
  }

  static String _parseMedicineName(Map<String, dynamic> row) {
    final name = row['medicine_name'] ??
        row['medicine'] ??
        row['medication'] ??
        row['name'];
    return (name ?? 'Unknown').toString();
  }

  static DateTime? _extractRowDoseTime(Map<String, dynamic> row) {
    return _parseDateTime(
      row['scheduled_time'] ??
          row['dose_time'] ??
          row['scheduled_at'] ??
          row['dose_at'] ??
          row['taken_at'] ??
          row['created_at'] ??
          row['timestamp'],
    );
  }

  Future<void> _fetchAndCompute() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final doseLogs = await _fetchDoseLogsRows();

      final todaysExpected = _expectedToday.map((d) {
        final scheduled = DateTime(
          today.year,
          today.month,
          today.day,
          d.time.hour,
          d.time.minute,
        );
        return scheduled;
      }).toList();

      // Weekly adherence: approximate by counting dose_logs in last 7 days
      // where a status/taken flag exists.
      final weekStart = today.subtract(const Duration(days: 6));
      final weekEndExclusive = today.add(const Duration(days: 1));

      int weekTotal = 0;
      int weekTaken = 0;

      DateTime? lastActive;

      // Create today's rows.
      final List<_TodayDoseRow> computed = [];
      for (int i = 0; i < _expectedToday.length; i++) {
        final expected = _expectedToday[i];
        final scheduled = todaysExpected[i];

        final matching = doseLogs.where((row) {
          final medicine = _parseMedicineName(row);
          final rowDoseTime = _extractRowDoseTime(row);
          if (medicine.toLowerCase() != expected.medicineName.toLowerCase()) {
            return false;
          }
          if (rowDoseTime == null) return false;
          // Match within the same minute.
          return rowDoseTime.year == scheduled.year &&
              rowDoseTime.month == scheduled.month &&
              rowDoseTime.day == scheduled.day &&
              rowDoseTime.hour == scheduled.hour &&
              rowDoseTime.minute == scheduled.minute;
        }).toList();

        DoseStatus status;
        if (matching.isNotEmpty) {
          // If multiple logs exist, prefer "missed" over "pending" over "taken".
          final statuses = matching.map(_normalizeStatus).toList();
          if (statuses.contains(DoseStatus.missed)) {
            status = DoseStatus.missed;
          } else if (statuses.contains(DoseStatus.taken)) {
            status = DoseStatus.taken;
          } else {
            status = DoseStatus.pending;
          }
        } else {
          // If scheduled time already passed, assume missed; otherwise pending.
          status = scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)
              ? DoseStatus.missed
              : DoseStatus.pending;
        }

        computed.add(
          _TodayDoseRow(
            medicineName: expected.medicineName,
            timeLabel: _formatTimeOfDay(expected.time),
            status: status,
          ),
        );
      }

      // Compute adherence + last active.
      for (final row in doseLogs) {
        final rowDoseTime = _extractRowDoseTime(row);
        if (rowDoseTime == null) continue;

        if (!rowDoseTime.isBefore(weekStart) &&
            rowDoseTime.isBefore(weekEndExclusive)) {
          // Treat each row as one scheduled attempt for approximation.
          weekTotal += 1;
          if (_normalizeStatus(row) == DoseStatus.taken) weekTaken += 1;
        }

        if (lastActive == null || rowDoseTime.isAfter(lastActive)) {
          lastActive = rowDoseTime;
        }
      }

      final adherence = weekTotal == 0 ? 0.0 : (weekTaken / weekTotal);

      if (!mounted) return;
      setState(() {
        _todayRows = computed;
        _weeklyAdherence = adherence;
        _lastActiveText = lastActive == null ? '—' : _formatRelative(lastActive);
        _isLoading = false;
      });
    } catch (_) {
      // If table/view isn't set up yet, still render the UI with defaults.
      if (!mounted) return;
      setState(() {
        _todayRows = _expectedToday
            .map((d) => _TodayDoseRow(
                  medicineName: d.medicineName,
                  timeLabel: _formatTimeOfDay(d.time),
                  status: DoseStatus.pending,
                ))
            .toList();
        _weeklyAdherence = 0.0;
        _lastActiveText = '—';
        _isLoading = false;
      });
    }
  }

  static String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $suffix';
  }

  static String _formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _subscribeToDoseLogs() {
    // Guard against multiple subscriptions.
    _channel?.unsubscribe();

    _channel = supabase
        .channel('realtime:dose_logs:${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'dose_logs',
      callback: (payload) {
        // Any changes may affect whether a dose is taken/pending/missed.
        // Debounce by doing a lightweight refresh.
        _fetchAndCompute();
      },
    )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cardShadow = [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 10,
        offset: Offset(0, 4),
      )
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        title: const Text(
          'Guardian Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _patientName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Relationship: $_relationship',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Last active',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _lastActiveText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade900,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Weekly adherence',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${(_weeklyAdherence * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // TODAY'S MEDICINES
              Text(
                "Today's Medicines",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: _todayRows.map((row) {
                  final (Color bg, IconData icon, Color iconColor) =
                      _statusVisual(row.status);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                      border: Border.all(
                        color: bg,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          color: iconColor,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.medicineName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                row.timeLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: bg.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabel(row.status),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: iconColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // ADD GUARDIAN
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Guardian invite flow coming soon.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Guardian'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static (Color, IconData, Color) _statusVisual(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return (const Color(0xFF4CAF50), Icons.check_circle, const Color(0xFF4CAF50));
      case DoseStatus.pending:
        return (const Color(0xFFF5A623), Icons.access_time, const Color(0xFFF5A623));
      case DoseStatus.missed:
        return (const Color(0xFFE53935), Icons.cancel, const Color(0xFFE53935));
    }
  }

  static String _statusLabel(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return 'Taken';
      case DoseStatus.pending:
        return 'Pending';
      case DoseStatus.missed:
        return 'Missed';
    }
  }
}

class _ExpectedDose {
  final String medicineName;
  final TimeOfDay time;

  const _ExpectedDose(this.medicineName, this.time);
}

class _TodayDoseRow {
  final String medicineName;
  final String timeLabel;
  final DoseStatus status;

  const _TodayDoseRow({
    required this.medicineName,
    required this.timeLabel,
    required this.status,
  });
}

