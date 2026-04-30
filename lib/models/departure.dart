class Departure {
  final String station;
  final String time;
  final String delay;
  final String track;

  Departure({
    required this.station,
    required this.time,
    required this.delay,
    required this.track,
  });

  factory Departure.fromJson(Map<String, dynamic> json) {
    return Departure(
      station: json['stationinfo']['standardname'] ?? 'Unknown',
      time: json['time'] ?? '',
      delay: json['delay'] ?? '0',
      track: json['platform'] ?? '?',
    );
  }
}