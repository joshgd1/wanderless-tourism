import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/api_client.dart';
import '../../../../core/auth_provider.dart';
import '../../../../shared/models/trip_plan.dart';
import '../../../../design_system.dart';

class CreateTripPlanScreen extends ConsumerStatefulWidget {
  const CreateTripPlanScreen({super.key});

  @override
  ConsumerState<CreateTripPlanScreen> createState() => _CreateTripPlanScreenState();
}

class _CreateTripPlanScreenState extends ConsumerState<CreateTripPlanScreen> {
  final _destController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  double _durationHours = 4.0;
  int _groupSize = 2;

  final List<String> _selectedInterests = [];
  final List<ProposedStop> _stops = [];

  // Dietary constraints (from PPT Slide 6 demo)
  String _dietaryRequirement = 'Any';

  bool _isSubmitting = false;
  bool _isLoadingSuggestions = false;

  final _allInterests = ['Food', 'Culture', 'Adventure', 'Nature', 'Wellness', 'History'];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final authState = ref.read(authProvider);
    final touristId = authState.touristId;
    if (touristId == null) return;

    setState(() => _isLoadingSuggestions = true);
    try {
      final api = ApiClient();
      final destinations = await api.getMlDestinationRecommendations(touristId);
      if (!mounted || destinations.isEmpty) return;

      final top = destinations.first;
      final tags = (top['tags'] as List?)?.cast<String>() ?? [];
      final topDestination = top['name'] as String? ?? '';

      if (topDestination.isNotEmpty) {
        _destController.text = topDestination;
      }

      // Pre-select interests that match destination tags
      final matchedInterests = _allInterests
          .where((interest) => tags.contains(interest.toLowerCase()))
          .map((interest) => interest.toLowerCase())
          .toList();

      if (matchedInterests.isNotEmpty) {
        setState(() {
          _selectedInterests.clear();
          _selectedInterests.addAll(matchedInterests);
        });
      }
    } catch (_) {
      // Silently ignore — form works without suggestions
    } finally {
      if (mounted) setState(() => _isLoadingSuggestions = false);
    }
  }

  Future<void> _selectDateRange() async {
    final initial = DateTimeRange(
      start: _startDate ?? DateTime.now().add(const Duration(days: 1)),
      end: _endDate ?? DateTime.now().add(const Duration(days: 3)),
    );
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.brand,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (range == null) return;
    setState(() {
      _startDate = range.start;
      _endDate = range.end;
    });
  }

  void _addStop() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _AddStopSheet(
          onAdd: (stop) => setState(() => _stops.add(stop)),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_destController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a destination'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      );
      return;
    }
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Select at least one interest'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authState = ref.read(authProvider);
      final touristId = authState.touristId;
      if (touristId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please sign in first'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
          );
        }
        return;
      }

      final api = ApiClient();
      await api.createTripPlan({
        'tourist_id': touristId,
        'destination': _destController.text.trim(),
        'interests': _selectedInterests.join('|'),
        'proposed_stops': _stops.map((s) => s.toJson()).toList(),
        'tour_date_start': _startDate == null ? null : DateFormat('yyyy-MM-dd').format(_startDate!),
        'tour_date_end': _endDate == null ? null : DateFormat('yyyy-MM-dd').format(_endDate!),
        'duration_hours': _durationHours,
        'group_size': _groupSize,
        'dietary_requirement': _dietaryRequirement,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Trip plan posted! Guides can now accept it.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _destController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: AppColors.textPrimary,
            leadingWidth: 0,
            leading: const SizedBox.shrink(),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.textPrimary,
                child: SafeArea(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: GridPainter()),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                        child: Row(
                          children: [
                            _BackBtn(onTap: () => context.pop()),
                            const SizedBox(width: 12),
                            Text(
                              'Propose a Trip',
                              style: AppText.h3.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(isWide ? AppSpacing.lg : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(label: 'Destination', icon: Icons.place_outlined),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          controller: _destController,
                          hint: 'e.g. Singapore',
                          prefix: const Icon(Icons.tour_outlined, size: 18, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(label: 'Preferred Date Range', icon: Icons.calendar_today_outlined),
                        const SizedBox(height: AppSpacing.sm),
                        _DateRangePicker(
                          startDate: _startDate,
                          endDate: _endDate,
                          onTap: () => _selectDateRange(),
                          onClear: () => setState(() { _startDate = null; _endDate = null; }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionTitle(label: 'Duration', icon: Icons.schedule_outlined),
                                  const SizedBox(height: AppSpacing.sm),
                                  _SliderRow(
                                    value: _durationHours,
                                    min: 1,
                                    max: 12,
                                    divisions: 22,
                                    label: '${_durationHours.toStringAsFixed(1)}h',
                                    onChanged: (v) => setState(() => _durationHours = v),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionTitle(label: 'Group Size', icon: Icons.group_outlined),
                                  const SizedBox(height: AppSpacing.sm),
                                  _StepperRow(
                                    value: _groupSize,
                                    min: 1,
                                    max: 15,
                                    onChanged: (v) => setState(() => _groupSize = v),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(label: 'Interests', icon: Icons.interests_outlined),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allInterests.map((interest) {
                            final selected = _selectedInterests.contains(interest.toLowerCase());
                            return _InterestPill(
                              label: interest,
                              isSelected: selected,
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    _selectedInterests.remove(interest.toLowerCase());
                                  } else {
                                    _selectedInterests.add(interest.toLowerCase());
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(label: 'Dietary Requirement', icon: Icons.restaurant_outlined),
                        const SizedBox(height: AppSpacing.sm),
                        _DietaryChips(
                          value: _dietaryRequirement,
                          onChanged: (v) => setState(() => _dietaryRequirement = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _SectionTitle(label: 'Proposed Stops', icon: Icons.place_outlined),
                            const Spacer(),
                            GhostButton(
                              label: 'Add Stop',
                              icon: Icons.add,
                              onPressed: _addStop,
                            ),
                          ],
                        ),
                        if (_stops.isEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: AppColors.textTertiary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No stops added yet — tap "Add Stop" to propose your itinerary',
                                    style: AppText.caption,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: AppSpacing.md),
                          ...List.generate(_stops.length, (i) {
                            final stop = _stops[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: _StopTile(
                                index: i + 1,
                                stop: stop,
                                onRemove: () => setState(() => _stops.removeAt(i)),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_isSubmitting)
                    const AppLoading()
                  else
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: 'Post Trip Plan',
                        icon: Icons.send_outlined,
                        onPressed: _submit,
                      ),
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});

  @override
  State<_BackBtn> createState() => _BackBtnState();
}

class _BackBtnState extends State<_BackBtn> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(Icons.arrow_back, color: Colors.white.withOpacity(_isHovered ? 1 : 0.7), size: 20),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionTitle({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.brand),
        const SizedBox(width: 6),
        Text(label, style: AppText.labelBold),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.brand,
            thumbColor: AppColors.brand,
            overlayColor: AppColors.brand.withOpacity(0.2),
            inactiveTrackColor: AppColors.surfaceSecondary,
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${min.toInt()}h', style: AppText.caption),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.brand.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(label, style: AppText.labelBold.copyWith(color: AppColors.brand)),
            ),
            Text('${max.toInt()}h', style: AppText.caption),
          ],
        ),
      ],
    );
  }
}

class _StepperRow extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _StepperRow({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepperBtn(
          icon: Icons.remove,
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        const SizedBox(width: 12),
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text('$value', style: AppText.h2),
        ),
        const SizedBox(width: 12),
        _StepperBtn(
          icon: Icons.add,
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _StepperBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepperBtn({required this.icon, this.onPressed});

  @override
  State<_StepperBtn> createState() => _StepperBtnState();
}

class _StepperBtnState extends State<_StepperBtn> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    return MouseRegion(
      onEnter: (_) {
        if (widget.onPressed != null) setState(() => _isHovered = true);
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDisabled
                ? AppColors.surfaceSecondary
                : _isHovered
                    ? AppColors.brand.withOpacity(0.1)
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: isDisabled ? AppColors.border : AppColors.brand,
              width: 1.5,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: isDisabled ? AppColors.textTertiary : AppColors.brand,
          ),
        ),
      ),
    );
  }
}

class _InterestPill extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _InterestPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_InterestPill> createState() => _InterestPillState();
}

class _InterestPillState extends State<_InterestPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.brand
                : _isHovered
                    ? AppColors.surfaceSecondary
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: widget.isSelected ? AppColors.brand : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Text(
            widget.label,
            style: AppText.label.copyWith(
              color: widget.isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _DietaryChips extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _DietaryChips({required this.value, required this.onChanged});

  static const _options = ['Any', 'Halal', 'Vegetarian', 'Vegan', 'Kosher', 'Gluten-free'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options.map((option) {
        final selected = value == option;
        return _DietaryChip(
          label: option,
          isSelected: selected,
          onTap: () => onChanged(option),
        );
      }).toList(),
    );
  }
}

class _DietaryChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DietaryChip({required this.label, required this.isSelected, required this.onTap});

  @override
  State<_DietaryChip> createState() => _DietaryChipState();
}

class _DietaryChipState extends State<_DietaryChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.brand
                : _isHovered
                    ? AppColors.surfaceSecondary
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: widget.isSelected ? AppColors.brand : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Text(
            widget.label,
            style: AppText.label.copyWith(
              color: widget.isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  final int index;
  final ProposedStop stop;
  final VoidCallback onRemove;

  const _StopTile({
    required this.index,
    required this.stop,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.brand,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$index',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stop.name, style: AppText.labelBold),
              if (stop.notes != null)
                Text(stop.notes!, style: AppText.caption),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text('${stop.durationHours.toStringAsFixed(1)}h', style: AppText.caption),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.close, size: 16),
          onPressed: onRemove,
          color: AppColors.textTertiary,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        ),
      ],
    );
  }
}

class _DateRangePicker extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateRangePicker({
    required this.startDate,
    required this.endDate,
    required this.onTap,
    required this.onClear,
  });

  String get _label {
    if (startDate == null && endDate == null) return 'Select dates';
    if (startDate != null && endDate != null) {
      return '${DateFormat('MMM d').format(startDate!)} – ${DateFormat('MMM d, yyyy').format(endDate!)}';
    }
    if (startDate != null) return '${DateFormat('MMM d, yyyy').format(startDate!)} – Select end';
    return '${DateFormat('MMM d').format(endDate!)} – Select start';
  }

  @override
  Widget build(BuildContext context) {
    final hasRange = startDate != null || endDate != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.date_range,
              size: 18,
              color: hasRange ? AppColors.brand : AppColors.textTertiary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _label,
                style: AppText.body.copyWith(
                  color: hasRange ? AppColors.textPrimary : AppColors.textTertiary,
                ),
              ),
            ),
            if (hasRange)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 16, color: AppColors.textTertiary),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddStopSheet extends StatefulWidget {
  final void Function(ProposedStop) onAdd;

  const _AddStopSheet({required this.onAdd});

  @override
  State<_AddStopSheet> createState() => _AddStopSheetState();
}

class _AddStopSheetState extends State<_AddStopSheet> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  double _durationHours = 1.5;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Add Stop', style: AppText.h2),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _nameController,
            label: 'Stop name',
            hint: 'e.g. Wat Phra Singh',
            prefix: const Icon(Icons.place_outlined, size: 18, color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Duration', style: AppText.label),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.brand,
                    thumbColor: AppColors.brand,
                    overlayColor: AppColors.brand.withOpacity(0.2),
                    inactiveTrackColor: AppColors.surfaceSecondary,
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: _durationHours,
                    min: 0.5,
                    max: 6.0,
                    divisions: 11,
                    onChanged: (v) => setState(() => _durationHours = v),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '${_durationHours.toStringAsFixed(1)}h',
                  style: AppText.labelBold.copyWith(color: AppColors.brand),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _notesController,
            label: 'Notes (optional)',
            hint: 'Any details about this stop...',
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Add Stop',
                  icon: Icons.add,
                  onPressed: () {
                    if (_nameController.text.trim().isEmpty) return;
                    widget.onAdd(ProposedStop(
                      name: _nameController.text.trim(),
                      durationHours: _durationHours,
                      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                    ));
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

