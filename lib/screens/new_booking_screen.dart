// lib/screens/new_booking_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewBookingScreen extends StatefulWidget {
  const NewBookingScreen({super.key});

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  String? _selectedLocation;
  final List<_LocationOption> _locations = const [
    _LocationOption('Auditorium', Icons.theaters_outlined),
    _LocationOption('Seminar Hall', Icons.groups_outlined),
    _LocationOption('Lobby', Icons.meeting_room_outlined),
    _LocationOption('Department', Icons.apartment_outlined),
  ];

  final List<_CategoryOption> _categories = const [
    _CategoryOption('Mic', Icons.mic_none),
    _CategoryOption('Speaker', Icons.speaker_outlined),
    _CategoryOption('Camera', Icons.videocam_outlined),
    _CategoryOption('Light', Icons.light_outlined),
    _CategoryOption('Chairs', Icons.event_seat_outlined),
    _CategoryOption('Tables', Icons.table_bar_outlined),
    _CategoryOption('Carpets', Icons.layers_outlined),
  ];

  final Map<String, int> _selectedQuantities = {'Mic': 1};
  final Map<String, TextEditingController> _quantityControllers = {};

  bool _othersSelected = false;
  final TextEditingController _othersController = TextEditingController();

  final TextEditingController _organizerController = TextEditingController();
  final TextEditingController _occasionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _dateFrom;
  DateTime? _dateTo;
  TimeOfDay? _timeFrom;
  TimeOfDay? _timeTo;

  // NEW: tracks whether we are currently saving to Firestore.
  // We use this to show a loading spinner and to stop the user
  // from tapping "Submit" multiple times in a row.
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (final cat in _categories) {
      _quantityControllers[cat.label] =
          TextEditingController(text: '${_selectedQuantities[cat.label] ?? 1}');
    }
  }

  @override
  void dispose() {
    _organizerController.dispose();
    _occasionController.dispose();
    _notesController.dispose();
    _othersController.dispose();
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleCategory(String label) {
    setState(() {
      if (_selectedQuantities.containsKey(label)) {
        _selectedQuantities.remove(label);
      } else {
        _selectedQuantities[label] = 1;
        _quantityControllers[label]?.text = '1';
      }
    });
  }

  void _changeQuantity(String label, int delta) {
    setState(() {
      final current = _selectedQuantities[label] ?? 1;
      final next = current + delta;
      if (next <= 0) {
        _selectedQuantities.remove(label);
      } else {
        _selectedQuantities[label] = next;
        _quantityControllers[label]?.text = '$next';
      }
    });
  }

  void _onQuantityTyped(String label, String value) {
    final parsed = int.tryParse(value);
    setState(() {
      if (parsed == null || parsed <= 0) {
        return;
      }
      _selectedQuantities[label] = parsed;
    });
  }

  void _toggleOthers() {
    setState(() {
      _othersSelected = !_othersSelected;
      if (!_othersSelected) {
        _othersController.clear();
      }
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  Future<void> _pickTime({required bool isFrom}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _timeFrom = picked;
        } else {
          _timeTo = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date From';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Time From';
    return time.format(context);
  }

  // Helper: turns a TimeOfDay ("2:30 PM") into a plain readable
  // string so we can store it in Firestore (Firestore doesn't
  // understand Flutter's TimeOfDay type directly).
  String? _timeToStoredString(TimeOfDay? time) {
    if (time == null) return null;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _submit() async {
    // ---- Validation (same as before) ----
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a location.')),
      );
      return;
    }
    if (_occasionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Occasion is a mandatory field.')),
      );
      return;
    }

    // Make sure someone is actually logged in before we try to save.
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to book.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Build the list of requested resources, e.g. "Mic x2, Chairs x30"
      final resourceList = _selectedQuantities.entries
          .map((entry) => {'item': entry.key, 'quantity': entry.value})
          .toList();

      if (_othersSelected && _othersController.text.trim().isNotEmpty) {
        resourceList.add({
          'item': _othersController.text.trim(),
          'quantity': 1,
        });
      }

      // IMPORTANT: field names below (bookedByUid, status, purpose,
      // createdAt) must exactly match what BookingTicketScreen queries.
      await FirebaseFirestore.instance.collection('bookings').add({
        'bookedByUid': currentUser.uid,
        'status': 'Pending', // BookingTicketScreen filters/groups by this
        'purpose': _occasionController.text.trim(), // the "Occasion" field
        'location': _selectedLocation,
        'organizerName': _organizerController.text.trim(),
        'resources': resourceList,
        'dateFrom': _dateFrom != null ? Timestamp.fromDate(_dateFrom!) : null,
        'dateTo': _dateTo != null ? Timestamp.fromDate(_dateTo!) : null,
        'timeFrom': _timeToStoredString(_timeFrom),
        'timeTo': _timeToStoredString(_timeTo),
        'notes': _notesController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking request submitted!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFBFA),
        elevation: 0,
        foregroundColor: const Color(0xFF1E1D1A),
        centerTitle: true,
        title: Column(
          children: const [
            Text(
              'New Booking',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16767C),
              ),
            ),
            Text(
              'Request a venue and resources',
              style: TextStyle(fontSize: 11, color: Color(0xFF6B6A63)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Location Details'),
              const SizedBox(height: 8),
              _buildLocationGrid(),
              const SizedBox(height: 20),

              _sectionLabel('Booking Category'),
              const SizedBox(height: 8),
              _buildCategoryGrid(),
              const SizedBox(height: 10),
              _buildOthersBox(),
              const SizedBox(height: 20),

              _sectionLabel('Organizer Name'),
              const SizedBox(height: 8),
              _textField(_organizerController, 'Enter the name of the booking organizer'),
              const SizedBox(height: 20),

              _sectionLabel('Occasion', required: true),
              const SizedBox(height: 8),
              _textField(_occasionController, 'Enter the event name (Mandatory field)'),
              const SizedBox(height: 20),

              _sectionLabel('Booking Duration'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _dateTimeButton(
                      icon: Icons.calendar_today_outlined,
                      label: _formatDate(_dateFrom),
                      onTap: () => _pickDate(isFrom: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dateTimeButton(
                      icon: Icons.calendar_today_outlined,
                      label: _dateTo == null ? 'Date To' : _formatDate(_dateTo),
                      onTap: () => _pickDate(isFrom: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _dateTimeButton(
                      icon: Icons.access_time,
                      label: _formatTime(_timeFrom),
                      onTap: () => _pickTime(isFrom: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dateTimeButton(
                      icon: Icons.access_time,
                      label: _timeTo == null ? 'Time To' : _formatTime(_timeTo),
                      onTap: () => _pickTime(isFrom: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _sectionLabel('Additional Requirements Description'),
              const SizedBox(height: 8),
              _textField(
                _notesController,
                'Describe why you need these resources clearly for the facilities team.',
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16767C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Booking Request',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E1D1A),
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildLocationGrid() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: _locations.map((loc) {
        final isSelected = _selectedLocation == loc.label;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedLocation = loc.label),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFDCEEED) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF16767C) : const Color(0xFFE3DFD3),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(loc.icon, size: 22, color: const Color(0xFF16767C)),
                const SizedBox(height: 6),
                Text(
                  loc.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF3A3833)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: _categories.map((cat) {
        final isSelected = _selectedQuantities.containsKey(cat.label);
        final controller = _quantityControllers[cat.label]!;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _toggleCategory(cat.label),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFDCEEED) : const Color(0xFFFCFBFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF16767C) : const Color(0xFFE3DFD3),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: isSelected
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(cat.icon, size: 18, color: const Color(0xFF16767C)),
                          const SizedBox(width: 6),
                          Text(cat.label, style: const TextStyle(fontSize: 12, color: Color(0xFF1E1D1A))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              iconSize: 16,
                              onPressed: () => _changeQuantity(cat.label, -1),
                              icon: const Icon(Icons.remove, color: Color(0xFF16767C)),
                            ),
                            SizedBox(
                              width: 36,
                              child: TextField(
                                controller: controller,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 6),
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) => _onQuantityTyped(cat.label, value),
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              iconSize: 16,
                              onPressed: () => _changeQuantity(cat.label, 1),
                              icon: const Icon(Icons.add, color: Color(0xFF16767C)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(cat.icon, size: 20, color: const Color(0xFF6B6A63)),
                      const SizedBox(width: 8),
                      Text(cat.label, style: const TextStyle(fontSize: 12, color: Color(0xFF3A3833))),
                    ],
                  ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOthersBox() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _othersSelected ? const Color(0xFFDCEEED) : const Color(0xFFFCFBFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _othersSelected ? const Color(0xFF16767C) : const Color(0xFFE3DFD3),
          width: _othersSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _toggleOthers,
            child: Row(
              children: [
                const Icon(Icons.category_outlined, size: 20, color: Color(0xFF6B6A63)),
                const SizedBox(width: 8),
                const Text('Others', style: TextStyle(fontSize: 12, color: Color(0xFF3A3833))),
                const Spacer(),
                Icon(
                  _othersSelected ? Icons.check_circle : Icons.add_circle_outline,
                  size: 18,
                  color: const Color(0xFF16767C),
                ),
              ],
            ),
          ),
          if (_othersSelected) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _othersController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Type what else you need (no number required)',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFB9B4A6)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE3DFD3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE3DFD3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF16767C), width: 1.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFB9B4A6)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE3DFD3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE3DFD3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF16767C), width: 1.5),
        ),
      ),
    );
  }

  Widget _dateTimeButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE3DFD3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF16767C)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF3A3833)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationOption {
  final String label;
  final IconData icon;
  const _LocationOption(this.label, this.icon);
}

class _CategoryOption {
  final String label;
  final IconData icon;
  const _CategoryOption(this.label, this.icon);
}