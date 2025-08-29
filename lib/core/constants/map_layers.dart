enum MapLayerType {
  openStreetMap,
  stadiaOutdoors,
}

extension MapLayerTypeExtension on MapLayerType {
  String get displayName {
    switch (this) {
      case MapLayerType.openStreetMap:
        return 'OpenStreetMap';
      case MapLayerType.stadiaOutdoors:
        return 'Stadia Outdoors';
      
    }
  }

  String get urlTemplate {
    switch (this) {
      case MapLayerType.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapLayerType.stadiaOutdoors:
        return 'https://tiles.stadiamaps.com/tiles/outdoors/{z}/{x}/{y}{r}.png?api_key=14fea9a8-cd92-483a-8ed6-380b4bbc1301';
      
    }
  }

  String get attribution {
    switch (this) {
      case MapLayerType.openStreetMap:
        return '© OpenStreetMap contributors';
      case MapLayerType.stadiaOutdoors:
        return '© Stadia Maps © OpenMapTiles © OpenStreetMap contributors';
      
    }
  }
}

class MapLayerHelper {
  static MapLayerType fromString(String value) {
    switch (value) {
      case 'OpenStreetMap':
        return MapLayerType.openStreetMap;
      case 'Stadia Outdoors':
        return MapLayerType.stadiaOutdoors;
      case 'MapTiler OpenStreetMap':
        // Fallback for removed layer
        return MapLayerType.openStreetMap;
      default:
        return MapLayerType.openStreetMap;
    }
  }
}
