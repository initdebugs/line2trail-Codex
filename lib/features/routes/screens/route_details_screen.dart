import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/activity_types.dart';
import '../models/saved_route.dart';
import '../widgets/route_map_preview.dart';
import '../widgets/elevation_chart.dart';
import '../../../shared/services/path_analysis_service.dart';
import '../../../shared/services/elevation_service.dart';

class RouteDetailsScreen extends StatefulWidget {
  final SavedRoute route;
  final Function(SavedRoute)? onOpenOnMap;

  const RouteDetailsScreen({
    super.key,
    required this.route,
    this.onOpenOnMap,
  });

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> 
    with TickerProviderStateMixin {
  late Future<PathTypeBreakdown> _pathBreakdownFuture;
  late Future<ElevationProfile> _elevationFuture;
  late Map<String, dynamic> _routeMetrics;
  
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Setup animations
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _pathBreakdownFuture = PathAnalysisService.analyze(
      widget.route.points,
      widget.route.activityType,
    );
    _elevationFuture = ElevationService.getProfile(widget.route.points);
    _routeMetrics = _calculateRouteMetrics();
    
    // Start animations
    _slideController.forward();
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _calculateRouteMetrics() {
    final points = widget.route.points;
    if (points.length < 2) return {};

    final distance = Distance();
    double totalDistance = 0;
    double maxSpeed = 0;
    List<double> speeds = [];
    List<double> bearings = [];

    // Calculate basic metrics
    for (int i = 1; i < points.length; i++) {
      final segmentDistance = distance(points[i - 1], points[i]);
      totalDistance += segmentDistance;
      
      // Calculate bearing changes for route complexity
      if (i < points.length - 1) {
        final bearing1 = distance.bearing(points[i - 1], points[i]);
        final bearing2 = distance.bearing(points[i], points[i + 1]);
        bearings.add((bearing2 - bearing1).abs());
      }
    }

    // Estimate route complexity based on direction changes
    double complexity = 1.0;
    if (bearings.isNotEmpty) {
      final avgBearingChange = bearings.reduce((a, b) => a + b) / bearings.length;
      complexity = (avgBearingChange / 90).clamp(0.5, 2.0);
    }

    // Check if route is a loop
    final isLoop = distance(points.first, points.last) < 50;

    // Estimate calories burned based on activity type and distance
    double caloriesPerKm;
    switch (widget.route.activityType) {
      case ActivityType.running:
        caloriesPerKm = 65;
        break;
      case ActivityType.cycling:
        caloriesPerKm = 25;
        break;
      case ActivityType.hiking:
        caloriesPerKm = 55;
        break;
      case ActivityType.walking:
        caloriesPerKm = 40;
        break;
    }

    final estimatedCalories = (widget.route.distance * caloriesPerKm * complexity).round();

    return {
      'totalDistance': totalDistance,
      'complexity': complexity,
      'isLoop': isLoop,
      'estimatedCalories': estimatedCalories,
      'waypoints': points.length,
      'avgSegmentLength': totalDistance / (points.length - 1),
    };
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.route;
    return Scaffold(
      appBar: AppBar(
        title: Text(r.name),
        actions: [
          IconButton(
            tooltip: 'Deel route',
            icon: const Icon(Icons.share),
            onPressed: () => _shareRoute(r),
          ),
          IconButton(
            tooltip: 'Open op kaart',
            icon: const Icon(Icons.map),
            onPressed: () {
              widget.onOpenOnMap?.call(r);
              Navigator.of(context).maybePop();
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _slideController,
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildAnimatedItem(0, _header(r)),
                    const SizedBox(height: 12),
                    _buildAnimatedItem(1, RouteMapPreview(points: r.points)),
                    const SizedBox(height: 12),
                    _buildAnimatedItem(2, _quickStats(r)),
                    const SizedBox(height: 12),
                    _buildAnimatedItem(3, _routeMetricsCard()),
                    const SizedBox(height: 12),
                    _buildAnimatedItem(4, _pathTypes()),
                    const SizedBox(height: 12),
                    _buildAnimatedItem(5, _performanceStats()),
                    const SizedBox(height: 12),
                    _buildAnimatedItem(6, _elevationSection()),
                    if (r.description != null && r.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildAnimatedItem(7, _description(r.description!)),
                    ],
                    const SizedBox(height: 16),
                    _buildAnimatedItem(8, _buildOpenMapButton(r)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header(SavedRoute r) {
    return Hero(
      tag: 'route-${r.id}',
      child: Material(
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.trailGreenSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(r.activityType.icon, color: AppColors.trailGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                r.location ?? 'Onbekende locatie',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                r.formattedDate,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
        ),
      ),
    );
  }

  Widget _quickStats(SavedRoute r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _statChip(Icons.straighten, 'Afstand', r.formattedDistance, AppColors.pathBlue),
            _statChip(Icons.schedule, 'Tijd', r.formattedTime, AppColors.pathBlue),
            FutureBuilder<ElevationProfile>(
              future: _elevationFuture,
              builder: (context, snap) {
                final ascent = snap.hasData ? '${snap.data!.totalAscent.round()} m' : '—';
                final descent = snap.hasData ? '${snap.data!.totalDescent.round()} m' : '—';
                return Wrap(
                  spacing: 8,
                  children: [
                    _statChip(Icons.trending_up, 'Stijging', ascent, AppColors.elevationGain),
                    _statChip(Icons.trending_down, 'Daling', descent, AppColors.elevationLoss),
                  ],
                );
              },
            ),
            _statChip(Icons.local_fire_department, 'Calorieën', '${_routeMetrics['estimatedCalories']} kcal', AppColors.warningAmber),
            if (_routeMetrics['isLoop'] == true)
              _statChip(Icons.loop, 'Rondgang', 'Loop', AppColors.trailGreen),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pathTypes() {
    return FutureBuilder<PathTypeBreakdown>(
      future: _pathBreakdownFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _sectionCard(
            title: 'Padtypen',
            child: const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
          );
        }
        final b = snapshot.data!;
        final items = [
          _PathItem('Voetpad', b.footpathPercent, AppColors.trailGreen),
          _PathItem('Fietspad', b.cyclePathPercent, AppColors.pathBlue),
          _PathItem('Weg', b.roadPercent, AppColors.warningAmber),
        ];
        
        final hasValidData = items.any((item) => item.percent > 0);
        return _sectionCard(
          title: 'Padtypen',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasValidData) ...[
                _stackedBar(items),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _metricChip('Moeilijkheid', b.difficulty, _getDifficultyColor(b.difficulty)),
                    _metricChip('Gem. snelheid', '${b.avgSpeed.toStringAsFixed(1)} km/h', AppColors.pathBlue),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: items
                    .where((i) => i.percent > 0)
                    .map((i) => Row(mainAxisSize: MainAxisSize.min, children: [
                          _legendDot(i.color),
                          const SizedBox(width: 6),
                          Text('${i.label}: ${i.percent.toStringAsFixed(1)}%'),
                        ]))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legendDot(Color color) {
    return Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }

  Widget _stackedBar(List<_PathItem> items) {
    return SizedBox(
      height: 16,
      child: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          return Row(
            children: items
                .map((i) => Container(
                      width: width * (i.percent.clamp(0, 100) / 100.0),
                      height: 16,
                      color: i.color,
                    ))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _elevationSection() {
    return FutureBuilder<ElevationProfile>(
      future: _elevationFuture,
      builder: (context, snapshot) {
        return _sectionCard(
          title: 'Hoogteprofiel',
          child: snapshot.hasData
              ? ElevationChart(
                  elevations: snapshot.data!.samples,
                )
              : const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
        );
      },
    );
  }

  Widget _description(String description) {
    return _sectionCard(
      title: 'Beschrijving',
      child: Text(description),
    );
  }

  Widget _routeMetricsCard() {
    return _sectionCard(
      title: 'Route Details',
      child: Column(
        children: [
          _metricRow('Complexiteit', _getComplexityText(_routeMetrics['complexity'])),
          _metricRow('Aantal punten', '${_routeMetrics['waypoints']}'),
          _metricRow('Gem. segment', '${(_routeMetrics['avgSegmentLength'] as double).round()} m'),
          if (_routeMetrics['isLoop'] == true)
            _metricRow('Type', 'Rondgang'),
        ],
      ),
    );
  }

  Widget _performanceStats() {
    return FutureBuilder<PathTypeBreakdown>(
      future: _pathBreakdownFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _sectionCard(
            title: 'Prestatie Analyse',
            child: const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
          );
        }
        
        final breakdown = snapshot.data!;
        return _sectionCard(
          title: 'Prestatie Analyse',
          child: Column(
            children: [
              _metricRow('Segmenten', '${breakdown.segments.length}'),
              _metricRow('Geschatte snelheid', '${breakdown.avgSpeed.toStringAsFixed(1)} km/h'),
              _metricRow('Moeilijkheidsgraad', breakdown.difficulty),
              const SizedBox(height: 8),
              _buildSpeedDistribution(breakdown.segments),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpeedDistribution(List<dynamic> segments) {
    if (segments.isEmpty) return const SizedBox.shrink();
    
    // This would show speed variation analysis
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Snelheid Variatie',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [
                AppColors.elevationLoss,
                AppColors.pathBlue,
                AppColors.elevationGain,
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Langzaam', style: Theme.of(context).textTheme.bodySmall),
            Text('Snel', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _metricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'makkelijk':
        return AppColors.trailGreen;
      case 'gemiddeld':
        return AppColors.warningAmber;
      case 'moeilijk':
        return AppColors.elevationLoss;
      default:
        return AppColors.pathBlue;
    }
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.trailGreen,
            ),
          ),
        ],
      ),
    );
  }

  String _getComplexityText(double complexity) {
    if (complexity < 0.7) return 'Eenvoudig';
    if (complexity < 1.3) return 'Gemiddeld';
    return 'Complex';
  }

  void _shareRoute(SavedRoute route) {
    _pathBreakdownFuture.then((breakdown) {
      final routeText = '''${route.name}

Afstand: ${route.formattedDistance}
Geschatte tijd: ${route.formattedTime}
Activiteit: ${route.activityType.displayName}
Calorieën: ${_routeMetrics['estimatedCalories']} kcal
Moeilijkheid: ${breakdown.difficulty}
Gem. snelheid: ${breakdown.avgSpeed.toStringAsFixed(1)} km/h
${_routeMetrics['isLoop'] == true ? 'Type: Rondgang' : ''}

Gemaakt met Line2Trail''';
      
      Clipboard.setData(ClipboardData(text: routeText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route gekopieerd naar klembord'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }).catchError((_) {
      // Fallback without advanced metrics
      final routeText = '''${route.name}

Afstand: ${route.formattedDistance}
Geschatte tijd: ${route.formattedTime}
Activiteit: ${route.activityType.displayName}
Calorieën: ${_routeMetrics['estimatedCalories']} kcal

Gemaakt met Line2Trail''';
      
      Clipboard.setData(ClipboardData(text: routeText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route gekopieerd naar klembord'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
  
  Widget _buildOpenMapButton(SavedRoute route) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.9, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: FilledButton.icon(
            onPressed: () async {
              // Add haptic feedback
              HapticFeedback.lightImpact();
              
              // Smooth exit animation
              await _slideController.reverse();
              widget.onOpenOnMap?.call(route);
              if (mounted) {
                Navigator.of(context).maybePop();
              }
            },
            icon: const Icon(Icons.map),
            label: const Text('Open op kaart'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.trailGreen,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.white.withOpacity(0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.trailGreen.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title, 
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.trailGreen,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _PathItem {
  final String label;
  final double percent;
  final Color color;
  _PathItem(this.label, this.percent, this.color);
}

