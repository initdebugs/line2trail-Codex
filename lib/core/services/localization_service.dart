import '../services/settings_service.dart';

class LocalizationService {
  static String getCurrentLanguage() {
    return SettingsService.getLanguage();
  }

  static bool get isEnglish => getCurrentLanguage() == 'English';
  static bool get isDutch => getCurrentLanguage() == 'Nederlands';

  // App Bar Titles
  static String get settings => isEnglish ? 'Settings' : 'Instellingen';
  static String get map => isEnglish ? 'Map' : 'Kaart';
  static String get routes => isEnglish ? 'Routes' : 'Routes';
  static String get navigate => isEnglish ? 'Navigate' : 'Navigeren';

  // Route Bar
  static String get draw => isEnglish ? 'Draw' : 'Tekenen';
  static String get stop => isEnglish ? 'Stop' : 'Stop';
  static String get save => isEnglish ? 'Save' : 'Opslaan';

  // Settings Screen
  static String get routeSettings => isEnglish ? 'Route Settings' : 'Route Instellingen';
  static String get showWaypoints => isEnglish ? 'Show Waypoints' : 'Waypoints tonen';
  static String get showWaypointsDesc => isEnglish ? 'Show waypoints by default on the map' : 'Standaard waypoints zichtbaar maken op de kaart';
  static String get defaultMode => isEnglish ? 'Default Activity' : 'Standaard Modus';
  static String get defaultModeDesc => isEnglish ? 'Default activity type for new routes' : 'De standaard activiteitstype voor nieuwe routes';
  
  static String get appSettings => isEnglish ? 'App Settings' : 'App Instellingen';
  static String get language => isEnglish ? 'Language' : 'Taal';
  static String get languageDesc => isEnglish ? 'Choose app interface language' : 'Kies de taal voor de app interface';
  
  static String get mapSettings => isEnglish ? 'Map Settings' : 'Kaart Instellingen';
  static String get units => isEnglish ? 'Units' : 'Eenheden';
  static String get unitsDesc => isEnglish ? 'Choose distance and speed units' : 'Kies afstands- en snelheidseenheden';
  static String get mapTheme => isEnglish ? 'Map Theme' : 'Kaartthema';
  static String get showCompass => isEnglish ? 'Show Compass' : 'Kompas tonen';
  static String get showCompassDesc => isEnglish ? 'Show compass widget on map' : 'Kompas widget op de kaart weergeven';

  // Activity Types
  static String get walking => isEnglish ? 'Walking' : 'Wandelen';
  static String get running => isEnglish ? 'Running' : 'Hardlopen';
  static String get hiking => isEnglish ? 'Hiking' : 'Hiken';
  static String get cycling => isEnglish ? 'Cycling' : 'Fietsen';

  // Dialog and Actions
  static String get chooseActivity => isEnglish ? 'Choose Activity' : 'Kies Activiteit';
  static String get chooseLanguage => isEnglish ? 'Choose Language' : 'Kies Taal';
  static String get chooseUnits => isEnglish ? 'Choose Units' : 'Kies Eenheden';
  static String get cancel => isEnglish ? 'Cancel' : 'Annuleren';
  static String get close => isEnglish ? 'Close' : 'Sluiten';

  // Units
  static String get metric => isEnglish ? 'Metric (km, m)' : 'Metrisch (km, m)';
  static String get imperial => isEnglish ? 'Imperial (mi, ft)' : 'Imperial (mi, ft)';

  // Bottom Navigation Labels
  static String get mapTab => isEnglish ? 'Map' : 'Kaart';
  static String get routesTab => isEnglish ? 'Routes' : 'Routes';
  static String get navigationTab => isEnglish ? 'Navigate' : 'Navigeren';
  static String get settingsTab => isEnglish ? 'Settings' : 'Instellingen';

  // Route Tools
  static String get undo => isEnglish ? 'Undo' : 'Ongedaan';
  static String get redo => isEnglish ? 'Redo' : 'Opnieuw';
  static String get show => isEnglish ? 'Show' : 'Tonen';
  static String get hide => isEnglish ? 'Hide' : 'Verbergen';
  static String get loop => isEnglish ? 'Loop' : 'Lus';
  static String get clear => isEnglish ? 'Clear' : 'Wissen';
  static String get more => isEnglish ? 'More' : 'Meer';

  // Speed Settings
  static String get speedSettings => isEnglish ? 'Speed Settings' : 'Snelheid Instellingen';
  static String get walkingSpeed => isEnglish ? 'Walking Speed' : 'Wandel Snelheid';
  static String get runningSpeed => isEnglish ? 'Running Speed' : 'Hardloop Snelheid';
  static String get cyclingSpeed => isEnglish ? 'Cycling Speed' : 'Fiets Snelheid';
  static String get hikingSpeed => isEnglish ? 'Hiking Speed' : 'Hike Snelheid';

  // Quick Actions
  static String get quickActions => isEnglish ? 'Quick Actions' : 'Snelle Acties';
  static String get help => isEnglish ? 'Help' : 'Help';
  static String get about => isEnglish ? 'About' : 'Over';
  static String get feedback => isEnglish ? 'Feedback' : 'Feedback';

  // Placeholder Screen
  static String get comingSoon => isEnglish ? 'Coming Soon' : 'Komt Binnenkort';
  static String get featureComingSoon => isEnglish ? 'This feature will be available soon.' : 'Deze functie wordt binnenkort beschikbaar.';
  static String get featureInDevelopment => isEnglish ? 'Feature in development' : 'Functie in ontwikkeling';
  static String get moreInfo => isEnglish ? 'More Info' : 'Meer Info';

  // General Actions
  static String get ok => isEnglish ? 'OK' : 'OK';
  static String get yes => isEnglish ? 'Yes' : 'Ja';
  static String get no => isEnglish ? 'No' : 'Nee';
}