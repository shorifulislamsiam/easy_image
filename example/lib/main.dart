import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_image/easy_image.dart';

// Sample 1x1 green PNG for memory demo
final Uint8List sampleMemoryPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkWMrwHwAC/wGA3o125AAAAABJRU5ErkJggg==',
);

// Sample SVG string
const String sampleSvgData = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <circle cx="50" cy="50" r="45" fill="#4CAF50" />
  <path d="M30 50 L45 65 L70 35" stroke="#FFFFFF" stroke-width="8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>
''';

void main() {
  runApp(const EasyImageExampleApp());
}

class EasyImageExampleApp extends StatelessWidget {
  const EasyImageExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Image Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  String _lastCacheSource = 'None';
  int _downloadedBytes = 0;
  int _totalBytes = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Easy Image Examples (v1.0.0)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear Cache',
            onPressed: () async {
              await SmartImage.clearCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image cache cleared!')),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('1. Basic Network Image with Fade-in'),
          const Center(
            child: SmartImage(
              url:
                  'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=500',
              width: 280,
              height: 180,
              radius: 12,
              shimmer: true,
              semanticLabel: 'Oil painting on canvas',
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('2. Circular Avatar'),
          const Center(
            child: SmartImage.circle(
              url:
                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
              radius: 50,
              shimmer: true,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('3. SVG Vector Image (flutter_svg built-in)'),
          Center(
            child: SmartImage(
              bytes: Uint8List.fromList(utf8.encode(sampleSvgData)),
              width: 80,
              height: 80,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('4. Memory Bytes Image'),
          Center(
            child: SmartImage(
              bytes: sampleMemoryPng,
              width: 100,
              height: 60,
              radius: 8,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('5. Shimmer Loading State'),
          const Center(
            child: SmartImage(
              url: 'https://httpstat.us/200?sleep=10000',
              width: 240,
              height: 120,
              radius: 12,
              shimmer: true,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('6. BlurHash Progressive Placeholder'),
          const Center(
            child: SmartImage(
              url:
                  'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=500',
              blurHash: 'L6PZfSi_.AyE_3t7t7R**0o#DgR4',
              width: 260,
              height: 150,
              radius: 12,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('7. Error State with Retry Button'),
          Center(
            child: SmartImage(
              url: 'https://invalid-non-existent-domain.xyz/broken.png',
              width: 180,
              height: 120,
              radius: 12,
              onRetry: () {
                debugPrint('Retrying image load...');
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('8. Observability & Cache Source Tracking'),
          Center(
            child: Column(
              children: [
                SmartImage(
                  url:
                      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500',
                  width: 260,
                  height: 150,
                  radius: 12,
                  shimmer: true,
                  config: SmartImageConfig(
                    onCacheHit: (source) {
                      setState(() {
                        _lastCacheSource = source.name;
                      });
                    },
                    onLoadProgress: (received, total) {
                      setState(() {
                        _downloadedBytes = received;
                        _totalBytes = total;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cache Source: $_lastCacheSource | Progress: $_downloadedBytes / $_totalBytes bytes',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(
              '9. Authenticated Request with Header-Aware Cache Key'),
          const Center(
            child: SmartImage(
              url:
                  'https://images.unsplash.com/photo-1518770660439-4636190af475?w=500',
              headers: {'Authorization': 'Bearer demo_session_token_123'},
              width: 240,
              height: 140,
              radius: 12,
              shimmer: true,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('10. CDN URL Transformation'),
          Center(
            child: SmartImage(
              url:
                  'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
              width: 220,
              height: 130,
              radius: 12,
              config: SmartImageConfig(
                cdnTransform: (url, {width, height}) {
                  return '$url?w=${width ?? 300}&fit=crop';
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(
              '11. Custom Max Bytes Guard (Oversized Rejection)'),
          Center(
            child: SmartImage(
              url:
                  'https://images.unsplash.com/photo-1579783902614-a3fb3927b675',
              width: 240,
              height: 120,
              radius: 12,
              config: const SmartImageConfig(
                maxBytes: 100, // Very low limit to trigger size exception
              ),
              errorWidget: Container(
                color: Colors.red.shade50,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Blocked: Max download size exceeded (Safety guard triggered)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}
