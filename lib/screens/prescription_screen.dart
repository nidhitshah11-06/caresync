import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart' as app;

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  static const Color _teal = Color(0xFF2E7D6E);

  bool _isLoading = true;
  List<_PrescriptionCard> _prescriptions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPrescriptions();
  }

  Future<void> _fetchPrescriptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch prescriptions (newest first).
      final response = await app.supabase
          .from('prescriptions')
          .select('*')
          .order('prescription_date', ascending: false)
          .limit(200);

      final presList = (response as List<dynamic>).cast<Map<String, dynamic>>();
      final ids = presList
          .map((p) => p['id'])
          .whereType<int>()
          .toList();

      List<Map<String, dynamic>> medicinesRows = [];
      if (ids.isNotEmpty) {
        // Join in memory: fetch medicines per prescription to avoid reliance
        // on `.in_()` support across supabase_flutter versions.
        for (final id in ids) {
          final medsResponse = await app.supabase
              .from('medicines')
              .select('*')
              .eq('prescription_id', id)
              .limit(200);

          medicinesRows.addAll((medsResponse as List<dynamic>)
              .cast<Map<String, dynamic>>());
        }
      }

      // Join in memory: prescription_id -> medicines list.
      final Map<int, List<Map<String, dynamic>>> medsByPrescriptionId = {};
      for (final m in medicinesRows) {
        final pid = m['prescription_id'];
        if (pid is int) {
          medsByPrescriptionId.putIfAbsent(pid, () => []).add(m);
        }
      }

      final cards = presList.map((p) {
        final int? id = p['id'] is int ? p['id'] as int : null;
        final doctorName = (p['doctor_name'] ?? p['doctorName'] ?? '').toString();
        final hospitalName =
            (p['hospital_name'] ?? p['hospitalName'] ?? '').toString();
        final originalImageUrl = (p['original_image_url'] ??
                p['originalImageUrl'] ??
                p['original_image'] ??
                p['originalImage'])
            .toString();

        final dateRaw = p['prescription_date'] ?? p['prescriptionDate'] ?? p['date'];
        final date = _parseDate(dateRaw);

        final meds = <_MedicineRow>[];
        if (id != null && medsByPrescriptionId.containsKey(id)) {
          for (final m in medsByPrescriptionId[id]!) {
            final name = (m['dosage'] ??
                    m['medicine_dosage'] ??
                    m['dosage_text'] ??
                    m['name'])
                ?.toString() ??
                '';
            final timing = m['timing']?.toString();
            meds.add(_MedicineRow(
              displayDosage: name.isNotEmpty ? name : '—',
              timing: timing,
            ));
          }
        }

        return _PrescriptionCard(
          id: id ?? 0,
          doctorName: doctorName.isNotEmpty ? doctorName : 'Unknown Doctor',
          hospitalName: hospitalName,
          prescriptionDateText: date ?? '—',
          originalImageUrl: originalImageUrl,
          medicines: meds,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _prescriptions = cards;
        _isLoading = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  static String? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return _formatDate(value);
    if (value is String) {
      final dt = DateTime.tryParse(value);
      return dt == null ? value : _formatDate(dt);
    }
    if (value is int) {
      // Heuristic: seconds vs ms.
      final ms = value.toString().length <= 10 ? value * 1000 : value;
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return _formatDate(dt);
    }
    return value.toString();
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        title: const Text(
          'My Prescriptions',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator(color: _teal));
            }

            if (_prescriptions.isEmpty) {
              return const Center(
                child: Text(
                  'No prescriptions yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            if (_error != null) {
              // Still show what we have; error can be used for debugging.
              return RefreshIndicator(
                onRefresh: _fetchPrescriptions,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _prescriptions.length,
                  itemBuilder: (context, index) {
                    return _PrescriptionCardWidget(
                      teal: _teal,
                      card: _prescriptions[index],
                    );
                  },
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _fetchPrescriptions,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _prescriptions.length,
                itemBuilder: (context, index) {
                  return _PrescriptionCardWidget(
                    teal: _teal,
                    card: _prescriptions[index],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PrescriptionCard {
  final int id;
  final String doctorName;
  final String hospitalName;
  final String prescriptionDateText;
  final String originalImageUrl;
  final List<_MedicineRow> medicines;

  const _PrescriptionCard({
    required this.id,
    required this.doctorName,
    required this.hospitalName,
    required this.prescriptionDateText,
    required this.originalImageUrl,
    required this.medicines,
  });
}

class _MedicineRow {
  final String displayDosage;
  final String? timing;

  const _MedicineRow({
    required this.displayDosage,
    required this.timing,
  });
}

class _PrescriptionCardWidget extends StatelessWidget {
  final Color teal;
  final _PrescriptionCard card;

  const _PrescriptionCardWidget({
    required this.teal,
    required this.card,
  });

  Future<void> _viewOriginalPhoto(BuildContext context) async {
    final url = card.originalImageUrl;
    if (url.isEmpty || url == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Original prescription photo not available.')),
      );
      return;
    }

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Original Prescription'),
        content: SizedBox(
          width: double.maxFinite,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('Failed to load image.')),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.doctorName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              card.hospitalName,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Date: ${card.prescriptionDateText}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Medicines:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (card.medicines.isEmpty)
              const Text(
                '—',
                style: TextStyle(color: Colors.grey),
              )
            else
              Column(
                children: card.medicines.map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.medication, size: 16, color: Color(0xFF2E7D6E)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            m.timing != null && m.timing!.isNotEmpty
                                ? '${m.displayDosage} (${m.timing})'
                                : m.displayDosage,
                            style: const TextStyle(fontSize: 13),
                          ),
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _viewOriginalPhoto(context),
                icon: const Icon(Icons.photo),
                label: const Text('View Original Prescription Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

