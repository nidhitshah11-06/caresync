import 'package:flutter/material.dart';

class VerificationScreen extends StatefulWidget {
  final String? imagePath;
  const VerificationScreen({Key? key, this.imagePath}) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<Map<String, dynamic>> _medicines = [
    {
      'name': 'Metformin 500mg',
      'timing': 'Morning, Night',
      'duration': '30 days',
      'instructions': 'After food',
      'unclear': false,
    },
    {
      'name': 'Amlodipine 5mg',
      'timing': 'Morning',
      'duration': 'UNCLEAR',
      'instructions': 'Before food',
      'unclear': false,
    },
    {
      'name': 'UNCLEAR',
      'timing': '1-0-1',
      'duration': '15 days',
      'instructions': 'UNCLEAR',
      'unclear': true,
    },
  ];

  bool get _hasUnclear => _medicines.any((m) =>
      m['name'] == 'UNCLEAR' ||
      m['timing'] == 'UNCLEAR' ||
      m['duration'] == 'UNCLEAR' ||
      m['instructions'] == 'UNCLEAR');

  void _editField(int index, String field, String current) {
    final controller = TextEditingController(
        text: current == 'UNCLEAR' ? '' : current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit $field',
          style: const TextStyle(
            color: Color(0xFF2E7D6E),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter $field',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2E7D6E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2E7D6E), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _medicines[index][field.toLowerCase()] =
                    controller.text.isEmpty ? 'UNCLEAR' : controller.text;
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D6E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmAndSave() {
    if (_hasUnclear) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '⚠️ Please fix all UNCLEAR fields before confirming'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Prescription saved successfully!'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D6E),
        foregroundColor: Colors.white,
        title: const Text(
          'Verify Prescription',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          if (widget.imagePath != null)
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.image, color: Colors.white, size: 18),
              label: const Text('View Photo',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
        ],
      ),
      body: Column(
        children: [
          // TOP BANNER
          if (_hasUnclear)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF3CD),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFF5A623), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Some fields are UNCLEAR — tap the ✏️ icon to fix them before saving.',
                      style: TextStyle(
                          color: Color(0xFF856404), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // MEDICINE LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _medicines.length,
              itemBuilder: (context, index) {
                final med = _medicines[index];
                return _buildMedicineCard(index, med);
              },
            ),
          ),

          // BOTTOM BUTTONS
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_hasUnclear)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '⚠️ Fix all UNCLEAR fields to enable Save',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color(0xFFE53935), fontSize: 13),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _hasUnclear ? null : _confirmAndSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D6E),
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _hasUnclear
                          ? 'Fix UNCLEAR fields first'
                          : '✅ Confirm & Save Prescription',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(int index, Map<String, dynamic> med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: med['unclear'] == true
              ? const Color(0xFFF5A623)
              : Colors.grey.shade200,
          width: med['unclear'] == true ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CARD HEADER
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: med['unclear'] == true
                  ? const Color(0xFFFFF8E1)
                  : const Color(0xFF2E7D6E).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.medication,
                    color: Color(0xFF2E7D6E), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildUnclearField(
                      med['name'], 'Medicine Name',
                      isHeader: true),
                ),
                IconButton(
                  onPressed: () => _editField(index, 'name', med['name']),
                  icon: const Icon(Icons.edit,
                      color: Color(0xFF2E7D6E), size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // FIELDS
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRow(index, 'Timing', 'timing', med['timing'],
                    Icons.access_time),
                const Divider(height: 20),
                _buildRow(index, 'Duration', 'duration', med['duration'],
                    Icons.calendar_today),
                const Divider(height: 20),
                _buildRow(index, 'Instructions', 'instructions',
                    med['instructions'], Icons.info_outline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(int index, String label, String field, String value,
      IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 18),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(child: _buildUnclearField(value, label)),
        IconButton(
          onPressed: () => _editField(index, label, value),
          icon: const Icon(Icons.edit, color: Color(0xFF2E7D6E), size: 16),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildUnclearField(String value, String label,
      {bool isHeader = false}) {
    final isUnclear = value == 'UNCLEAR';
    return Container(
      padding: isUnclear
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
          : EdgeInsets.zero,
      decoration: isUnclear
          ? BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFF5A623)),
            )
          : null,
      child: Text(
        value,
        style: TextStyle(
          fontSize: isHeader ? 16 : 14,
          fontWeight:
              isHeader ? FontWeight.bold : FontWeight.normal,
          color: isUnclear
              ? const Color(0xFF856404)
              : (isHeader ? Colors.grey[800] : Colors.grey[700]),
        ),
      ),
    );
  }
}