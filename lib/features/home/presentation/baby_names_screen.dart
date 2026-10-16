import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/screen_background.dart';

enum _NameGender { boy, girl, unisex }

class _BabyName {
  const _BabyName(this.name, this.gender, this.origin, this.meaning, {this.id});

  final String? id;
  final String name;
  final _NameGender gender;
  final String origin;
  final String meaning;
}

class BabyNamesScreen extends StatefulWidget {
  const BabyNamesScreen({super.key});

  @override
  State<BabyNamesScreen> createState() => _BabyNamesScreenState();
}

class _BabyNamesScreenState extends State<BabyNamesScreen> {
  static const _names = [
    _BabyName('Amara', _NameGender.girl, 'Igbo', 'Grace, mercy'),
    _BabyName('Elias', _NameGender.boy, 'Hebrew', 'The Lord is my God'),
    _BabyName('Luna', _NameGender.girl, 'Latin', 'Moon'),
    _BabyName('Kai', _NameGender.unisex, 'Hawaiian', 'Sea'),
    _BabyName('Sofia', _NameGender.girl, 'Greek', 'Wisdom'),
    _BabyName('Mateo', _NameGender.boy, 'Spanish', "Gift of God"),
    _BabyName('Nova', _NameGender.girl, 'Latin', 'New, star'),
    _BabyName('Ezra', _NameGender.boy, 'Hebrew', 'Help'),
    _BabyName('Aria', _NameGender.girl, 'Italian', 'Air, melody'),
    _BabyName('Milo', _NameGender.boy, 'German', 'Soldier, merciful'),
    _BabyName('Rowan', _NameGender.unisex, 'Gaelic', 'Little redhead'),
    _BabyName('Zoe', _NameGender.girl, 'Greek', 'Life'),
    _BabyName('Leo', _NameGender.boy, 'Latin', 'Lion'),
    _BabyName('Ivy', _NameGender.girl, 'English', 'Faithfulness'),
    _BabyName('Jasper', _NameGender.boy, 'Persian', 'Bringer of treasure'),
    _BabyName('Emory', _NameGender.unisex, 'German', 'Industrious leader'),
    _BabyName('Willow', _NameGender.girl, 'English', 'Grace, elegance'),
    _BabyName('Theo', _NameGender.boy, 'Greek', 'Divine gift'),
    _BabyName('Maya', _NameGender.girl, 'Sanskrit', 'Illusion, dream'),
    _BabyName('Atlas', _NameGender.boy, 'Greek', 'Enduring, strong'),
  ];

  String _query = '';
  _NameGender? _filter;
  final Set<String> _favorites = {};
  List<_BabyName> _customNames = [];
  bool _favoritesOnly = false;

  List<_BabyName> get _filtered => [..._customNames, ..._names].where((n) {
    if (_favoritesOnly && !_favorites.contains(n.name)) return false;
    if (_filter != null && n.gender != _filter) return false;
    if (_query.isNotEmpty &&
        !n.name.toLowerCase().contains(_query.toLowerCase())) {
      return false;
    }
    return true;
  }).toList();

  String _genderLabel(_NameGender g) => switch (g) {
    _NameGender.boy => 'Boy',
    _NameGender.girl => 'Girl',
    _NameGender.unisex => 'Unisex',
  };

  Color _genderColor(_NameGender g) => switch (g) {
    _NameGender.boy => AppColors.secondary,
    _NameGender.girl => AppColors.primary,
    _NameGender.unisex => AppColors.lavenderLight,
  };

  @override
  void initState() {
    super.initState();
    _loadCustomNames();
  }

  Future<void> _loadCustomNames() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final rows = await SupabaseConfig.client
          .from('baby_name_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _customNames = rows
            .map(
              (row) => _BabyName(
                row['name'] as String,
                _NameGender.values.byName(row['gender'] as String),
                (row['origin'] as String?) ?? 'Personal list',
                (row['meaning'] as String?) ?? '',
                id: row['id'] as String,
              ),
            )
            .toList();
      });
    } catch (_) {
      // The standard name library remains available if the optional saved-name
      // table has not been installed yet.
    }
  }

  Future<void> _showAddName() async {
    final name = TextEditingController();
    final origin = TextEditingController();
    final meaning = TextEditingController();
    var gender = _NameGender.unisex;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add a baby name'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: origin,
                  decoration: const InputDecoration(
                    labelText: 'Origin (optional)',
                  ),
                ),
                TextField(
                  controller: meaning,
                  decoration: const InputDecoration(
                    labelText: 'Meaning (optional)',
                  ),
                ),
                DropdownButton<_NameGender>(
                  value: gender,
                  isExpanded: true,
                  items: _NameGender.values
                      .map(
                        (g) => DropdownMenuItem(
                          value: g,
                          child: Text(_genderLabel(g)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => gender = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final value = name.text.trim();
                final userId = SupabaseConfig.client.auth.currentUser?.id;
                if (value.isEmpty || userId == null) return;
                await SupabaseConfig.client.from('baby_name_entries').upsert({
                  'user_id': userId,
                  'name': value,
                  'gender': gender.name,
                  'origin': origin.text.trim(),
                  'meaning': meaning.text.trim(),
                }, onConflict: 'user_id,name');
                if (context.mounted) Navigator.pop(context);
                await _loadCustomNames();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    origin.dispose();
    meaning.dispose();
  }

  Future<void> _deleteName(_BabyName name) async {
    if (name.id == null) return;
    try {
      await SupabaseConfig.client
          .from('baby_name_entries')
          .delete()
          .eq('id', name.id!);
      _favorites.remove(name.name);
      await _loadCustomNames();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not delete name: $e')));
      }
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
                  child: Column(
                    children: [
                      _header(context),
                      const SizedBox(height: 14),
                      _searchBar(),
                      const SizedBox(height: 12),
                      _filterRow(),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _filtered.isEmpty
                    ? _emptyState()
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                _nameCard(_filtered[index]),
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
                'Baby names',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '${_favorites.length} favorited',
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _showAddName,
          tooltip: 'Add a baby name',
          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _favoritesOnly = !_favoritesOnly),
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _favoritesOnly
                  ? AppColors.secondary
                  : Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _favoritesOnly
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _favoritesOnly ? Colors.white : AppColors.primary,
              size: 20,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _searchBar() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.25),
      ),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.search_rounded,
          color: AppColors.onSurfaceVariant,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              color: AppColors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Search names…',
              hintStyle: GoogleFonts.nunitoSans(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _filterRow() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
    child: Row(
      children: [
        _filterChip(
          'All',
          _filter == null,
          () => setState(() => _filter = null),
        ),
        const SizedBox(width: 8),
        _filterChip(
          'Boy',
          _filter == _NameGender.boy,
          () => setState(() => _filter = _NameGender.boy),
        ),
        const SizedBox(width: 8),
        _filterChip(
          'Girl',
          _filter == _NameGender.girl,
          () => setState(() => _filter = _NameGender.girl),
        ),
        const SizedBox(width: 8),
        _filterChip(
          'Unisex',
          _filter == _NameGender.unisex,
          () => setState(() => _filter = _NameGender.unisex),
        ),
      ],
    ),
  );

  Widget _filterChip(String label, bool selected, VoidCallback onTap) =>
      InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.outlineVariant.withValues(alpha: 0.3),
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

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 40,
            color: AppColors.lavenderLight,
          ),
          const SizedBox(height: 12),
          Text(
            'No names match your filters.',
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _nameCard(_BabyName n) {
    final favorited = _favorites.contains(n.name);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
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
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _genderColor(n.gender).withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Text(
              n.name[0],
              style: GoogleFonts.nunitoSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _genderColor(n.gender),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      n.name,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _genderColor(n.gender).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _genderLabel(n.gender),
                        style: GoogleFonts.nunitoSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: _genderColor(n.gender),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${n.origin} · ${n.meaning}',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(
              () => favorited
                  ? _favorites.remove(n.name)
                  : _favorites.add(n.name),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                favorited
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: favorited
                    ? AppColors.secondary
                    : AppColors.onSurfaceVariant,
                size: 22,
              ),
            ),
          ),
          if (n.id != null)
            IconButton(
              onPressed: () => _deleteName(n),
              tooltip: 'Delete saved name',
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
