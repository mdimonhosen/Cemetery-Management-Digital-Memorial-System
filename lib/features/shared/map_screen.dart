import 'package:cemetry/core/models/plot.dart';
import 'package:cemetry/features/admin/admin_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plotsAsync = ref.watch(plotsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cemetry Map')),
      body: plotsAsync.when(
        data: (plots) {
          // Filter plots that have valid coordinates
          final validPlots = plots.where((p) => p.latitude != null && p.longitude != null).toList();

          if (validPlots.isEmpty) {
            return const Center(child: Text('No mapped plots available.'));
          }
          
          // Default center (or first plot)
          final initialCenter = LatLng(validPlots.first.latitude!, validPlots.first.longitude!);

          return FlutterMap(
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.cemetry.app',
              ),
              MarkerLayer(
                markers: validPlots.map((plot) {
                  final isAvailable = plot.status == 'available';
                  return Marker(
                    point: LatLng(plot.latitude!, plot.longitude!),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showPlotDetails(context, plot),
                      child: Icon(
                        Icons.location_on,
                        color: isAvailable ? Colors.green : Colors.red,
                        size: 40,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showPlotDetails(BuildContext context, Plot plot) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plot.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Status: ${plot.status.toUpperCase()}', 
                style: TextStyle(color: plot.status == 'available' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
             if (plot.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    plot.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.grey, size: 40),
                            SizedBox(height: 8),
                            Text('Image unavailable', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            const SizedBox(height: 16),
            Text('Price: \$${plot.price ?? 0}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
             Text(plot.description ?? 'No description'),
          ],
        ),
      ),
    );
  }
}
