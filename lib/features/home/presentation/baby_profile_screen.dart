import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/screen_background.dart';
import 'baby_care_models.dart';

class BabyProfileScreen extends StatefulWidget {
  const BabyProfileScreen({super.key});

  @override
  State<BabyProfileScreen> createState() => _BabyProfileScreenState();
}

class _BabyProfileScreenState extends State<BabyProfileScreen> {
  @override
  void initState() {
    super.initState();
    BabyProfileStore.fetchAll();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Stack(
      children: [
        const ScreenBackground(),
        SafeArea(
          child: Column(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: _header(context),
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: BabyProfileStore.isLoading,
                      builder: (context, loading, _) =>
                          ValueListenableBuilder<List<BabyProfile>>(
                            valueListenable: BabyProfileStore.babies,
                            builder: (context, babies, _) {
                              if (loading && babies.isEmpty) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                );
                              }
                              if (babies.isEmpty) {
                                return Center(
                                  child: Text(
                                    'No baby profiles yet.\nTap + to add one.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunitoSans(
                                      fontSize: 14,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                );
                              }
                              return ValueListenableBuilder<String>(
                                valueListenable: BabyProfileStore.activeBabyId,
                                builder: (context, activeId, _) =>
                                    RefreshIndicator(
                                      color: AppColors.primary,
                                      onRefresh: BabyProfileStore.fetchAll,
                                      child: ListView.separated(
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          16,
                                          20,
                                          90,
                                        ),
                                        itemCount: babies.length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, index) =>
                                            _babyCard(
                                              babies[index],
                                              babies[index].id == activeId,
                                              true,
                                            ),
                                      ),
                                    ),
                              );
                            },
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    floatingActionButton: ValueListenableBuilder<List<BabyProfile>>(
      valueListenable: BabyProfileStore.babies,
      builder: (context, babies, _) => babies.isNotEmpty
          ? const SizedBox.shrink()
          : FloatingActionButton(
              onPressed: () => _openBabyForm(),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
    ),
  );

  Widget _header(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.2),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Baby profile',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'View or update your baby\'s information.',
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _babyCard(BabyProfile baby, bool active, bool canRemove) => InkWell(
    borderRadius: BorderRadius.circular(22),
    onTap: active ? null : () => BabyProfileStore.setActive(baby.id),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: active
              ? AppColors.secondary
              : AppColors.outlineVariant.withValues(alpha: 0.25),
          width: active ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _avatar(baby, size: 54),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        baby.name,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (active) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  babyAgeLabel(baby.dateOfBirth),
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${baby.gender.label} · Born ${MaterialLocalizations.of(context).formatMediumDate(baby.dateOfBirth)}',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => _openBabyForm(existing: baby),
                tooltip: 'Edit',
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 19,
                ),
              ),
              if (canRemove)
                IconButton(
                  onPressed: () => _confirmRemove(baby),
                  tooltip: 'Remove',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 19,
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _avatar(BabyProfile baby, {required double size}) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Color(0xFFD3BBFE),
      shape: BoxShape.circle,
    ),
    clipBehavior: Clip.antiAlias,
    child: Icon(
      Icons.child_care_rounded,
      color: AppColors.primary,
      size: size * 0.5,
    ),
  );

  Future<void> _confirmRemove(BabyProfile baby) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove baby profile?'),
        content: Text(
          'This permanently deletes ${baby.name}\'s profile. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await BabyProfileStore.removeBaby(baby.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${baby.name} removed.')));
      }
    } catch (e) {
      _showError('Could not remove profile: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  void _openBabyForm({BabyProfile? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    DateTime dob = existing?.dateOfBirth ?? DateTime.now();
    BabyGender gender = existing?.gender ?? BabyGender.other;
    double birthWeight = existing?.birthWeightLb ?? 7.0;
    double birthLength = existing?.birthLengthIn ?? 19.5;
    String? formError;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxHeight: 680),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  existing == null ? 'Add a baby' : 'Edit baby',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: Color(0xFFD3BBFE),
                            child: Icon(
                              Icons.child_care_rounded,
                              color: AppColors.primary,
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: nameController,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 14,
                            color: AppColors.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: "Baby's name",
                            hintStyle: GoogleFonts.nunitoSans(
                              fontSize: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Date of birth',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: sheetContext,
                              initialDate: dob,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365 * 6),
                              ),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setSheetState(() => dob = picked);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  MaterialLocalizations.of(
                                    sheetContext,
                                  ).formatMediumDate(dob),
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Gender',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: BabyGender.values
                              .map(
                                (g) => _chip(
                                  g.label,
                                  gender == g,
                                  () => setSheetState(() => gender = g),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        _stepperRow(
                          label: 'Birth weight',
                          value: '${birthWeight.toStringAsFixed(1)} lb',
                          onMinus: () => setSheetState(
                            () => birthWeight = (birthWeight - 0.1).clamp(
                              1.0,
                              20.0,
                            ),
                          ),
                          onPlus: () => setSheetState(
                            () => birthWeight = (birthWeight + 0.1).clamp(
                              1.0,
                              20.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _stepperRow(
                          label: 'Birth length',
                          value: '${birthLength.toStringAsFixed(1)} in',
                          onMinus: () => setSheetState(
                            () => birthLength = (birthLength - 0.1).clamp(
                              10.0,
                              26.0,
                            ),
                          ),
                          onPlus: () => setSheetState(
                            () => birthLength = (birthLength + 0.1).clamp(
                              10.0,
                              26.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (formError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    formError!,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade400,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            setSheetState(() {
                              formError = null;
                              saving = true;
                            });
                            try {
                              final draft = BabyProfile(
                                id: existing?.id ?? '',
                                name: nameController.text.trim(),
                                dateOfBirth: dob,
                                gender: gender,
                                birthWeightLb: birthWeight,
                                birthLengthIn: birthLength,
                              );
                              if (existing == null) {
                                await BabyProfileStore.addBaby(draft);
                              } else {
                                await BabyProfileStore.updateBaby(draft);
                              }
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            } catch (e) {
                              setSheetState(() {
                                saving = false;
                                formError = e is BabyProfileValidationError
                                    ? e.message
                                    : 'Could not save profile: $e';
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 0,
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save',
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => InkWell(
    borderRadius: BorderRadius.circular(999),
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? AppColors.primary
              : AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunitoSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: selected ? Colors.white : AppColors.onSurfaceVariant,
        ),
      ),
    ),
  );

  Widget _stepperRow({
    required String label,
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.nunitoSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ),
        _stepperButton(Icons.remove_rounded, onMinus),
        SizedBox(
          width: 66,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunitoSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        _stepperButton(Icons.add_rounded, onPlus),
      ],
    ),
  );

  Widget _stepperButton(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFD3BBFE),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: AppColors.primary),
    ),
  );
}
