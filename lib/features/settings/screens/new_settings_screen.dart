import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/activity_types.dart';
import '../../../core/services/settings_service.dart';

class NewSettingsScreen extends StatefulWidget {
  const NewSettingsScreen({super.key});

  @override
  State<NewSettingsScreen> createState() => _NewSettingsScreenState();
}

class _NewSettingsScreenState extends State<NewSettingsScreen> {
  bool _waypointsVisible = true;
  ActivityType _defaultMode = ActivityType.walking;
  String _language = 'Nederlands';
  String _unitsSystem = 'Metric';
  bool _showCompass = true;
  bool _routeNotifications = true;
  bool _achievementNotifications = false;
  bool _autoPause = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await SettingsService.init();
    setState(() {
      _waypointsVisible = SettingsService.getWaypointsVisible();
      _defaultMode = SettingsService.getDefaultActivity();
      _language = SettingsService.getLanguage();
      _unitsSystem = SettingsService.getUnitsSystem();
      _isLoading = false;
    });
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
                      AppColors.trailGreenLight,
                    ],
                  ),
                ),
                child: const Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Icon(
                        Icons.settings,
                        size: 200,
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Quick Actions Row
                  _buildQuickActionsCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Route Settings
                  _buildModernSection(
                    title: 'Route Instellingen',
                    icon: Icons.route,
                    color: AppColors.pathBlue,
                    children: [
                      _buildModernSwitchTile(
                        title: 'Waypoints tonen',
                        subtitle: 'Toon waypoints standaard op de kaart',
                        value: _waypointsVisible,
                        onChanged: (value) async {
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
                  
                  const SizedBox(height: 16),
                  
                  // App Settings
                  _buildModernSection(
                    title: 'App Instellingen',
                    icon: Icons.phone_android,
                    color: AppColors.summitOrange,
                    children: [
                      _buildModernDropdownTile(
                        title: 'Taal',
                        subtitle: _language,
                        icon: Icons.language,
                        onTap: () => _showLanguageSelector(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Map Settings
                  _buildModernSection(
                    title: 'Kaart Instellingen',
                    icon: Icons.map_outlined,
                    color: AppColors.trailGreen,
                    children: [
                      _buildModernSwitchTile(
                        title: 'Kompas tonen',
                        subtitle: 'Toon kompas widget op de kaart',
                        value: _showCompass,
                        onChanged: (value) => setState(() => _showCompass = value),
                        icon: Icons.explore_outlined,
                      ),
                      _buildModernListTile(
                        title: 'Kaartthema',
                        subtitle: 'OpenStreetMap standaard',
                        icon: Icons.palette_outlined,
                        onTap: () => _showComingSoon('Kaartthema'),
                      ),
                      _buildModernDropdownTile(
                        title: 'Eenheden',
                        subtitle: _unitsSystem == 'Metric' ? 'Metrisch (km, m)' : 'Imperial (mi, ft)',
                        icon: Icons.straighten,
                        onTap: () => _showUnitsSelector(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Notifications
                  _buildModernSection(
                    title: 'Meldingen',
                    icon: Icons.notifications_outlined,
                    color: AppColors.warningAmber,
                    children: [
                      _buildModernSwitchTile(
                        title: 'Route Meldingen',
                        subtitle: 'Meldingen voor route updates',
                        value: _routeNotifications,
                        onChanged: (value) => setState(() => _routeNotifications = value),
                        icon: Icons.route_outlined,
                      ),
                      _buildModernSwitchTile(
                        title: 'Prestatie Meldingen',
                        subtitle: 'Meldingen voor mijlpalen',
                        value: _achievementNotifications,
                        onChanged: (value) => setState(() => _achievementNotifications = value),
                        icon: Icons.emoji_events_outlined,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Advanced Settings
                  _buildModernSection(
                    title: 'Geavanceerd',
                    icon: Icons.tune,
                    color: AppColors.textSecondary,
                    children: [
                      _buildModernSwitchTile(
                        title: 'Auto-pause',
                        subtitle: 'Pauzeer automatisch bij stilstand',
                        value: _autoPause,
                        onChanged: (value) => setState(() => _autoPause = value),
                        icon: Icons.pause_circle_outline,
                      ),
                      _buildModernListTile(
                        title: 'Opname Interval',
                        subtitle: 'Elk 5 seconden',
                        icon: Icons.timer_outlined,
                        onTap: () => _showComingSoon('Opname interval'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Data & Info
                  _buildModernSection(
                    title: 'Data & Info',
                    icon: Icons.info_outline,
                    color: AppColors.pathBlueDark,
                    children: [
                      _buildModernListTile(
                        title: 'Routes Exporteren',
                        subtitle: 'Exporteer naar GPX/KML',
                        icon: Icons.file_upload_outlined,
                        onTap: () => _showComingSoon('Export'),
                      ),
                      _buildModernListTile(
                        title: 'App Versie',
                        subtitle: '1.0.0 (Beta)',
                        icon: Icons.info_outlined,
                        onTap: () => _showVersionInfo(),
                      ),
                      _buildModernListTile(
                        title: 'Feedback',
                        subtitle: 'Help ons verbeteren',
                        icon: Icons.feedback_outlined,
                        onTap: () => _showComingSoon('Feedback'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: AppColors.trailGreen,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Snelle Acties',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.trailGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.help_outline,
                    label: 'Help',
                    onTap: () => _showComingSoon('Help'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.info_outline,
                    label: 'Over',
                    onTap: () => _showVersionInfo(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.feedback_outlined,
                    label: 'Feedback',
                    onTap: () => _showComingSoon('Feedback'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: AppColors.trailGreen),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.trailGreen,
              ),
            ),
          ],
        ),
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
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
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
          ...children.map((child) => child).toList(),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.pathBlueSurface,
              borderRadius: BorderRadius.circular(20),
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

  void _showActivitySelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kies Standaard Activiteit',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ...ActivityType.values.map((type) => ListTile(
              leading: Icon(type.icon, color: AppColors.trailGreen),
              title: Text(_getActivityTypeInDutch(type)),
              trailing: _defaultMode == type ? const Icon(Icons.check, color: AppColors.trailGreen) : null,
              onTap: () async {
                await SettingsService.setDefaultActivity(type);
                setState(() => _defaultMode = type);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    final languages = ['Nederlands', 'English'];
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kies Taal',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ...languages.map((lang) => ListTile(
              leading: const Icon(Icons.language, color: AppColors.trailGreen),
              title: Text(lang),
              trailing: _language == lang ? const Icon(Icons.check, color: AppColors.trailGreen) : null,
              onTap: () async {
                await SettingsService.setLanguage(lang);
                setState(() => _language = lang);
                Navigator.pop(context);
              },
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kies Eenheden',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ...units.map((unit) => ListTile(
              leading: const Icon(Icons.straighten, color: AppColors.trailGreen),
              title: Text(unit == 'Metric' ? 'Metrisch (km, m)' : 'Imperial (mi, ft)'),
              trailing: _unitsSystem == unit ? const Icon(Icons.check, color: AppColors.trailGreen) : null,
              onTap: () async {
                await SettingsService.setUnitsSystem(unit);
                setState(() => _unitsSystem = unit);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showVersionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Informatie'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pathify'),
            SizedBox(height: 4),
            Text('Versie: 1.0.0 (Beta)', style: TextStyle(color: AppColors.textSecondary)),
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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature komt binnenkort beschikbaar'),
        backgroundColor: AppColors.trailGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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