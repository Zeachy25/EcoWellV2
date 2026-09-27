import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/geo.dart';
import '../../core/utils/responsive.dart';
import '../../models/geo_fence.dart';
import '../../models/green_space.dart';
import '../../providers/app_providers.dart';
import '../../providers/geofence_provider.dart';
import '../shared/fence_overlay.dart';
import '../shared/geofence_status_chip.dart';

enum MapLayerMode { topographic, satellite, calmHeatmap }

/// Returns [spaces] sorted by live distance (nearest first) using
/// [distanceMetersOf]. Places with no distance yet (null, e.g. before the
/// first GPS fix) sort last so they never jump ahead of known distances.
/// The input list is not modified.
List<GreenSpace> sortSpacesByDistance(
  List<GreenSpace> spaces,
  double? Function(GreenSpace) distanceMetersOf,
) {
  final sorted = [...spaces];
  sorted.sort((a, b) {
    final da = distanceMetersOf(a);
    final db = distanceMetersOf(b);
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  });
  return sorted;
}

class ExploreMapScreen extends ConsumerStatefulWidget {
  const ExploreMapScreen({super.key});

  @override
  ConsumerState<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends ConsumerState<ExploreMapScreen> {
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;

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

  MapType get _mapType => switch (_layerMode) {
    MapLayerMode.topographic => MapType.normal,
    MapLayerMode.satellite => MapType.satellite,
    MapLayerMode.calmHeatmap => MapType.hybrid,
  };

  @override
  void dispose() {
    _searchController.dispose();
    _mapController = null;
    super.dispose();
  }

  void _recenterMap() {
    final pos = ref.read(geofenceProvider).position;
    if (pos != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 16),
        ),
      );
    } else {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(
            target: LatLng(
              AppConfig.defaultLatitude,
              AppConfig.defaultLongitude,
            ),
            zoom: 11,
          ),
        ),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Centered on your location'),
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
      MapLayerMode.topographic => 'Standard Topographic Map',
      MapLayerMode.satellite => 'Eco Satellite View',
      MapLayerMode.calmHeatmap => 'Hybrid Geofence View',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to $name'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Geofence circle for every (filtered) green space using a circular fence.
  /// The circle you are currently inside gets highlighted in cyan.
  Set<Circle> _buildCircles(List<GreenSpace> spaces, GreenSpace? insideSpace) {
    return spaces.where((space) => space.fence is CircleFence).map((space) {
      final isInside = space.id == insideSpace?.id;
      final isSelected = space.id == _selectedSpaceId;
      return FenceOverlay.circleFor(
        space,
        id: 'geofence-${space.id}',
        fillColor: isInside
            ? const Color(0x6648CAE4)
            : const Color(0x3390EEB0),
        strokeColor: isInside
            ? const Color(0xFF48CAE4)
            : isSelected
            ? const Color(0xFF1B7A3D)
            : const Color(0xFF2E7D32),
        strokeWidth: isInside ? 3 : 2,
        consumeTapEvents: true,
        onTap: () => setState(() => _selectedSpaceId = space.id),
      )!;
    }).toSet();
  }

  /// Geofence polygon for every (filtered) green space using a polygon fence
  /// (e.g. a trapezoid tracing an exact boundary). Same highlight rules as the
  /// circles above.
  Set<Polygon> _buildPolygons(
    List<GreenSpace> spaces,
    GreenSpace? insideSpace,
  ) {
    return spaces.where((space) => space.fence is PolygonFence).map((space) {
      final isInside = space.id == insideSpace?.id;
      final isSelected = space.id == _selectedSpaceId;
      return FenceOverlay.polygonFor(
        space,
        id: 'geofence-${space.id}',
        fillColor: isInside
            ? const Color(0x6648CAE4)
            : const Color(0x3390EEB0),
        strokeColor: isInside
            ? const Color(0xFF48CAE4)
            : isSelected
            ? const Color(0xFF1B7A3D)
            : const Color(0xFF2E7D32),
        strokeWidth: isInside ? 3 : 2,
        consumeTapEvents: true,
        onTap: () => setState(() => _selectedSpaceId = space.id),
      )!;
    }).toSet();
  }

  /// Green pin per geofenced place. The place you are inside is orange.
  Set<Marker> _buildMarkers(List<GreenSpace> spaces, GreenSpace? insideSpace) {
    return spaces.map((space) {
      final isInside = space.id == insideSpace?.id;
      return Marker(
        markerId: MarkerId('space-${space.id}'),
        position: LatLng(space.latitude, space.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isInside ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueGreen,
        ),
        infoWindow: InfoWindow(
          title: space.name,
          snippet: 'Geofence ${space.fenceLabel}',
        ),
        onTap: () => setState(() => _selectedSpaceId = space.id),
      );
    }).toSet();
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
                padding: EdgeInsets.fromLTRB(
                  Responsive.size(context, 20),
                  Responsive.size(context, 16),
                  Responsive.size(context, 20),
                  Responsive.size(context, 24),
                ),
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
                          child: const Text(
                            'Reset',
                            style: TextStyle(color: AppColors.forestMid),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.size(context, 12)),
                    Text(
                      'Category',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 13),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
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
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
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
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 13),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: Responsive.size(context, 8)),
                    Wrap(
                      spacing: 8,
                      children: ['All', 'High', 'Moderate'].map((destress) {
                        final isSelected = _selectedDestress == destress;
                        return ChoiceChip(
                          label: Text(
                            destress == 'All'
                                ? 'All Levels'
                                : 'Destress: $destress',
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.forestDark,
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(
                            fontSize: Responsive.fontSize(context, 12),
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
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
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 13),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${_maxDistance.toInt()} km',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 13),
                            fontWeight: FontWeight.w700,
                            color: AppColors.forestMid,
                          ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Responsive.radius(context, 16),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
    final sorted = sortSpacesByDistance(spaces, _distanceMetersTo);
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
              padding: EdgeInsets.fromLTRB(
                Responsive.size(context, 16),
                Responsive.size(context, 12),
                Responsive.size(context, 16),
                Responsive.size(context, 20),
              ),
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
                    '${sorted.length} natural restorative spaces available',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: Responsive.size(context, 14)),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: sorted.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: Responsive.size(context, 12)),
                      itemBuilder: (context, index) {
                        final space = sorted[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            context.push('/green-space/${space.id}');
                          },
                          child: Container(
                            padding: EdgeInsets.all(
                              Responsive.size(context, 12),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                Responsive.radius(context, 16),
                              ),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    Responsive.radius(context, 12),
                                  ),
                                  child: Image.asset(
                                    space.imageUrl ?? 'assets/images/home.png',
                                    width: Responsive.size(context, 72),
                                    height: Responsive.size(context, 72),
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (
                                          context,
                                          error,
                                          stackTrace,
                                        ) => Container(
                                          width: Responsive.size(context, 72),
                                          height: Responsive.size(context, 72),
                                          color: AppColors.mintLight,
                                          child: const Icon(
                                            Icons.park,
                                            color: AppColors.forestMid,
                                          ),
                                        ),
                                  ),
                                ),
                                SizedBox(width: Responsive.size(context, 12)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        space.name,
                                        style: TextStyle(
                                          fontSize: Responsive.fontSize(
                                            context,
                                            14,
                                          ),
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(
                                        height: Responsive.size(context, 2),
                                      ),
                                      Text(
                                        '${space.category} • ${_distanceText(space)}',
                                        style: TextStyle(
                                          fontSize: Responsive.fontSize(
                                            context,
                                            11,
                                          ),
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      SizedBox(
                                        height: Responsive.size(context, 6),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: Responsive.size(
                                                context,
                                                6,
                                              ),
                                              vertical: Responsive.size(
                                                context,
                                                2,
                                              ),
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF132B20),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              space.destressTag ??
                                                  'DESTRESS LEVEL: HIGH',
                                              style: TextStyle(
                                                fontSize: Responsive.fontSize(
                                                  context,
                                                  8,
                                                ),
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Icon(
                                            Icons.star,
                                            size: Responsive.size(context, 14),
                                            color: AppColors.goldStar,
                                          ),
                                          SizedBox(
                                            width: Responsive.size(context, 2),
                                          ),
                                          Text(
                                            space.quietScore.toStringAsFixed(1),
                                            style: TextStyle(
                                              fontSize: Responsive.fontSize(
                                                context,
                                                12,
                                              ),
                                              fontWeight: FontWeight.bold,
                                            ),
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
    final geofence = ref.watch(geofenceProvider);
    final query = _searchController.text.trim().toLowerCase();

    final filteredSpaces = sortSpacesByDistance(spaces.where((s) {
      if (query.isNotEmpty) {
        final matchesQuery =
            s.name.toLowerCase().contains(query) ||
            s.category.toLowerCase().contains(query) ||
            s.description.toLowerCase().contains(query) ||
            s.address.toLowerCase().contains(query);
        if (!matchesQuery) return false;
      }

      if (_selectedCategory != 'All') {
        if (!s.category.toLowerCase().contains(
          _selectedCategory.toLowerCase().split(' ').first,
        )) {
          return false;
        }
      }

      if (_selectedDestress != 'All') {
        final tag = (s.destressTag ?? '').toUpperCase();
        if (_selectedDestress == 'High' && !tag.contains('HIGH')) return false;
        if (_selectedDestress == 'Moderate' &&
            !tag.contains('MODERATE') &&
            !tag.contains('BREEZE')) {
          return false;
        }
      }

      if (_distanceMetersTo(s) case final double meters
          when meters / 1000 > _maxDistance) {
        return false;
      }

      return true;
    }).toList(), _distanceMetersTo);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1927),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Real Google Map with developer-defined geofence shapes
          Positioned.fill(
            child: GoogleMap(
              mapType: _mapType,
              initialCameraPosition: const CameraPosition(
                target: LatLng(
                  AppConfig.defaultLatitude,
                  AppConfig.defaultLongitude,
                ),
                zoom: 11,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: _buildMarkers(filteredSpaces, geofence.insideSpace),
              circles: _buildCircles(filteredSpaces, geofence.insideSpace),
              polygons: _buildPolygons(filteredSpaces, geofence.insideSpace),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),

          // 2. Top Floating Search Capsule + Circular Filter Button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  Responsive.size(context, 16),
                  Responsive.size(context, 12),
                  Responsive.size(context, 16),
                  Responsive.size(context, 0),
                ),
                child: Row(
                  children: [
                    // White Search Bar Capsule
                    Expanded(
                      child: Container(
                        height: Responsive.size(context, 48),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            Responsive.radius(context, 24),
                          ),
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
                            const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF8E9AA0),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
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
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: AppColors.textTertiary,
                                  size: 18,
                                ),
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
                          child: Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2b. Live geofence status chip (tap to simulate enter/exit)
          Positioned(
            top: Responsive.size(context, 76),
            left: Responsive.size(context, 16),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  top: Responsive.size(context, 5),
                ),
                child: const GeofenceStatusChip(),
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
                  icon: Icons.route_rounded,
                  tooltip: _selectedSpaceId == null
                      ? 'Select a green pin to get the route'
                      : 'Get route to selected pin',
                  onTap: _selectedSpaceId == null
                      ? null
                      : () {
                          final id = _selectedSpaceId;
                          if (id == null) return;
                          context.push('/navigate?spaceId=$id');
                        },
                ),
                SizedBox(height: Responsive.size(context, 12)),
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
              padding: EdgeInsets.fromLTRB(
                Responsive.size(context, 16),
                Responsive.size(context, 12),
                Responsive.size(context, 16),
                Responsive.size(context, 82),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(Responsive.radius(context, 26)),
                ),
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
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 2,
                          ),
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
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 13),
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: filteredSpaces.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(width: Responsive.size(context, 14)),
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
      ),
    );
  }

  Widget _buildMapControlBtn({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: Responsive.size(context, 44),
          height: Responsive.size(context, 44),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: enabled ? const Color(0xFF163324) : const Color(0xFF9EAAB3),
            size: Responsive.size(context, 22),
          ),
        ),
      ),
    );
  }

  /// Distance in meters from the user's current GPS fix to [space]. Returns null
  /// (rendered as "--") until the first position fix arrives, so distances are
  /// always real and never the seeded static values.
  double? _distanceMetersTo(GreenSpace space) {
    final pos = ref.read(geofenceProvider).position;
    if (pos == null) return null;
    return distanceMeters(
      pos.latitude,
      pos.longitude,
      space.latitude,
      space.longitude,
    );
  }

  /// Display label for [space]'s distance (e.g. "9 m", "1.2 km", "--").
  String _distanceText(GreenSpace space) {
    final meters = _distanceMetersTo(space);
    if (meters == null) return '--';
    return formatGeoDistance(meters);
  }

  Widget _buildPlaceCard(BuildContext context, GreenSpace space) {
    final isSelected = _selectedSpaceId == space.id;
    final isBreeze = (space.destressTag ?? '').toUpperCase().contains('BREEZE');
    final tagColor = isBreeze
        ? const Color(0xFF422616).withValues(alpha: 0.9)
        : const Color(0xFF132B20).withValues(alpha: 0.88);

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
            color: isSelected
                ? const Color(0xFF2E7D32)
                : const Color(0xFFE8ECE9),
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
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(Responsive.radius(context, 17)),
                  ),
                  child: SizedBox(
                    height: Responsive.size(context, 98),
                    width: double.infinity,
                    child: Image.asset(
                      space.imageUrl ?? 'assets/images/home.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFDCEFE3),
                        child: const Center(
                          child: Icon(
                            Icons.nature,
                            color: Color(0xFF2E7D32),
                            size: 36,
                          ),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.size(context, 7),
                      vertical: Responsive.size(context, 3),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        Responsive.radius(context, 12),
                      ),
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
                        Icon(
                          Icons.star_rounded,
                          color: AppColors.goldStar,
                          size: Responsive.size(context, 14),
                        ),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.size(context, 8),
                      vertical: Responsive.size(context, 3.5),
                    ),
                    decoration: BoxDecoration(
                      color: tagColor,
                      borderRadius: BorderRadius.circular(
                        Responsive.radius(context, 6),
                      ),
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
              padding: EdgeInsets.fromLTRB(
                Responsive.size(context, 10),
                Responsive.size(context, 8),
                Responsive.size(context, 10),
                Responsive.size(context, 8),
              ),
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
                      Icon(
                        Icons.location_on_rounded,
                        size: Responsive.size(context, 12),
                        color: const Color(0xFF2E7D32),
                      ),
                      SizedBox(width: Responsive.size(context, 3)),
                      Expanded(
                        child: Text(
                          '${_distanceText(space)} • ${space.category}',
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
                            margin: EdgeInsets.only(
                              right: Responsive.size(context, 4),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.size(context, 6),
                              vertical: Responsive.size(context, 2),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F5F2),
                              borderRadius: BorderRadius.circular(
                                Responsive.radius(context, 10),
                              ),
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
