import 'package:flutter/material.dart';
import '../models/departure.dart';
import '../services/transit_service.dart';
import '../services/mock_transit_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TransitService _irailService = TransitService();
  final MockTransitService _omanService = MockTransitService();

  List<Departure> _departures = [];
  bool _isLoading = false;
  String _error = '';
  bool _useOman = true;

  String _selectedOmanStation = 'Ruwi Bus Station';
  String _selectedBelgianStation = 'Gent-Sint-Pieters';

  final List<String> _belgianStations = [
    'Gent-Sint-Pieters',
    'Brussel-Centraal',
    'Antwerpen-Centraal',
  ];

  @override
  void initState() {
    super.initState();
    _loadDepartures();
  }

  Future<void> _loadDepartures() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      List<Departure> departures;
      if (_useOman) {
        departures = await _omanService.getDepartures(_selectedOmanStation);
      } else {
        departures = await _irailService.getDepartures(_selectedBelgianStation);
      }
      setState(() {
        _departures = departures;
        _isLoading = false;
      });
      _notifyDelays(departures);
    } catch (e) {
      setState(() {
        _error = 'Could not load departures. Check your connection.';
        _isLoading = false;
      });
    }
  }

  void _notifyDelays(List<Departure> departures) {
    final delayed = departures.where((d) => d.delay != '0').toList();
    if (delayed.isEmpty || !mounted) return;

    final names = delayed.map((d) => d.station).join(', ');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 4),
        content: Text(
          '${delayed.length} delay${delayed.length > 1 ? 's' : ''}: $names',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  String _formatTime(String timestamp) {
    final date =
        DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp) * 1000);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Public Transport Assistant',
            style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDepartures,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            color: cs.primary,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _useOman = true);
                          _loadDepartures();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _useOman ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '🇴🇲 Oman (Mwasalat)',
                              style: TextStyle(
                                color: _useOman ? cs.primary : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _useOman = false);
                          _loadDepartures();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_useOman ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '🇧🇪 Belgium (IRAIL)',
                              style: TextStyle(
                                color: !_useOman ? cs.primary : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _useOman
                    ? DropdownButtonFormField<String>(
                        value: _selectedOmanStation,
                        dropdownColor: cs.primary,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Select Omani Station',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white30)),
                        ),
                        items: MockTransitService.stations
                            .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s,
                                    style: const TextStyle(color: Colors.white))))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedOmanStation = value!);
                          _loadDepartures();
                        },
                      )
                    : DropdownButtonFormField<String>(
                        value: _selectedBelgianStation,
                        dropdownColor: cs.primary,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Select Belgian Station',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white30)),
                        ),
                        items: _belgianStations
                            .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s,
                                    style: const TextStyle(color: Colors.white))))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedBelgianStation = value!);
                          _loadDepartures();
                        },
                      ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : _error.isNotEmpty
                    ? Center(
                        child: Text(_error,
                            style: const TextStyle(color: Colors.red)))
                    : RefreshIndicator(
                        onRefresh: _loadDepartures,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _departures.length,
                          itemBuilder: (context, index) {
                            final d = _departures[index];
                            final delayed = d.delay != '0';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: cs.primary,
                                  child: Text(d.track,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12)),
                                ),
                                title: Text(d.station,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  delayed
                                      ? 'Delayed ${int.parse(d.delay) ~/ 60} min'
                                      : 'On time',
                                  style: TextStyle(
                                      color: delayed ? Colors.red : Colors.green),
                                ),
                                trailing: Text(
                                  _formatTime(d.time),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
