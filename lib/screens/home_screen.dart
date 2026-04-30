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
    } catch (e) {
      setState(() {
        _error = 'Could not load departures. Check your connection.';
        _isLoading = false;
      });
    }
  }

  String _formatTime(String timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp) * 1000);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('AI Public Transport Assistant',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
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
            color: Colors.blue[800],
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
                            child: Text('🇴🇲 Oman (Mwasalat)',
                                style: TextStyle(
                                    color: _useOman
                                        ? Colors.blue[900]
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
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
                            child: Text('🇧🇪 Belgium (IRAIL)',
                                style: TextStyle(
                                    color: !_useOman
                                        ? Colors.blue[900]
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
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
                        dropdownColor: Colors.blue[800],
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
                                    style:
                                        const TextStyle(color: Colors.white))))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedOmanStation = value!);
                          _loadDepartures();
                        },
                      )
                    : DropdownButtonFormField<String>(
                        value: _selectedBelgianStation,
                        dropdownColor: Colors.blue[800],
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
                                    style:
                                        const TextStyle(color: Colors.white))))
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
                ? const Center(child: CircularProgressIndicator())
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
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[900],
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
                                        color: delayed
                                            ? Colors.red
                                            : Colors.green)),
                                trailing: Text(_formatTime(d.time),
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[900])),
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