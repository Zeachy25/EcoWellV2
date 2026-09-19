import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/green_space.dart';
import '../../providers/app_providers.dart';

enum MapLayerMode {
  topographic,
  satellite,
  calmHeatmap,
}

class ExploreMapScreen extends ConsumerStatefulWidget {
  const ExploreMapScreen({super.key});

  @override
  ConsumerState<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends ConsumerState<ExploreMapScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TransformationController _transformController = TransformationController();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  MapLayerMode _layerMode = MapLayerMode.topographic;
  String _selectedCategory = 'All';
  String _selectedDestress = 'All';
  double _maxDistance = 20.0;
  String? _selectedSpaceId;

  final List<String> _categories = const [
    'All',
    'Mangrove Park',
    'Mountain Sanctuary',
    'Beach',
    'City Park',
    'Viewpoint',
    'Waterfront',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _transformController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _recenterMap() {
    _transformController.value = Matrix4.identity();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Centered on your location in Mati City'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleLayerMode() {
    setState(() {
      _layerMode = switch (_layerMode) {
        MapLayerMode.topographic => MapLayerMode.satellite,
        MapLayerMode.satellite => MapLayerMode.calmHeatmap,
        MapLayerMode.calmHeatmap => MapLayerMode.topographic,
      };
    });

    final name = switch (_layerMode) {
      MapLayerMode.topographic => 'Topographic Night Map',
      MapLayerMode.satellite => 'Eco Satellite View',
      MapLayerMode.calmHeatmap => 'Quiet Score Heatmap',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to $name'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openFilterModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(Responsive.size(context, 20), Responsive.size(context, 16), Responsive.size(context, 20), Responsive.size(context, 24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: Responsive.size(context, 40),
                        height: Responsive.size(context, 4),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.size(context, 16)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Calm Spaces',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 18),
                            fontWeight: FontWeight.w800,
                            fontFamily: 'serif',
                            color: AppColors.forestDark,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedCategory = 'All';
                              _selectedDestress = 'All';
                              _maxDistance = 20.0;
                            });
                            setState(() {});
                          },
                          child: const Text('Reset', style: TextStyle(color: AppColors.forestMid)),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.size(context, 12)),
                    Text(
                      'Category',
                      style: TextStyle(fontSize: Responsive.fontSize(context, 13), fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: Responsive.size(context, 8)),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: AppColors.forestDark,
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(
                            fontSize: Responsive.fontSize(context, 12),
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => _selectedCategory = cat);
                              setState(() => _selectedCategory = cat);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: Responsive.size(context, 16)),
                    Text(
                      'Destress Level',
                      style: TextStyle(fontSize: Responsive.fontSize(context, 13), fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: Responsive.size(context, 8)),
                    Wrap(
                      spacing: 8,
                      children: ['All', 'High', 'Moderate'].map((destress) {
                        final isSelected = _selectedDestress == destress;
                        return ChoiceChip(
                          label: Text(destress == 'All' ? 'All Levels' : 'Destress: $destress'),
                          selected: isSelected,
                          selectedColor: AppColors.forestDark,
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(
                            fontSize: Responsive.fontSize(context, 12),
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => _selectedDestress = destress);
                              setState(() => _selectedDestress = destress);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: Responsive.size(context, 16)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Max Distance',
                          style: TextStyle(fontSize: Responsive.fontSize(context, 13), fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${_maxDistance.toInt()} km',
                          style: TextStyle(fontSize: Responsive.fontSize(context, 13), fontWeight: FontWeight.w700, color: AppColors.forestMid),
                        ),
                      ],
                    ),
                    Slider(
                      value: _maxDistance,
                      min: 1.0,
                      max: 25.0,
                      divisions: 24,
                      activeColor: AppColors.forestDark,
                      inactiveColor: AppColors.mintLight,
                      onChanged: (val) {
                        setModalState(() => _maxDistance = val);
                        setState(() => _maxDistance = val);
                      },
                    ),
                    SizedBox(height: Responsive.size(context, 16)),
                    SizedBox(
                      width: double.infinity,
                      height: Responsive.size(context, 48),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(context, 16))),
                        ),
                        child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openSeeAllModal(List<GreenSpace> spaces) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: EdgeInsets.fromLTRB(Responsive.size(context, 16), Responsive.size(context, 12), Responsive.size(context, 16), Responsive.size(context, 20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.size(context, 14)),
                  Text(
                    'All Calm & Green Spaces in Mati',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 18),
                      fontWeight: FontWeight.w800,
                      fontFamily: 'serif',
                      color: AppColors.forestDark,
                    ),
                  ),
                  SizedBox(height: Responsive.size(context, 4)),
                  Text(
                    '${spaces.length} natural restorative spaces available',
                    style: TextStyle(fontSize: Responsive.fontSize(context, 12), color: AppColors.textSecondary),
                  ),
                  SizedBox(height: Responsive.size(context, 14)),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: spaces.length,
                      separatorBuilder: (context, index) => SizedBox(height: Responsive.size(context, 12)),
                      itemBuilder: (context, index) {
                        final space = spaces[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            context.push('/green-space/${space.id}');
                          },
                          child: Container(
                            padding: EdgeInsets.all(Responsive.size(context, 12)),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(Responsive.radius(context, 16)),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(Responsive.radius(context, 12)),
                                  child: Image.asset(
                                    space.imageUrl ?? 'assets/images/home.png',
                                    width: Responsive.size(context, 72),
                                    height: Responsive.size(context, 72),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: Responsive.size(context, 72),
                                      height: Responsive.size(context, 72),
                                      color: AppColors.mintLight,
                                      child: const Icon(Icons.park, color: AppColors.forestMid),
                                    ),
                                  ),
                                ),
                                SizedBox(width: Responsive.size(context, 12)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        space.name,
                                        style: TextStyle(
                                          fontSize: Responsive.fontSize(context, 14),
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: Responsive.size(context, 2)),
                                      Text(
                                        '${space.category} • ${space.distanceKm ?? 1.2} km',
                                        style: TextStyle(fontSize: Responsive.fontSize(context, 11), color: AppColors.textSecondary),
                                      ),
                                      SizedBox(height: Responsive.size(context, 6)),
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: Responsive.size(context, 6), vertical: Responsive.size(context, 2)),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF132B20),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              space.destressTag ?? 'DESTRESS LEVEL: HIGH',
                                              style: TextStyle(fontSize: Responsive.fontSize(context, 8), fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ),
                                          const Spacer(),
                                          Icon(Icons.star, size: Responsive.size(context, 14), color: AppColors.goldStar),
                                          SizedBox(width: Responsive.size(context, 2)),
                                          Text(
                                            space.quietScore.toStringAsFixed(1),
                                            style: TextStyle(fontSize: Responsive.fontSize(context, 12), fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final spaces = ref.watch(greenSpacesProvider);
    final query = _searchController.text.trim().toLowerCase();

    final filteredSpaces = spaces.where((s) {
      if (query.isNotEmpty) {
        final matchesQuery = s.name.toLowerCase().contains(query) ||
            s.category.toLowerCase().contains(query) ||
            s.description.toLowerCase().contains(query) ||
            s.address.toLowerCase().contains(query);
        if (!matchesQuery) return false;
      }

      if (_selectedCategory != 'All') {
        if (!s.category.toLowerCase().contains(_selectedCategory.toLowerCase().split(' ').first)) {
          return false;
        }
      }

      if (_selectedDestress != 'All') {
        final tag = (s.destressTag ?? '').toUpperCase();
        if (_selectedDestress == 'High' && !tag.contains('HIGH')) return false;
        if (_selectedDestress == 'Moderate' && !tag.contains('MODERATE') && !tag.contains('BREEZE')) return false;
      }

      if ((s.distanceKm ?? 1.2) > _maxDistance) {
        return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A1927),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mapWidth = math.max(constraints.maxWidth, 360.0);
          final mapHeight = math.max(constraints.maxHeight, 640.0);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Interactive Full-bleed Topographical / Satellite Map Canvas
              Positioned.fill(
                child: InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 0.8,
                  maxScale: 3.5,
                  boundaryMargin: const EdgeInsets.all(120),
                  child: SizedBox(
                    width: mapWidth,
                    height: mapHeight,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          size: Size(mapWidth, mapHeight),
                          painter: _MatiTopographicMapPainter(
                            spaces: spaces,
                            layerMode: _layerMode,
                            pulseValue: _pulseAnimation.value,
                            selectedSpaceId: _selectedSpaceId,
                            onTapSpace: (spaceId) {
                              setState(() => _selectedSpaceId = spaceId);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // 2. Top Floating Search Capsule + Circular Filter Button
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(Responsive.size(context, 16), Responsive.size(context, 12), Responsive.size(context, 16), Responsive.size(context, 0)),
                    child: Row(
                      children: [
                        // White Search Bar Capsule
                        Expanded(
                          child: Container(
                            height: Responsive.size(context, 48),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(Responsive.radius(context, 24)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded, color: Color(0xFF8E9AA0), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                    decoration: const InputDecoration(
                                      hintText: 'Find a calm space...',
                                      hintStyle: TextStyle(
                                        color: Color(0xFF9EAAB3),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      fillColor: Colors.transparent,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                    child: const Icon(Icons.close_rounded, color: AppColors.textTertiary, size: 18),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(width: Responsive.size(context, 12)),

                        // Dark Forest Green Filter Button
                        GestureDetector(
                          onTap: _openFilterModal,
                          child: Container(
                            width: Responsive.size(context, 48),
                            height: Responsive.size(context, 48),
                            decoration: BoxDecoration(
                              color: const Color(0xFF163324),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Floating Action Buttons on Right (Layers & GPS Location)
              Positioned(
                right: 16,
                bottom: 275,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMapControlBtn(
                      icon: Icons.layers_outlined,
                      tooltip: 'Switch Map View',
                      onTap: _toggleLayerMode,
                    ),
                    SizedBox(height: Responsive.size(context, 12)),
                    _buildMapControlBtn(
                      icon: Icons.my_location_rounded,
                      tooltip: 'Center Location',
                      onTap: _recenterMap,
                    ),
                  ],
                ),
              ),

              // 4. Curved Bottom Sheet: "Recommended for You"
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(Responsive.size(context, 16), Responsive.size(context, 12), Responsive.size(context, 16), Responsive.size(context, 82)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.radius(context, 26))),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Center Rounded Drag Handle
                      Center(
                        child: Container(
                          width: Responsive.size(context, 38),
                          height: Responsive.size(context, 4.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B1B1B),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),

                      SizedBox(height: Responsive.size(context, 12)),

                      // Header Row: Serif Title + "See all"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'Recommended for You',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 18),
                                fontWeight: FontWeight.w800,
                                fontFamily: 'serif',
                                color: const Color(0xFF132B20),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _openSeeAllModal(spaces),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                              child: Text(
                                'See all',
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 13),
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: Responsive.size(context, 12)),

                      // Horizontal Place Cards Carousel
                      SizedBox(
                        height: Responsive.size(context, 185),
                        child: filteredSpaces.isEmpty
                            ? Center(
                                child: Text(
                                  'No spaces match "$query"',
                                  style: TextStyle(fontSize: Responsive.fontSize(context, 13), color: AppColors.textSecondary),
                                ),
                              )
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: filteredSpaces.length,
                                separatorBuilder: (context, index) => SizedBox(width: Responsive.size(context, 14)),
                                itemBuilder: (context, index) {
                                  final space = filteredSpaces[index];
                                  return _buildPlaceCard(context, space);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapControlBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: Responsive.size(context, 44),
          height: Responsive.size(context, 44),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF163324), size: Responsive.size(context, 22)),
        ),
      ),
    );
  }

  Widget _buildPlaceCard(BuildContext context, GreenSpace space) {
    final isSelected = _selectedSpaceId == space.id;
    final isBreeze = (space.destressTag ?? '').toUpperCase().contains('BREEZE');
    final tagColor = isBreeze ? const Color(0xFF422616).withValues(alpha: 0.9) : const Color(0xFF132B20).withValues(alpha: 0.88);

    return GestureDetector(
      onTap: () {
        setState(() => _selectedSpaceId = space.id);
        context.push('/green-space/${space.id}');
      },
      child: Container(
        width: Responsive.size(context, 220),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Responsive.radius(context, 18)),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFE8ECE9),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image with Rating and Destress Tag
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.radius(context, 17))),
                  child: SizedBox(
                    height: Responsive.size(context, 98),
                    width: double.infinity,
                    child: Image.asset(
                      space.imageUrl ?? 'assets/images/home.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFDCEFE3),
                        child: const Center(
                          child: Icon(Icons.nature, color: Color(0xFF2E7D32), size: 36),
                        ),
                      ),
                    ),
                  ),
                ),

                // Star Rating Pill (Top-Right)
                Positioned(
                  top: Responsive.size(context, 8),
                  right: Responsive.size(context, 8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: Responsive.size(context, 7), vertical: Responsive.size(context, 3)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Responsive.radius(context, 12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: AppColors.goldStar, size: Responsive.size(context, 14)),
                        SizedBox(width: Responsive.size(context, 2)),
                        Text(
                          space.quietScore.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 11),
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF222222),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Destress Level Pill (Bottom-Left over image)
                Positioned(
                  left: Responsive.size(context, 8),
                  bottom: Responsive.size(context, 8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: Responsive.size(context, 8), vertical: Responsive.size(context, 3.5)),
                    decoration: BoxDecoration(
                      color: tagColor,
                      borderRadius: BorderRadius.circular(Responsive.radius(context, 6)),
                    ),
                    child: Text(
                      space.destressTag ?? 'DESTRESS LEVEL: HIGH',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 8.5),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Card Body
            Padding(
              padding: EdgeInsets.fromLTRB(Responsive.size(context, 10), Responsive.size(context, 8), Responsive.size(context, 10), Responsive.size(context, 8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    space.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 13),
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF132B20),
                    ),
                  ),
                  SizedBox(height: Responsive.size(context, 3)),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: Responsive.size(context, 12), color: const Color(0xFF2E7D32)),
                      SizedBox(width: Responsive.size(context, 3)),
                      Expanded(
                        child: Text(
                          '${space.distanceKm ?? 1.2} km • ${space.category}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 10.5),
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.size(context, 6)),
                  // Tag chips preview
                  if (space.tags.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Row(
                        children: space.tags.take(2).map((tag) {
                          return Container(
                            margin: EdgeInsets.only(right: Responsive.size(context, 4)),
                            padding: EdgeInsets.symmetric(horizontal: Responsive.size(context, 6), vertical: Responsive.size(context, 2)),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F5F2),
                              borderRadius: BorderRadius.circular(Responsive.radius(context, 10)),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 9),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
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

class _MatiTopographicMapPainter extends CustomPainter {
  final List<GreenSpace> spaces;
  final MapLayerMode layerMode;
  final double pulseValue;
  final String? selectedSpaceId;
  final void Function(String) onTapSpace;

  _MatiTopographicMapPainter({
    required this.spaces,
    required this.layerMode,
    required this.pulseValue,
    required this.selectedSpaceId,
    required this.onTapSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 1. Base Dark Background
    final oceanColor = switch (layerMode) {
      MapLayerMode.topographic => const Color(0xFF071421),
      MapLayerMode.satellite => const Color(0xFF05101A),
      MapLayerMode.calmHeatmap => const Color(0xFF040F18),
    };
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = oceanColor);

    // 2. Coastal Land Mass Terrain (Mati Bay Geography)
    final landColor = switch (layerMode) {
      MapLayerMode.topographic => const Color(0xFF0E2233),
      MapLayerMode.satellite => const Color(0xFF132729),
      MapLayerMode.calmHeatmap => const Color(0xFF0B1F2D),
    };

    final landPath = Path()
      ..moveTo(0, height * 0.52)
      ..cubicTo(width * 0.25, height * 0.50, width * 0.45, height * 0.45, width * 0.58, height * 0.38)
      ..cubicTo(width * 0.72, height * 0.32, width * 0.85, height * 0.28, width, height * 0.20)
      ..lineTo(width, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(landPath, Paint()..color = landColor);

    // 3. Topographical Elevation Contour Lines (100m, 300m, 500m)
    final contourPaint = Paint()
      ..color = const Color(0xFF1F3D5C).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final contour1 = Path()
      ..moveTo(0, height * 0.38)
      ..cubicTo(width * 0.3, height * 0.35, width * 0.5, height * 0.22, width, height * 0.12);
    canvas.drawPath(contour1, contourPaint);

    final contour2 = Path()
      ..moveTo(width * 0.1, height * 0.28)
      ..cubicTo(width * 0.4, height * 0.24, width * 0.65, height * 0.16, width, height * 0.08);
    canvas.drawPath(contour2, contourPaint);

    final contour3 = Path()
      ..moveTo(width * 0.35, height * 0.18)
      ..cubicTo(width * 0.55, height * 0.12, width * 0.75, height * 0.08, width, height * 0.04);
    canvas.drawPath(contour3, contourPaint);

    // Elevation text labels ("100m", "500m")
    _drawElevationLabel(canvas, '100m', Offset(width * 0.58, height * 0.18));
    _drawElevationLabel(canvas, '500m', Offset(width * 0.54, height * 0.23));

    // 4. Blue Water Stream & River Ribbons
    final riverPaint = Paint()
      ..color = const Color(0xFF2E63B8).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final river1 = Path()
      ..moveTo(width * 0.45, 0)
      ..cubicTo(width * 0.42, height * 0.12, width * 0.46, height * 0.22, width * 0.48, height * 0.30);
    canvas.drawPath(river1, riverPaint);

    final river2 = Path()
      ..moveTo(width * 0.72, 0)
      ..cubicTo(width * 0.68, height * 0.10, width * 0.58, height * 0.20, width * 0.51, height * 0.32);
    canvas.drawPath(river2, riverPaint);

    // 5. Blue Arterial Road Network Lines
    final mainRoadPaint = Paint()
      ..color = const Color(0xFF3880E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;

    final secondaryRoadPaint = Paint()
      ..color = const Color(0xFF265EA6).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Main Highway & Mati Diversion Road
    final mainHighway = Path()
      ..moveTo(0, height * 0.48)
      ..lineTo(width * 0.24, height * 0.42)
      ..lineTo(width * 0.46, height * 0.36)
      ..cubicTo(width * 0.52, height * 0.44, width * 0.58, height * 0.52, width * 0.65, height * 0.58)
      ..lineTo(width * 0.78, height * 0.60)
      ..lineTo(width, height * 0.58);
    canvas.drawPath(mainHighway, mainRoadPaint);

    // Secondary city network roads
    final branch1 = Path()
      ..moveTo(width * 0.24, height * 0.42)
      ..lineTo(width * 0.38, height * 0.32)
      ..lineTo(width * 0.46, height * 0.36);
    canvas.drawPath(branch1, secondaryRoadPaint);

    final branch2 = Path()
      ..moveTo(width * 0.46, height * 0.36)
      ..lineTo(width * 0.50, height * 0.26)
      ..lineTo(width * 0.58, height * 0.20);
    canvas.drawPath(branch2, secondaryRoadPaint);

    final branch3 = Path()
      ..moveTo(width * 0.12, height * 0.52)
      ..lineTo(width * 0.28, height * 0.56)
      ..lineTo(width * 0.36, height * 0.50);
    canvas.drawPath(branch3, secondaryRoadPaint);

    // 6. Road Names & Street Labels
    _drawStreetLabel(canvas, 'LIPAWAN 2', Offset(width * 0.26, height * 0.39), -0.2);
    _drawStreetLabel(canvas, 'SAINZ', Offset(width * 0.38, height * 0.44), 0.0);
    _drawStreetLabel(canvas, 'Mati Diversion Road', Offset(width * 0.54, height * 0.46), 0.75);
    _drawStreetLabel(canvas, 'Tu-tuo', Offset(width * 0.80, height * 0.43), 0.0);
    _drawStreetLabel(canvas, 'CENTRAL', Offset(width * 0.12, height * 0.44), -0.3);

    // 7. Green Nature Zones (Pastel Sage Polygon Patches)
    final greenZonePaint = Paint()
      ..color = const Color(0xFFA6D69D).withValues(alpha: layerMode == MapLayerMode.satellite ? 0.85 : 0.70)
      ..style = PaintingStyle.fill;

    // Guang-guang Mangrove polygon (Center-Left)
    final mangroveZone = Path()
      ..moveTo(width * 0.32, height * 0.36)
      ..cubicTo(width * 0.28, height * 0.34, width * 0.32, height * 0.30, width * 0.37, height * 0.31)
      ..cubicTo(width * 0.41, height * 0.32, width * 0.40, height * 0.38, width * 0.36, height * 0.38)
      ..close();
    canvas.drawPath(mangroveZone, greenZonePaint);

    // Forest / Park polygon 1 (Center-Top)
    final parkZone1 = Path()
      ..moveTo(width * 0.48, height * 0.28)
      ..cubicTo(width * 0.44, height * 0.25, width * 0.48, height * 0.20, width * 0.54, height * 0.21)
      ..cubicTo(width * 0.56, height * 0.25, width * 0.53, height * 0.30, width * 0.49, height * 0.30)
      ..close();
    canvas.drawPath(parkZone1, greenZonePaint);

    // Mountain Sanctuary polygon 2 (Center-Right)
    final sanctuaryZone = Path()
      ..moveTo(width * 0.60, height * 0.28)
      ..cubicTo(width * 0.56, height * 0.24, width * 0.64, height * 0.20, width * 0.69, height * 0.24)
      ..cubicTo(width * 0.71, height * 0.29, width * 0.66, height * 0.32, width * 0.60, height * 0.30)
      ..close();
    canvas.drawPath(sanctuaryZone, greenZonePaint);

    // 8. Calm Heatmap Mode Overlay
    if (layerMode == MapLayerMode.calmHeatmap) {
      final heatmapGlow = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF38B289).withValues(alpha: 0.45),
            const Color(0xFF48CAE4).withValues(alpha: 0.20),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(width * 0.35, height * 0.34), radius: 80));
      canvas.drawCircle(Offset(width * 0.35, height * 0.34), 80, heatmapGlow);
    }

    // 9. Bold "MATI" City Center Title
    const matiText = TextSpan(
      text: 'MATI',
      style: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.5,
        shadows: [
          Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
    );
    final matiPainter = TextPainter(text: matiText, textDirection: TextDirection.ltr)..layout();
    matiPainter.paint(canvas, Offset(width * 0.28, height * 0.47));

    // 10. Landmark Red Pin ("MENZI" / Baywalk)
    final menziPinLoc = Offset(width * 0.62, height * 0.55);
    final menziPulse = Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.3);
    final menziDot = Paint()..color = const Color(0xFFEF4444);
    canvas.drawCircle(menziPinLoc, 9, menziPulse);
    canvas.drawCircle(menziPinLoc, 4.5, menziDot);
    _drawStreetLabel(canvas, 'MENZI', Offset(width * 0.55, height * 0.54), 0.0);

    // 11. Glowing User Location Pulse Indicator (Bright Cyan / Blue)
    final userLoc = Offset(width * 0.485, height * 0.33);

    // Outer Animated Translucent Ripple
    final rippleRadius = 10.0 + (pulseValue * 18.0);
    final rippleOpacity = (1.0 - pulseValue).clamp(0.0, 0.7);
    final ripplePaint = Paint()
      ..color = const Color(0xFF38B6FF).withValues(alpha: rippleOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(userLoc, rippleRadius, ripplePaint);

    // Cyan Glow Ring
    final userRing = Paint()
      ..color = const Color(0xFF38B6FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(userLoc, 9, userRing);

    // Cyan Base Dot
    final userDot = Paint()..color = const Color(0xFF38B6FF);
    canvas.drawCircle(userLoc, 7, userDot);

    // White Center Core
    final userCore = Paint()..color = Colors.white;
    canvas.drawCircle(userLoc, 3.5, userCore);
  }

  void _drawElevationLabel(Canvas canvas, String text, Offset offset) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: const Color(0xFF6B8BA4).withValues(alpha: 0.7),
        fontSize: 8.5,
        fontWeight: FontWeight.w600,
      ),
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, offset);
  }

  void _drawStreetLabel(Canvas canvas, String text, Offset offset, double angle) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    if (angle != 0.0) canvas.rotate(angle);

    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.8),
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        shadows: const [
          Shadow(color: Colors.black87, blurRadius: 4),
        ],
      ),
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MatiTopographicMapPainter oldDelegate) {
    return oldDelegate.layerMode != layerMode ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.selectedSpaceId != selectedSpaceId ||
        oldDelegate.spaces != spaces;
  }
}
