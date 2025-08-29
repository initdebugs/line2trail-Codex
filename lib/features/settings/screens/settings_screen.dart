import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/activity_types.dart';
import '../../../core/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _waypointsVisible = true;
  ActivityType _defaultMode = ActivityType.walking;
  String _language = 'Nederlands';
  String _unitsSystem = 'Metric';
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
        appBar: AppBar(
          title: const Text('Instellingen'),
          backgroundColor: AppColors.trailGreen,
          foregroundColor: AppColors.textInverse,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instellingen'),
        backgroundColor: AppColors.trailGreen,
        foregroundColor: AppColors.textInverse,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Route Instellingen'),
          const SizedBox(height: 8),
          _buildCard([
            _buildSwitchTile(
              title: 'Waypoints tonen',
              subtitle: 'Standaard waypoints zichtbaar maken op de kaart',
              value: _waypointsVisible,
              onChanged: (value) async {
                await SettingsService.setWaypointsVisible(value);
                setState(() => _waypointsVisible = value);
              },
              icon: Icons.place,
            ),
            const Divider(height: 1),
            _buildDropdownTile<ActivityType>(
              title: 'Standaard Modus',
              subtitle: 'De standaard activiteitstype voor nieuwe routes',
              value: _defaultMode,
              icon: _defaultMode.icon,
              items: ActivityType.values
                  .map((type) => DropdownMenuItem<ActivityType>(
                        value: type,
                        child: Row(
                          children: [
                            Icon(type.icon, size: 20),
                            const SizedBox(width: 8),
                            Text(_getActivityTypeInDutch(type)),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (ActivityType? value) async {
                if (value != null) {
                  await SettingsService.setDefaultActivity(value);
                  setState(() => _defaultMode = value);
                }
              },
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader('App Instellingen'),
          const SizedBox(height: 8),
          _buildCard([
            _buildDropdownTile<String>(
              title: 'Taal',
              subtitle: 'Kies de taal voor de app interface',
              value: _language,
              icon: Icons.language,
              items: ['Nederlands', 'English']
                  .map((lang) => DropdownMenuItem<String>(
                        value: lang,
                        child: Text(lang),
                      ))
                  .toList(),
              onChanged: (String? value) async {
                if (value != null) {
                  await SettingsService.setLanguage(value);
                  setState(() => _language = value);
                }
              },
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader('Kaart Instellingen'),
          const SizedBox(height: 8),
          _buildCard([
            _buildListTile(
              title: 'Kaartthema',
              subtitle: 'OpenStreetMap standaard',
              icon: Icons.map,
              onTap: () => _showComingSoon('Kaartthema selectie'),
            ),
            const Divider(height: 1),
            _buildDropdownTile<String>(
              title: 'Eenheden',
              subtitle: 'Kies afstands- en snelheidseenheden',
              value: _unitsSystem,
              icon: Icons.straighten,
              items: ['Metric', 'Imperial']
                  .map((unit) => DropdownMenuItem<String>(
                        value: unit,
                        child: Text(unit == 'Metric' ? 'Metrisch (km, m)' : 'Imperial (mi, ft)'),
                      ))
                  .toList(),
              onChanged: (String? value) async {
                if (value != null) {
                  await SettingsService.setUnitsSystem(value);
                  setState(() => _unitsSystem = value);
                }
              },
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'Kompas tonen',
              subtitle: 'Kompas widget op de kaart weergeven',
              value: true,
              onChanged: (value) => _showComingSoon('Kompas instelling'),
              icon: Icons.explore,
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader('Route Opname'),
          const SizedBox(height: 8),
          _buildCard([
            _buildSwitchTile(
              title: 'Auto-pause',
              subtitle: 'Automatisch pauzeren bij stilstand',
              value: false,
              onChanged: (value) => _showComingSoon('Auto-pause functie'),
              icon: Icons.pause_circle,
            ),
            const Divider(height: 1),
            _buildListTile(
              title: 'Opname Interval',
              subtitle: 'Elk 5 seconden',
              icon: Icons.timer,
              onTap: () => _showComingSoon('Opname interval'),
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader('Meldingen'),
          const SizedBox(height: 8),
          _buildCard([
            _buildSwitchTile(
              title: 'Route Meldingen',
              subtitle: 'Meldingen voor route updates',
              value: true,
              onChanged: (value) => _showComingSoon('Route meldingen'),
              icon: Icons.notifications,
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'Prestatie Meldingen',
              subtitle: 'Meldingen voor mijlpalen en prestaties',
              value: false,
              onChanged: (value) => _showComingSoon('Prestatie meldingen'),
              icon: Icons.emoji_events,
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader('Gegevens & Privacy'),
          const SizedBox(height: 8),
          _buildCard([
            _buildListTile(
              title: 'Routes Exporteren',
              subtitle: 'Exporteer routes naar GPX/KML',
              icon: Icons.file_upload,
              onTap: () => _showComingSoon('Route export'),
            ),
            const Divider(height: 1),
            _buildListTile(
              title: 'Gegevens Wissen',
              subtitle: 'Alle opgeslagen routes verwijderen',
              icon: Icons.delete_forever,
              onTap: () => _showComingSoon('Gegevens wissen'),
            ),
            const Divider(height: 1),
            _buildListTile(
              title: 'Privacy Beleid',
              subtitle: 'Bekijk ons privacy beleid',
              icon: Icons.privacy_tip,
              onTap: () => _showComingSoon('Privacy beleid'),
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader('Over'),
          const SizedBox(height: 8),
          _buildCard([
            _buildListTile(
              title: 'App Versie',
              subtitle: '1.0.0 (Beta)',
              icon: Icons.info,
              onTap: () => _showComingSoon('Versie informatie'),
            ),
            const Divider(height: 1),
            _buildListTile(
              title: 'Feedback Geven',
              subtitle: 'Help ons de app te verbeteren',
              icon: Icons.feedback,
              onTap: () => _showComingSoon('Feedback formulier'),
            ),
            const Divider(height: 1),
            _buildListTile(
              title: 'Licenties',
              subtitle: 'Open source licenties bekijken',
              icon: Icons.article,
              onTap: () => _showComingSoon('Licentie informatie'),
            ),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.trailGreen,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.trailGreen,
        size: 24,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      secondary: Icon(
        icon,
        color: AppColors.trailGreen,
        size: 24,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.trailGreen,
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required String subtitle,
    required T value,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.trailGreen,
        size: 24,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: Container(),
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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature komt binnenkort beschikbaar'),
        backgroundColor: AppColors.trailGreen,
      ),
    );
  }
}