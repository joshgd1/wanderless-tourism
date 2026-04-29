import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_client.dart';
import '../../../../core/onboarding_provider.dart';
import '../../../../shared/models/trip_plan.dart';

class CreateTripPlanScreen extends ConsumerStatefulWidget {
  const CreateTripPlanScreen({super.key});

  @override
  ConsumerState<CreateTripPlanScreen> createState() => _CreateTripPlanScreenState();
}

class _CreateTripPlanScreenState extends ConsumerState<CreateTripPlanScreen> {
  final _destController = TextEditingController();
  final _dateController = TextEditingController();
  double _durationHours = 4.0;
  int _groupSize = 2;

  final List<String> _selectedInterests = [];
  final List<ProposedStop> _stops = [];

  bool _isSubmitting = false;

  final _allInterests = ['Food', 'Culture', 'Adventure', 'Nature', 'Wellness', 'History'];

  void _addStop() {
    showDialog(
      context: context,
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        double hrs = 1.5;
        final notesCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Add Stop'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Stop name', hintText: 'e.g. Wat Phra Singh'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Duration: '),
                      Expanded(
                        child: Slider(
                          value: hrs,
                          min: 0.5,
                          max: 6.0,
                          divisions: 11,
                          label: '${hrs.toStringAsFixed(1)}h',
                          onChanged: (v) => setDialogState(() => hrs = v),
                        ),
                      ),
                      Text('${hrs.toStringAsFixed(1)}h'),
                    ],
                  ),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notes (optional)'),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    setState(() {
                      _stops.add(ProposedStop(
                        name: nameCtrl.text.trim(),
                        durationHours: hrs,
                        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                      ));
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_destController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination')),
      );
      return;
    }
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one interest')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final touristId = await ref.read(touristIdProvider.future);
      if (touristId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete onboarding first')),
        );
        return;
      }

      final api = ApiClient();
      await api.createTripPlan({
        'tourist_id': touristId,
        'destination': _destController.text.trim(),
        'interests': _selectedInterests.join('|'),
        'proposed_stops': _stops.map((s) => s.toJson()).toList(),
        'tour_date': _dateController.text.trim().isEmpty ? null : _dateController.text.trim(),
        'duration_hours': _durationHours,
        'group_size': _groupSize,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip plan posted! Guides can now accept it.'),
            backgroundColor: Color(0xFF25D366),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _destController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2E1A),
        foregroundColor: Colors.white,
        title: const Text('Propose a Trip'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Destination
            _sectionLabel('Destination'),
            TextField(
              controller: _destController,
              decoration: _inputDecoration('e.g. Chiang Mai, Thailand'),
            ),
            const SizedBox(height: 20),

            // Date
            _sectionLabel('Preferred Date'),
            TextField(
              controller: _dateController,
              decoration: _inputDecoration('e.g. 2026-05-15').copyWith(
                hintText: 'YYYY-MM-DD (optional)',
              ),
            ),
            const SizedBox(height: 20),

            // Duration + group size
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Duration'),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _durationHours,
                              min: 1,
                              max: 12,
                              divisions: 22,
                              label: '${_durationHours.toStringAsFixed(1)}h',
                              activeColor: const Color(0xFF25D366),
                              onChanged: (v) => setState(() => _durationHours = v),
                            ),
                          ),
                          Text('${_durationHours.toStringAsFixed(1)}h'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Group Size'),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _groupSize > 1
                                ? () => setState(() => _groupSize--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: const Color(0xFF25D366),
                          ),
                          Text('$_groupSize', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            onPressed: _groupSize < 15
                                ? () => setState(() => _groupSize++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                            color: const Color(0xFF25D366),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Interests
            _sectionLabel('Interests'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allInterests.map((interest) {
                final selected = _selectedInterests.contains(interest.toLowerCase());
                return FilterChip(
                  label: Text(interest),
                  selected: selected,
                  selectedColor: const Color(0xFF25D366).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF25D366),
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        _selectedInterests.add(interest.toLowerCase());
                      } else {
                        _selectedInterests.remove(interest.toLowerCase());
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Proposed stops
            Row(
              children: [
                _sectionLabel('Proposed Stops'),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addStop,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Stop'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF25D366)),
                ),
              ],
            ),
            if (_stops.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(
                  child: Text('No stops added yet — tap "Add Stop" to propose your itinerary',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...List.generate(_stops.length, (i) {
                final stop = _stops[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF25D366),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    title: Text(stop.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${stop.durationHours.toStringAsFixed(1)}h${stop.notes != null ? ' — ${stop.notes}' : ''}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _stops.removeAt(i)),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Post Trip Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1A2E1A)),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF25D366), width: 2)),
    );
  }
}
