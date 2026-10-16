import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/screen_background.dart';

/// Backs the hospital-bag checklist with the `hospital_bag_progress`
/// Supabase table — items themselves stay hardcoded below; only which
/// ones are checked off is persisted.
class _HospitalBagStore {
  _HospitalBagStore._();

  static const String _table = 'hospital_bag_progress';
  static SupabaseClient get _db => SupabaseConfig.client;

  static Future<Set<String>> fetchPacked() async {
    final rows = await _db.from(_table).select('item_key');
    return rows.map((r) => r['item_key'] as String).toSet();
  }

  static Future<void> setPacked(String itemKey, bool packed) async {
    if (packed) {
      await _db.from(_table).upsert({'item_key': itemKey, 'packed': true});
    } else {
      await _db.from(_table).delete().eq('item_key', itemKey);
    }
  }
}

class _ChecklistCategory {
  const _ChecklistCategory(this.title, this.icon, this.items);

  final String title;
  final IconData icon;
  final List<String> items;
}

class HospitalBagScreen extends StatefulWidget {
  const HospitalBagScreen({super.key});

  @override
  State<HospitalBagScreen> createState() => _HospitalBagScreenState();
}

class _HospitalBagScreenState extends State<HospitalBagScreen> {
  static const _categories = [
    _ChecklistCategory('For Mom', Icons.person_outline, [
      'Comfortable going-home outfit',
      'Toiletries bag',
      'Phone charger (long cord)',
      'Nursing bra and pads',
      'Slippers and cozy socks',
      'Insurance card and ID',
      'Snacks',
    ]),
    _ChecklistCategory('For Baby', Icons.child_care_outlined, [
      'Going-home outfit (season-appropriate)',
      'Swaddle blankets (2–3)',
      'Car seat, installed',
      'Diapers and wipes',
      'Hat and mittens',
    ]),
    _ChecklistCategory('For Your Support Person', Icons.favorite_outline, [
      'Change of clothes',
      'Snacks and drinks',
      'Entertainment (book, charger)',
      'Camera or phone for photos',
    ]),
    _ChecklistCategory('Documents', Icons.description_outlined, [
      'Birth plan copy',
      'Insurance information',
      'Hospital pre-registration forms',
      "Pediatrician's contact info",
    ]),
  ];

  Set<String> _packed = {};
  bool _loading = true;

  int get _totalItems => _categories.fold(0, (sum, c) => sum + c.items.length);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final packed = await _HospitalBagStore.fetchPacked();
      if (!mounted) return;
      setState(() {
        _packed = packed;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Could not load your checklist: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  Future<void> _toggleItem(String key) async {
    final wasPacked = _packed.contains(key);
    setState(() => wasPacked ? _packed.remove(key) : _packed.add(key));
    try {
      await _HospitalBagStore.setPacked(key, !wasPacked);
    } catch (e) {
      setState(() => wasPacked ? _packed.add(key) : _packed.remove(key));
      _showError('Could not save: $e');
    }
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
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _progressCard(),
                                const SizedBox(height: 24),
                                ..._categories.map(
                                  (category) => Padding(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: _categoryCard(category),
                                  ),
                                ),
                              ],
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
                'Hospital bag',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Aim to have it packed by week 35–36.',
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

  Widget _progressCard() {
    final total = _totalItems;
    final packed = _packed.length;
    final progress = total == 0 ? 0.0 : packed / total;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Packed so far',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$packed of $total items',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(_ChecklistCategory category) {
    final packedInCategory = category.items
        .where((item) => _packed.contains('${category.title}·$item'))
        .length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD3BBFE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    color: AppColors.primary,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.title,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  '$packedInCategory/${category.items.length}',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ...category.items.map((item) {
            final key = '${category.title}·$item';
            final checked = _packed.contains(key);
            return InkWell(
              onTap: () => _toggleItem(key),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: checked
                            ? AppColors.secondary
                            : Colors.transparent,
                        border: Border.all(
                          color: checked
                              ? AppColors.secondary
                              : AppColors.outlineVariant,
                          width: 2,
                        ),
                      ),
                      child: checked
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: checked
                              ? AppColors.onSurfaceVariant
                              : AppColors.onSurface,
                          decoration: checked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
