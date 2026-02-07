import 'package:cemetry/features/admin/admin_controller.dart' show plotsProvider, adminControllerProvider;
import 'package:cemetry/features/auth/auth_service.dart';
import 'package:cemetry/features/user/user_controller.dart' show userControllerProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AvailablePlotsScreen extends ConsumerWidget {
  const AvailablePlotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We can use either provider, but let's use userPlotsProvider for general viewing
    final plotsAsync = ref.watch(plotsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Plots'),
      ),
      body: plotsAsync.when(
        data: (plots) {
          final availablePlots = plots.where((p) => p.status == 'available').toList();
          
          if (availablePlots.isEmpty) {
            return const Center(child: Text('No available plots at the moment.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: availablePlots.length,
            itemBuilder: (context, index) {
              final plot = availablePlots[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        (plot.imageUrl != null && plot.imageUrl!.isNotEmpty) ? plot.imageUrl! : 'https://picsum.photos/id/10/600/400',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[100],
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200, 
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Image failed to load', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(plot.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              Text('\$${plot.price}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(plot.address ?? 'No Address', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(plot.description ?? 'No description available.'),
                          const SizedBox(height: 16),
                          FutureBuilder<int>(
                            future: ref.read(authServiceProvider).getUserRole(),
                            builder: (context, snapshot) {
                              final isAdmin = snapshot.data == 1;
                              return Column(
                                children: [
                                  if (isAdmin)
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: () => _showDirectBookingDialog(context, ref, plot.id),
                                        style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
                                        icon: const Icon(Icons.flash_on),
                                        label: const Text('Book Directly'),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () => _showBookingDetailsDialog(context, ref, plot.id),
                                      child: const Text('Request Booking'),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showBookingDetailsDialog(BuildContext context, WidgetRef ref, String plotId) {
    final deceasedNameCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Burial Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: deceasedNameCtrl, decoration: const InputDecoration(labelText: 'Name of Deceased')),
              TextField(controller: relationCtrl, decoration: const InputDecoration(labelText: 'Relationship to Deceased')),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(labelText: 'Estimated Burial Date', hintText: 'YYYY-MM-DD'),
                keyboardType: TextInputType.datetime,
              ),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Special Notes'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (deceasedNameCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deceased name is required')));
                return;
              }
              try {
                final details = {
                  'deceased_name': deceasedNameCtrl.text,
                  'relation': relationCtrl.text,
                  'burial_date': dateCtrl.text,
                  'notes': notesCtrl.text,
                };
                await ref.read(userControllerProvider).makeRequest(plotId, details);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking request sent!')));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  void _showDirectBookingDialog(BuildContext context, WidgetRef ref, String plotId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Direct Booking'),
        content: const Text('Are you sure you want to book this plot directly? This will mark it as sold immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                await ref.read(adminControllerProvider).bookPlotDirectly(plotId: plotId);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back from plots screen
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plot booked successfully!')));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }
}
