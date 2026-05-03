import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/claude_service.dart';

class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({super.key});

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  final ClaudeService _gemini = ClaudeService();
  bool _isRunning = false;
  int _completed = 0;
  List<Map<String, dynamic>> _results = [];
  String _status = 'Ready to benchmark';

  final List<Map<String, String>> _testQueries = [
    // Delay queries (tool 1)
    {'query': 'Is there a delay at Ruwi Bus Station?', 'type': 'delay'},
    {'query': 'Any delays at Seeb Bus Station?', 'type': 'delay'},
    {'query': 'What delays at Al Khuwair?', 'type': 'delay'},
    {'query': 'هل هناك تأخير في محطة الرويّ؟', 'type': 'delay_arabic'},
    {'query': 'تأخير في محطة السيب؟', 'type': 'delay_arabic'},
    {'query': 'Is Gent-Sint-Pieters delayed?', 'type': 'delay'},
    {'query': 'Delays at Brussel-Centraal?', 'type': 'delay'},
    {'query': 'Any service disruptions at Sohar?', 'type': 'delay'},
    {'query': 'Is Salalah Bus Station on time?', 'type': 'delay'},
    {'query': 'هل الخدمة منتظمة في السلالة؟', 'type': 'delay_arabic'},
    // Route queries (tool 2)
    {'query': 'How do I get from Ruwi to Seeb?', 'type': 'route'},
    {'query': 'Best route from Seeb to Al Khuwair?', 'type': 'route'},
    {'query': 'Alternative routes from Sohar to Muscat?', 'type': 'route'},
    {'query': 'كيف أصل من الرويّ إلى السيب؟', 'type': 'route_arabic'},
    {'query': 'ما هي البدائل من السيب إلى مسقط؟', 'type': 'route_arabic'},
    {'query': 'How to travel from Gent to Brussels?', 'type': 'route'},
    {'query': 'Best way from Antwerp to Brussels?', 'type': 'route'},
    {'query': 'Route from Salalah to Muscat?', 'type': 'route'},
    {'query': 'How do I get from Wattayah to Qurum?', 'type': 'route'},
    {'query': 'أفضل طريق من مسقط إلى صلالة؟', 'type': 'route_arabic'},
    // Nearby stops (tool 3)
    {'query': 'What are the nearest stops to me?', 'type': 'nearby'},
    {'query': 'Show me nearby bus stations', 'type': 'nearby'},
    {'query': 'Which stop is closest?', 'type': 'nearby'},
    {'query': 'ما هي المحطات القريبة مني؟', 'type': 'nearby_arabic'},
    {'query': 'أقرب محطة إليّ؟', 'type': 'nearby_arabic'},
    // General queries
    {'query': 'What time does the last bus leave Ruwi?', 'type': 'general'},
    {'query': 'How many stops between Seeb and Ruwi?', 'type': 'general'},
    {'query': 'Is the transit system reliable in Oman?', 'type': 'general'},
    {'query': 'Tell me about Mwasalat buses', 'type': 'general'},
    {'query': 'What transport options exist in Muscat?', 'type': 'general'},
    // French
    {'query': 'Y a-t-il des retards à Bruxelles?', 'type': 'delay_french'},
    {'query': 'Comment aller de Gand à Bruxelles?', 'type': 'route_french'},
    // Spanish
    {'query': '¿Hay retrasos en Bruselas?', 'type': 'delay_spanish'},
    {'query': '¿Cómo llego de Gante a Bruselas?', 'type': 'route_spanish'},
    // More English
    {'query': 'Is Route 1 running on time?', 'type': 'delay'},
    {'query': 'What platforms are available at Ruwi?', 'type': 'general'},
    {'query': 'How crowded is the bus to Seeb?', 'type': 'general'},
    {'query': 'Are there delays on Route 2?', 'type': 'delay'},
    {'query': 'What is the fastest route to the airport?', 'type': 'route'},
    {'query': 'Show me all routes from Al Khuwair', 'type': 'route'},
    // More Arabic
    {'query': 'متى يغادر آخر باص من الرويّ؟', 'type': 'general_arabic'},
    {'query': 'كم عدد المحطات بين السيب والرويّ؟', 'type': 'general_arabic'},
    {'query': 'ما هي خيارات النقل في مسقط؟', 'type': 'general_arabic'},
    {'query': 'هل الباص رقم 2 متأخر؟', 'type': 'delay_arabic'},
    {'query': 'أريد الذهاب إلى المطار', 'type': 'route_arabic'},
    // Mixed
    {'query': 'Delay info for all Muscat stations', 'type': 'delay'},
    {'query': 'Compare routes from Ruwi to Seeb', 'type': 'route'},
    {'query': 'Is public transport safe in Oman?', 'type': 'general'},
    {'query': 'هل النقل العام آمن في عُمان؟', 'type': 'general_arabic'},
    {'query': 'Best time to travel to avoid crowds', 'type': 'general'},
  ];

  Future<void> _runBenchmark() async {
    setState(() {
      _isRunning = true;
      _completed = 0;
      _results = [];
      _status = 'Running benchmark...';
    });

    for (final query in _testQueries) {
      _gemini.resetChat();
      final stopwatch = Stopwatch()..start();
      await _gemini.sendMessage(query['query']!);
      stopwatch.stop();

      setState(() {
        _results.add({
          'query': query['query'],
          'type': query['type'],
          'latency_ms': stopwatch.elapsedMilliseconds,
        });
        _completed++;
        _status = 'Running... $_completed/${_testQueries.length}';
      });

      await Future.delayed(const Duration(milliseconds: 500));
    }

    setState(() {
      _isRunning = false;
      _status = 'Benchmark complete!';
    });
  }

  double get _mean {
    if (_results.isEmpty) return 0;
    final total = _results.fold(0, (sum, r) => sum + (r['latency_ms'] as int));
    return total / _results.length;
  }

  double get _median {
    if (_results.isEmpty) return 0;
    final sorted = _results.map((r) => r['latency_ms'] as int).toList()..sort();
    return sorted[sorted.length ~/ 2].toDouble();
  }

  double get _p95 {
    if (_results.isEmpty) return 0;
    final sorted = _results.map((r) => r['latency_ms'] as int).toList()..sort();
    final index = (sorted.length * 0.95).floor();
    return sorted[index].toDouble();
  }

  String get _csvData {
    final buffer = StringBuffer();
    buffer.writeln('query,type,latency_ms');
    for (final r in _results) {
      buffer.writeln('"${r['query']}",${r['type']},${r['latency_ms']}');
    }
    buffer.writeln('\nSummary');
    buffer.writeln('Mean,${_mean.toStringAsFixed(0)}ms');
    buffer.writeln('Median,${_median.toStringAsFixed(0)}ms');
    buffer.writeln('95th Percentile,${_p95.toStringAsFixed(0)}ms');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Benchmark',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                      label: 'Mean', value: '${_mean.toStringAsFixed(0)}ms'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                      label: 'Median',
                      value: '${_median.toStringAsFixed(0)}ms'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                      label: '95th %ile',
                      value: '${_p95.toStringAsFixed(0)}ms'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _testQueries.isEmpty
                  ? 0
                  : _completed / _testQueries.length,
              backgroundColor: Colors.grey[300],
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(_status,
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary),
                    onPressed: _isRunning ? null : _runBenchmark,
                    child: Text(
                        _isRunning ? 'Running...' : 'Run 50 Queries',
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700]),
                    onPressed: _results.isEmpty ? null : () async {
                      await Clipboard.setData(ClipboardData(text: _csvData));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('CSV copied to clipboard!')),
                        );
                      }
                    },
                    child: const Text('Copy CSV',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700]),
                    onPressed: _results.isEmpty ? null : () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('CSV Data'),
                          content: SingleChildScrollView(
                            child: SelectableText(_csvData,
                                style: const TextStyle(fontSize: 11)),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            )
                          ],
                        ),
                      );
                    },
                    child: const Text('View CSV',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final r = _results[index];
                  final ms = r['latency_ms'] as int;
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: ms < 2000
                          ? Colors.green
                          : ms < 4000
                              ? Colors.orange
                              : Colors.red,
                      child: Text('${index + 1}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10)),
                    ),
                    title: Text(r['query'] as String,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text(r['type'] as String,
                        style: const TextStyle(fontSize: 11)),
                    trailing: Text('${ms}ms',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ms < 2000
                                ? Colors.green
                                : ms < 4000
                                    ? Colors.orange
                                    : Colors.red)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label,
              style:
                  TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }
}