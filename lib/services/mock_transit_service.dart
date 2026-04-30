import '../models/departure.dart';

class MockTransitService {
  static final Map<String, List<Map<String, dynamic>>> _stops = {
    'Ruwi Bus Station': [
      {'station': 'Seeb', 'platform': '1', 'route': 'Route 1', 'delayMin': 0},
      {'station': 'Al Khuwair', 'platform': '2', 'route': 'Route 2', 'delayMin': 5},
      {'station': 'Qurum', 'platform': '3', 'route': 'Route 3', 'delayMin': 0},
      {'station': 'Wattayah', 'platform': '1', 'route': 'Route 4', 'delayMin': 10},
      {'station': 'Azaiba', 'platform': '4', 'route': 'Route 5', 'delayMin': 0},
    ],
    'Seeb Bus Station': [
      {'station': 'Ruwi', 'platform': '1', 'route': 'Route 1', 'delayMin': 0},
      {'station': 'Airport', 'platform': '2', 'route': 'Route 6', 'delayMin': 3},
      {'station': 'Sohar', 'platform': '3', 'route': 'Route 7', 'delayMin': 0},
      {'station': 'Barka', 'platform': '1', 'route': 'Route 8', 'delayMin': 7},
    ],
    'Al Khuwair': [
      {'station': 'Ruwi', 'platform': '1', 'route': 'Route 2', 'delayMin': 0},
      {'station': 'Qurum', 'platform': '2', 'route': 'Route 9', 'delayMin': 0},
      {'station': 'Mawaleh', 'platform': '3', 'route': 'Route 10', 'delayMin': 15},
    ],
    'Sohar Bus Station': [
      {'station': 'Muscat', 'platform': '1', 'route': 'Route 7', 'delayMin': 0},
      {'station': 'Barka', 'platform': '2', 'route': 'Route 11', 'delayMin': 5},
      {'station': 'Shinas', 'platform': '1', 'route': 'Route 12', 'delayMin': 0},
    ],
    'Salalah Bus Station': [
      {'station': 'Muscat', 'platform': '1', 'route': 'Route 20', 'delayMin': 0},
      {'station': 'Mirbat', 'platform': '2', 'route': 'Route 21', 'delayMin': 8},
      {'station': 'Taqah', 'platform': '3', 'route': 'Route 22', 'delayMin': 0},
    ],
  };

  Future<List<Departure>> getDepartures(String station) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final now = DateTime.now();
    final buses = _stops[station] ?? [];

    return List.generate(buses.length, (i) {
      final departureTime = now.add(Duration(minutes: 5 + (i * 8)));
      final bus = buses[i];
      return Departure(
        station: bus['station'],
        time: (departureTime.millisecondsSinceEpoch ~/ 1000).toString(),
        delay: (bus['delayMin'] * 60).toString(),
        track: bus['platform'],
      );
    });
  }

  static List<String> get stations => _stops.keys.toList();
}