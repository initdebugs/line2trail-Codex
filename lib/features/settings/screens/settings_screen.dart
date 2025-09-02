import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/activity_types.dart';
import '../../../core/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> 
    with TickerProviderStateMixin {
  bool _waypointsVisible = true;
  ActivityType _defaultMode = ActivityType.walking;
  String _unitsSystem = 'Metric';
  String _runningSpeedUnit = 'km/h';
  bool _isLoading = true;
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    _loadSettings();
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    await SettingsService.init();
    setState(() {
      _waypointsVisible = SettingsService.getWaypointsVisible();
      _defaultMode = SettingsService.getDefaultActivity();
      _unitsSystem = SettingsService.getUnitsSystem();
      _runningSpeedUnit = SettingsService.getRunningSpeedUnit();
      _isLoading = false;
    });
    
    // Start entrance animation after loading
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern SliverAppBar with gradient
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.trailGreen,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Instellingen',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.trailGreen,
                      AppColors.pathBlue,
                    ],
                  ),
                ),
                child: const Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Icon(
                        Icons.settings,
                        size: 150,
                        color: Colors.white10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Settings Content
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Quick Stats Card
                      _buildAnimatedSection(0, _buildStatsCard()),

                      const SizedBox(height: 24),

                      // Route Settings
                      _buildAnimatedSection(
                        1,
                        _buildModernSection(
                          title: 'Route Instellingen',
                          icon: Icons.route,
                          color: AppColors.trailGreen,
                          children: [
                            _buildModernSwitchTile(
                              title: 'Waypoints tonen',
                              subtitle: 'Toon waypoints standaard op de kaart',
                              value: _waypointsVisible,
                              onChanged: (value) async {
                                HapticFeedback.selectionClick();
                                await SettingsService.setWaypointsVisible(value);
                                setState(() => _waypointsVisible = value);
                              },
                              icon: Icons.place_outlined,
                            ),
                            _buildModernDropdownTile(
                              title: 'Standaard Activiteit',
                              subtitle: _getActivityTypeInDutch(_defaultMode),
                              icon: _defaultMode.icon,
                              onTap: () => _showActivitySelector(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Speed Settings
                      _buildAnimatedSection(
                        2,
                        _buildModernSection(
                          title: 'Snelheid Instellingen',
                          icon: Icons.speed,
                          color: AppColors.pathBlue,
                          children: [
                            _buildSpeedSettingTile(
                              activity: ActivityType.walking,
                              title: 'Wandel Snelheid',
                            ),
                            _buildSpeedSettingTile(
                              activity: ActivityType.running,
                              title: 'Hardloop Snelheid',
                            ),
                            _buildSpeedSettingTile(
                              activity: ActivityType.cycling,
                              title: 'Fiets Snelheid',
                            ),
                            _buildSpeedSettingTile(
                              activity: ActivityType.hiking,
                              title: 'Hike Snelheid',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Display Settings
                      _buildAnimatedSection(
                        3,
                        _buildModernSection(
                          title: 'Weergave Instellingen',
                          icon: Icons.display_settings,
                          color: AppColors.summitOrange,
                          children: [
                            _buildModernDropdownTile(
                              title: 'Eenheden',
                              subtitle: _unitsSystem == 'Metric' ? 'Metrisch (km, m)' : 'Imperial (mi, ft)',
                              icon: Icons.straighten,
                              onTap: () => _showUnitsSelector(),
                            ),
                            if (_runningSpeedUnit == 'min/km')
                              _buildInfoTile(
                                title: 'Hardloop Eenheid',
                                subtitle: 'min/km (tempo)',
                                icon: Icons.timer,
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // App Info
                      _buildAnimatedSection(
                        4,
                        _buildModernSection(
                          title: 'App Informatie',
                          icon: Icons.info_outline,
                          color: AppColors.textSecondary,
                          children: [
                            _buildModernListTile(
                              title: 'Versie',
                              subtitle: '1.0.0 (Beta)',
                              icon: Icons.info_outlined,
                              onTap: () => _showAppInfo(),
                            ),
                            _buildModernListTile(
                              title: 'Over Line2Trail',
                              subtitle: 'Meer informatie over de app',
                              icon: Icons.hiking_outlined,
                              onTap: () => _showAbout(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSection(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 150)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - value)),
          child: Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
  
  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.trailGreenSurface,
            AppColors.pathBlueSurface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.flash_on,
                  color: AppColors.trailGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Instellingen Overzicht',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.trailGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Activiteit',
                  _getActivityTypeInDutch(_defaultMode),
                  _defaultMode.icon,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.5)),
              Expanded(
                child: _buildStatItem(
                  'Eenheden',
                  _unitsSystem == 'Metric' ? 'km/m' : 'mi/ft',
                  Icons.straighten,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.5)),
              Expanded(
                child: _buildStatItem(
                  'Waypoints',
                  _waypointsVisible ? 'Aan' : 'Uit',
                  Icons.place,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Icon(icon, color: AppColors.trailGreen, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.trailGreen,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.trailGreenSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.trailGreen),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.trailGreenSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.trailGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.trailGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdownTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _buildModernListTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.pathBlueSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.pathBlue.withOpacity(0.3)),
            ),
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.pathBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.expand_more, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.summitOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.summitOrange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.info_outline, color: AppColors.summitOrange, size: 20),
        ],
      ),
    );
  }

  Widget _buildSpeedSettingTile({
    required ActivityType activity,
    required String title,
  }) {
    final speed = SettingsService.getActivitySpeed(activity);
    String subtitle;

    if (activity == ActivityType.running && _runningSpeedUnit == 'min/km') {
      final minPerKm = 60 / speed;
      final minutes = minPerKm.floor();
      final seconds = ((minPerKm - minutes) * 60).round();
      subtitle = '${minutes}:${seconds.toString().padLeft(2, '0')} min/km';
    } else {
      subtitle = '${speed.toStringAsFixed(1)} km/h';
    }

    return _buildModernListTile(
      title: title,
      subtitle: subtitle,
      icon: activity.icon,
      onTap: () => _showSpeedSelector(activity, title),
    );
  }

  void _showActivitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Kies Standaard Activiteit',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            ...ActivityType.values.map((type) => InkWell(
              onTap: () async {
                await SettingsService.setDefaultActivity(type);
                setState(() => _defaultMode = type);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _defaultMode == type ? AppColors.trailGreenSurface : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _defaultMode == type ? AppColors.trailGreen : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(type.icon, color: AppColors.trailGreen),
                    const SizedBox(width: 16),
                    Text(
                      _getActivityTypeInDutch(type),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: _defaultMode == type ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    if (_defaultMode == type)
                      const Icon(Icons.check, color: AppColors.trailGreen),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showUnitsSelector() {
    final units = ['Metric', 'Imperial'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Kies Eenheden',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            ...units.map((unit) => InkWell(
              onTap: () async {
                await SettingsService.setUnitsSystem(unit);
                setState(() => _unitsSystem = unit);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _unitsSystem == unit ? AppColors.pathBlueSurface : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _unitsSystem == unit ? AppColors.pathBlue : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.straighten, color: AppColors.pathBlue),
                    const SizedBox(width: 16),
                    Text(
                      unit == 'Metric' ? 'Metrisch (km, m)' : 'Imperial (mi, ft)',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: _unitsSystem == unit ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    if (_unitsSystem == unit)
                      const Icon(Icons.check, color: AppColors.pathBlue),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showSpeedSelector(ActivityType activity, String title) {
    final currentSpeed = SettingsService.getActivitySpeed(activity);
    double selectedSpeed = currentSpeed;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),

                if (activity == ActivityType.running) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _runningSpeedUnit == 'km/h' ? null : () {
                            setState(() => _runningSpeedUnit = 'km/h');
                            SettingsService.setRunningSpeedUnit('km/h');
                            setModalState(() {});
                          },
                          icon: const Icon(Icons.speed),
                          label: const Text('km/h'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _runningSpeedUnit == 'km/h' ? AppColors.trailGreen : null,
                            foregroundColor: _runningSpeedUnit == 'km/h' ? Colors.white : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _runningSpeedUnit == 'min/km' ? null : () {
                            setState(() => _runningSpeedUnit = 'min/km');
                            SettingsService.setRunningSpeedUnit('min/km');
                            setModalState(() {});
                          },
                          icon: const Icon(Icons.timer),
                          label: const Text('min/km'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _runningSpeedUnit == 'min/km' ? AppColors.trailGreen : null,
                            foregroundColor: _runningSpeedUnit == 'min/km' ? Colors.white : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                if (activity == ActivityType.running && _runningSpeedUnit == 'min/km') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.trailGreenSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer, color: AppColors.trailGreen),
                        const SizedBox(width: 12),
                        Text(
                          'Tempo: ${(60/selectedSpeed).toStringAsFixed(1)} min/km',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.trailGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: selectedSpeed,
                    min: 6.0,
                    max: 20.0,
                    divisions: 70,
                    activeColor: AppColors.trailGreen,
                    onChanged: (value) {
                      setModalState(() => selectedSpeed = value);
                    },
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.pathBlueSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.speed, color: AppColors.pathBlue),
                        const SizedBox(width: 12),
                        Text(
                          '${selectedSpeed.toStringAsFixed(1)} km/h',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.pathBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: selectedSpeed,
                    min: _getMinSpeed(activity),
                    max: _getMaxSpeed(activity),
                    divisions: (_getMaxSpeed(activity) - _getMinSpeed(activity)).round(),
                    activeColor: AppColors.trailGreen,
                    onChanged: (value) {
                      setModalState(() => selectedSpeed = value);
                    },
                  ),
                ],

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuleren'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await SettingsService.setActivitySpeed(activity, selectedSpeed);
                          setState(() {});
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.trailGreen,
                        ),
                        child: const Text('Opslaan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.hiking, color: AppColors.trailGreen),
            const SizedBox(width: 8),
            const Text('Line2Trail'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versie: 1.0.0 (Beta)'),
            SizedBox(height: 8),
            Text('Een app voor het tekenen van wandel-, fiets-, hardloop- en wandelroutes.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Over Line2Trail'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Line2Trail is een handige app voor het plannen van routes voor verschillende activiteiten.'),
            SizedBox(height: 12),
            Text('Functies:'),
            Text('• Teken routes met je vinger'),
            Text('• Automatisch aanpassing aan paden'),
            Text('• Hoogteprofiel analyse'),
            Text('• Route statistieken'),
            Text('• Verschillende activiteitstypen'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  double _getMinSpeed(ActivityType activity) {
    switch (activity) {
      case ActivityType.walking:
        return 2.0;
      case ActivityType.running:
        return 6.0;
      case ActivityType.cycling:
        return 10.0;
      case ActivityType.hiking:
        return 1.0;
    }
  }

  double _getMaxSpeed(ActivityType activity) {
    switch (activity) {
      case ActivityType.walking:
        return 8.0;
      case ActivityType.running:
        return 20.0;
      case ActivityType.cycling:
        return 40.0;
      case ActivityType.hiking:
        return 6.0;
    }
  }

  String _getActivityTypeInDutch(ActivityType type) {
    switch (type) {
      case ActivityType.walking:
        return 'Wandelen';
      case ActivityType.running:
        return 'Hardlopen';
      case ActivityType.hiking:
        return 'Hiken';
      case ActivityType.cycling:
        return 'Fietsen';
    }
  }
}