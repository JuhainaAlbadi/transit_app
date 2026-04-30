import 'mock_transit_service.dart';
import 'transit_service.dart';

class TransitTools {
  final MockTransitService _omanService = MockTransitService();
  final TransitService _belgianService = TransitService();

  Future<Map<String, dynamic>> getDelayInfo(String station) async {
    try {
      final departures = MockTransitService.stations.contains(station)
          ? await _omanService.getDepartures(station)
          : await _belgianService.getDepartures(station);

      final delayed = departures.where((d) => d.delay != '0').toList();

      return {
        'station': station,
        'total_departures': departures.length,
        'delayed_count': delayed.length,
        'delays': delayed.map((d) => {
          'destination': d.station,
          'delay_minutes': int.parse(d.delay) ~/ 60,
          'platform': d.track,
        }).toList(),
        'status': delayed.isEmpty ? 'All services on time' : '${delayed.length} service(s) delayed',
      };
    } catch (e) {
      return {'error': 'Could not fetch delay info: $e'};
    }
  }

  Future<Map<String, dynamic>> getAlternativeRoutes(
      String origin, String destination) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'origin': origin,
      'destination': destination,
      'routes': [
        {
          'route_id': 'R1',
          'description': 'Direct bus via main road',
          'duration_minutes': 25,
          'transfers': 0,
          'crowding': 'Low',
          'recommendation': 'Fastest option',
        },
        {
          'route_id': 'R2',
          'description': 'Via city center with transfer',
          'duration_minutes': 35,
          'transfers': 1,
          'crowding': 'Medium',
          'recommendation': 'More frequent service',
        },
        {
          'route_id': 'R3',
          'description': 'Scenic coastal route',
          'duration_minutes': 45,
          'transfers': 0,
          'crowding': 'Low',
          'recommendation': 'Best if no rush',
        },
      ],
    };
  }

  Future<Map<String, dynamic>> getNearbyStops(
      double lat, double lng) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'location': {'lat': lat, 'lng': lng},
      'nearby_stops': [
        {'name': 'Ruwi Bus Station', 'distance_m': 120, 'status': 'On time'},
        {'name': 'Al Khuwair Stop', 'distance_m': 340, 'status': 'On time'},
        {'name': 'Wattayah Stop', 'distance_m': 580, 'status': 'Delayed 5 min'},
      ],
    };
  }
}