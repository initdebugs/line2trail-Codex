import 'dart:math';
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';

class ElevationProfile {
  final List<double> samples; // meters
  final double totalAscent; // meters
  final double totalDescent; // meters
  ElevationProfile({
    required this.samples,
    required this.totalAscent,
    required this.totalDescent,
  });
}

class ElevationService {
  // Open-Meteo Elevation API
  static const String _baseUrl = 'https://api.open-meteo.com/v1/elevation';

  // Uses remote elevation data when available; falls back to a conservative synthetic profile.
  static Future<ElevationProfile> getProfile(List<LatLng> points) async {
    if (points.length < 2) {
      return ElevationProfile(samples: const [], totalAscent: 0, totalDescent: 0);
    }

    try {
      return await _fetchFromApi(points);
    } catch (_) {
      // Fall back to synthetic profile with realistic bounds
      return _syntheticProfile(points);
    }
  }

  static Future<ElevationProfile> _fetchFromApi(List<LatLng> points) async {
    // Downsample to limit query size; keep overall shape.
    final sampled = _downsample(points, maxPoints: 100);
    final latitudes = sampled.map((p) => p.latitude.toStringAsFixed(6)).join(',');
    final longitudes = sampled.map((p) => p.longitude.toStringAsFixed(6)).join(',');

    final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 12)));
    final response = await dio.get(
      _baseUrl,
      queryParameters: {
        'latitude': latitudes,
        'longitude': longitudes,
      },
      options: Options(responseType: ResponseType.json),
    );

    final data = response.data;
    final samples = <double>[];

    if (data is Map) {
      final elev = data['elevation'];
      if (elev is List) {
        for (final v in elev) {
          if (v is num) samples.add(v.toDouble());
        }
      } else if (elev is num) {
        samples.add(elev.toDouble());
      }
    }

    if (samples.isEmpty) {
      throw Exception('No elevation data');
    }

    // Optional: light smoothing to reduce noise effects on ascent/descent
    final smoothed = _movingAverage(samples, window: 3);
    final totals = _computeTotals(smoothed, minDeltaThreshold: 0.5);
    return ElevationProfile(samples: smoothed, totalAscent: totals.$1, totalDescent: totals.$2);
  }

  static (double, double) _computeTotals(List<double> samples, {double minDeltaThreshold = 0.0}) {
    double ascent = 0, descent = 0;
    for (int i = 1; i < samples.length; i++) {
      final d = samples[i] - samples[i - 1];
      if (minDeltaThreshold > 0 && d.abs() < minDeltaThreshold) continue;
      if (d > 0) ascent += d; else descent += -d;
    }
    return (ascent, descent);
  }

  static List<LatLng> _downsample(List<LatLng> points, {required int maxPoints}) {
    if (points.length <= maxPoints) return points;
    final step = points.length / (maxPoints - 1);
    final result = <LatLng>[];
    for (int i = 0; i < maxPoints; i++) {
      final idx = (i * step).round().clamp(0, points.length - 1);
      result.add(points[idx]);
    }
    return result;
  }

  static ElevationProfile _syntheticProfile(List<LatLng> points) {
    final totalMeters = _totalDistance(points);
    final isLoop = Distance()(points.first, points.last) <= 50.0;
    const maxGrade = 0.03; // cap ascent to ~3% of distance
    const reliefCapMeters = 400.0; // absolute cap
    final maxAscent = min(totalMeters * maxGrade, reliefCapMeters);
    final targetAscent = max(2.0, maxAscent * 0.6);

    final sampleCount = max(32, min(300, (totalMeters / 20).round()));
    final rng = Random(_hashPoints(points));
    final baseline = 10.0 + rng.nextInt(60);
    final amplitude = targetAscent;
    final samples = <double>[];
    for (int i = 0; i < sampleCount; i++) {
      final t = i / (sampleCount - 1);
      double h;
      if (isLoop) {
        h = t <= 0.5 ? (t / 0.5) * amplitude : ((1 - t) / 0.5) * amplitude;
      } else {
        final riseEnd = 0.6;
        if (t <= riseEnd) {
          h = (t / riseEnd) * amplitude;
        } else {
          h = amplitude * (1 - (t - riseEnd) * 0.15);
        }
      }
      final jitter = (sin(t * pi) * 0.05 + sin(t * pi * 0.5) * 0.03) * amplitude;
      samples.add(baseline + max(0, h + jitter));
    }

    var (ascent, descent) = _computeTotals(samples, minDeltaThreshold: 0.5);
    ascent = ascent.clamp(0, maxAscent * 1.2);
    descent = isLoop ? ascent : min(descent, ascent * 0.9);
    return ElevationProfile(samples: samples, totalAscent: ascent, totalDescent: descent);
  }

  static int _hashPoints(List<LatLng> pts) {
    // Simple deterministic hash from coordinates
    int h = 0x9e3779b1;
    for (final p in pts.take(50)) {
      h ^= (p.latitude * 10000).round();
      h = (h << 5) - h + (p.longitude * 10000).round();
      h &= 0x7fffffff;
    }
    return h;
  }

  static double _totalDistance(List<LatLng> points) {
    final distance = Distance();
    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += distance(points[i - 1], points[i]);
    }
    return total;
  }

  static List<double> _movingAverage(List<double> values, {int window = 3}) {
    if (values.isEmpty || window <= 1) return values;
    final w = window.clamp(2, 15);
    final res = <double>[];
    for (int i = 0; i < values.length; i++) {
      int start = max(0, i - (w ~/ 2));
      int end = min(values.length - 1, i + (w ~/ 2));
      double sum = 0;
      int count = 0;
      for (int j = start; j <= end; j++) {
        sum += values[j];
        count++;
      }
      res.add(sum / count);
    }
    return res;
  }
}
