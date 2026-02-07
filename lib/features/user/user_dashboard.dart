import 'package:cemetry/core/widgets/responsive_shell.dart';
import 'package:cemetry/features/shared/profile_screen.dart';
import 'package:cemetry/features/shared/map_screen.dart';
import 'package:cemetry/features/user/user_controller.dart';
import 'package:cemetry/features/admin/admin_controller.dart' show plotsProvider;
import 'package:cemetry/features/shared/available_plots_screen.dart';
import 'package:cemetry/features/chat/user_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardIndexProvider = StateProvider<int>((ref) => 0);

class UserDashboard extends ConsumerWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(dashboardIndexProvider);

    return Scaffold(
      body: ResponsiveDashboardShell(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => ref.read(dashboardIndexProvider.notifier).state = index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_filled), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bookmark_border), label: 'My Requests'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
        railDestinations: const [
          NavigationRailDestination(icon: Icon(Icons.home_filled), label: Text('Home')),
          NavigationRailDestination(icon: Icon(Icons.bookmark_border), label: Text('My Requests')),
          NavigationRailDestination(icon: Icon(Icons.person), label: Text('Profile')),
        ],
        child: IndexedStack(
          index: selectedIndex,
          children: const [
            _UserHomeTab(),
            _UserRequestsTab(),
            ProfileScreen(),
          ],
        ),
      ),
    );
  }
}

class _UserHomeTab extends ConsumerWidget {
  const _UserHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plotsAsync = ref.watch(plotsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return Scaffold( 
      backgroundColor: Colors.grey[50], 
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header with Avatar Greeting + Chat Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   userProfileAsync.when(
                    data: (profile) => Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text((profile['name'] as String? ?? 'U')[0].toUpperCase()),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hello,', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                            Text(
                              profile['name'] ?? 'User',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    loading: () => const SizedBox(),
                    error: (_, _) => const SizedBox(),
                  ),
                  
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () {
                       Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserChatRequestScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Hero Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A49F3), Color(0xFF6C63FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF4A49F3).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Find Your Peace', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        Icon(Icons.spa, color: Colors.white.withValues(alpha: 0.8)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Premium Plots\nAvailable Now',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    const Text('Secure a lasting legacy.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 3. Services Grid
              const Text('Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildServiceItem(context, Icons.grass, 'Plots', Colors.pink, () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AvailablePlotsScreen()));
                  }),
                  _buildServiceItem(context, Icons.map, 'Map', Colors.blue, () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MapScreen()));
                  }),
                  _buildServiceItem(context, Icons.history, 'History', Colors.orange, () {
                    ref.read(dashboardIndexProvider.notifier).state = 1; // Switch to My Requests tab
                  }),
                  _buildServiceItem(context, Icons.support_agent, 'Support', Colors.green, () {}),
                ],
              ),
              const SizedBox(height: 32),

              // 4. Recent / New Listings
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   const Text('New Listings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   TextButton(onPressed: (){}, child: const Text("See All")),
                 ],
               ),
              const SizedBox(height: 16),
              plotsAsync.when(
                data: (plots) {
                  if (plots.isEmpty) return const Text('No plots found.');
                  return Column(
                    children: plots.take(5).map((plot) => _buildPlotItem(context, ref, plot)).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItem(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPlotItem(BuildContext context, WidgetRef ref, dynamic plot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: plot.imageUrl != null && plot.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      (plot.imageUrl != null && plot.imageUrl!.isNotEmpty) ? plot.imageUrl! : 'https://picsum.photos/id/10/100/100',
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.grey, size: 24),
                            Text('Error', style: TextStyle(fontSize: 8, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  )
                : Icon(Icons.grass, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plot.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                   children: [
                     const Icon(Icons.location_on, size: 12, color: Colors.grey),
                     const SizedBox(width: 4),
                     Expanded(child: Text(plot.address ?? 'No address', style: TextStyle(color: Colors.grey[600], fontSize: 12), overflow: TextOverflow.ellipsis)),
                   ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${plot.price}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700], fontSize: 16)),
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                   try {
                        await ref.read(userControllerProvider).makeRequest(plot['id'], {});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent!')));
                        }
                      } catch (e) {
                         if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to request')));
                      }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                   decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)
                   ),
                  child: Text('Request', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserRequestsTab extends ConsumerWidget {
  const _UserRequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(userRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: requestsAsync.when(
        data: (requests) {
           if (requests.isEmpty) {
            return const Center(child: Text('No bookings yet'));
           }
           return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
               final req = requests[index];
               final plot = req['plots'] ?? {};
               final status = req['status'] as String? ?? 'pending';
               Color statusColor = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
               
               return Card(
                 margin: const EdgeInsets.only(bottom: 12),
                 child: ExpansionTile(
                   leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.bookmark, color: Colors.blue),
                   ),
                   title: Text(plot['name'] ?? 'Unknown'),
                   subtitle: Text('Status: ${status.toUpperCase()}'),
                   trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  children: [
                    if (req['details'] != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Burial Information', style: TextStyle(fontWeight: FontWeight.bold)),
                            const Divider(),
                            _buildInfoRow('Deceased', req['details']['deceased_name']),
                            _buildInfoRow('Relation', req['details']['relation']),
                            _buildInfoRow('Burial Date', req['details']['burial_date']),
                            _buildInfoRow('Notes', req['details']['notes']),
                          ],
                        ),
                      ),
                  ],
                 ),
               );
            }
           );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    if (value == null || (value is String && value.isEmpty)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value.toString(), style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
