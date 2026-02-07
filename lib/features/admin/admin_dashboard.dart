import 'package:cemetry/core/widgets/responsive_shell.dart';
import 'package:cemetry/features/admin/admin_controller.dart';
import 'package:cemetry/features/shared/profile_screen.dart';
import 'package:cemetry/features/shared/map_screen.dart'; 
import 'package:cemetry/features/auth/auth_service.dart';
import 'package:cemetry/features/shared/available_plots_screen.dart';
import 'package:cemetry/features/chat/admin_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavigationDrawer(
        onDestinationSelected: (idx) {
             Navigator.pop(context); 
             if (idx == 0) { /* Already here */ }
             if (idx == 1) { 
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MapScreen()));
             }
             if (idx == 6) { // Sign Out index
               ref.read(authServiceProvider).signOut();
               context.go('/login');
             }
        },
        children: const [
           Padding(
             padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
             child: Text('Admin Menu', style: TextStyle(fontWeight: FontWeight.bold)),
           ),
           NavigationDrawerDestination(icon: Icon(Icons.dashboard), label: Text('All Plots')),
           NavigationDrawerDestination(icon: Icon(Icons.map), label: Text('Map')),
           NavigationDrawerDestination(icon: Icon(Icons.edit), label: Text('Edit Plots')),
           NavigationDrawerDestination(icon: Icon(Icons.assignment), label: Text('Booking Requests')),
           NavigationDrawerDestination(icon: Icon(Icons.check_circle), label: Text('Accepted List')),
           NavigationDrawerDestination(icon: Icon(Icons.history), label: Text('History')),
           Padding(padding: EdgeInsets.symmetric(horizontal: 28), child: Divider()),
           NavigationDrawerDestination(icon: Icon(Icons.logout), label: Text('Sign Out')),
        ],
      ),
      body: ResponsiveDashboardShell(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.assignment), label: 'Requests'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
        railDestinations: const [
          NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
          NavigationRailDestination(icon: Icon(Icons.assignment), label: Text('Requests')),
          NavigationRailDestination(icon: Icon(Icons.person), label: Text('Profile')),
        ],
        child: IndexedStack(
          index: _selectedIndex,
          children: const [
            _AdminHomeTab(),
            _AdminRequestsTab(),
            ProfileScreen(),
          ],
        ),
      ),
    );
  }
}

class _AdminHomeTab extends ConsumerWidget {
  const _AdminHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availablePlotsAsync = ref.watch(availablePlotsProvider);
    final allPlotsAsync = ref.watch(plotsProvider);
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
              // 1. Header with Slider Button (Menu) + Avatar Greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Builder(builder: (context) {
                        return IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        );
                      }),
                      const SizedBox(width: 8),
                      // ... Avatar and Greeting logic
                      userProfileAsync.when(
                        data: (profile) => Text('Welcome, ${profile['name'] ?? 'Admin'}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        loading: () => const SizedBox(), 
                        error: (_, _) => const SizedBox(),
                      ),
                    ],
                  ),
                   IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminChatListScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Hero Card (Stats or Action)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF2E3192).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('System Overview', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        Icon(Icons.admin_panel_settings, color: Colors.white.withValues(alpha: 0.8)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Show count if available
                    // Show detailed stats
                    allPlotsAsync.when(
                      data: (plots) {
                        final availableCount = plots.where((p) => p.status == 'available').length;
                        final soldCount = plots.where((p) => p.status == 'sold').length;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$availableCount Available Plots', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            Text('$soldCount Sold Plots', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        );
                      },
                      loading: () => const Text('...', style: TextStyle(color: Colors.white, fontSize: 24)),
                      error: (_, _) => const Text('Error', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 24),
                    const Text('Manage your lands efficiently.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 3. Services / Actions Grid
              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround, // Space equally
                children: [
                   _buildServiceItem(context, Icons.add_location_alt, 'Plots', Colors.green, () {
                     Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AvailablePlotsScreen()));
                   }),
                   _buildServiceItem(context, Icons.add_circle_outline, 'Add Plot', Colors.orange, () => _showAddPlotDialog(context, ref)),
                   // Map Button added here
                   _buildServiceItem(context, Icons.map, 'Map', Colors.blue, () {
                     Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MapScreen()));
                   }),
                   _buildServiceItem(context, Icons.analytics, 'Analytics', Colors.purple, () {
                     Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SoldPlotsScreen()));
                   }),
                  _buildServiceItem(context, Icons.settings, 'Settings', Colors.grey, () => _showSettingsDialog(context, ref)),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Available Plots', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              availablePlotsAsync.when(
                data: (plots) {
                  if (plots.isEmpty) return const Text('No plots uploaded yet.');
                  return Column(
                    children: plots.map((plot) => _buildPlotItem(context, ref, plot)).toList(),
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
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
        ],
      ),
    );
  }

  // Reuse the Plot Item logic (same as before)
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
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                (plot.imageUrl != null && plot.imageUrl!.isNotEmpty) ? plot.imageUrl! : 'https://picsum.photos/id/10/100/100',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, color: Colors.grey, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plot.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(plot.address ?? 'No Address', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${plot.price}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
               PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'edit') {
                    // We need a way to pass the full plot object or refetch. 
                    // Assuming 'plot' is the Plot object.
                    _showEditPlotDialog(context, ref, plot);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Edit')])),
                  // Delete could be added here later
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.person_add, color: Colors.blue),
              ),
              title: const Text('Add New Admin'),
              subtitle: const Text('Create a new account with user type 1'),
              onTap: () {
                Navigator.pop(context);
                _showAddAdminDialog(context, ref);
              },
            ),
            const SizedBox(height: 16),
             ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.info_outline, color: Colors.grey),
              ),
              title: const Text('App Version'),
              subtitle: const Text('1.0.0.36'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAdminDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Admin Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 12),
              TextField(controller: mobileCtrl, decoration: const InputDecoration(labelText: 'Mobile Number')),
              const SizedBox(height: 12),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Home Address')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty || nameCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in required fields')));
                return;
              }
              try {
                await ref.read(authServiceProvider).createAdmin(
                  email: emailCtrl.text,
                  password: passCtrl.text,
                  name: nameCtrl.text,
                  mobile: mobileCtrl.text,
                  address: addrCtrl.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin account created successfully!')));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }, 
            child: const Text('Create Account')
          ),
        ],
      ),
    );
  }

  void _showAddPlotDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final imageController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final mapLinkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Plot'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Plot Name', prefixIcon: Icon(Icons.title))),
              const SizedBox(height: 12),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on))),
              const SizedBox(height: 12),
               Row(
                children: [
                  Expanded(child: TextField(controller: latController, decoration: const InputDecoration(labelText: 'Latitude', hintText: 'e.g. 23.81'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: lngController, decoration: const InputDecoration(labelText: 'Longitude', hintText: 'e.g. 90.41'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: mapLinkController, decoration: const InputDecoration(labelText: 'Google Maps Link', prefixIcon: Icon(Icons.link))),
              const SizedBox(height: 12),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)), maxLines: 2),
              const SizedBox(height: 12),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price', prefixIcon: Icon(Icons.attach_money)), keyboardType: TextInputType.number),
               const SizedBox(height: 12),
              TextField(controller: imageController, decoration: const InputDecoration(labelText: 'Image URL', prefixIcon: Icon(Icons.image))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
               if (nameController.text.isEmpty) return;
              try {
                final price = double.tryParse(priceController.text) ?? 0.0;
                final lat = double.tryParse(latController.text);
                final lng = double.tryParse(lngController.text);
                
                Navigator.pop(context);

               await ref.read(adminControllerProvider).addPlot(
                      name: nameController.text,
                      address: addressController.text,
                      description: descController.text,
                      price: price,
                      imageUrl: imageController.text.isNotEmpty ? imageController.text : null,
                      latitude: lat,
                      longitude: lng,
                      googleMapsLink: mapLinkController.text.isNotEmpty ? mapLinkController.text : null,
                    );
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plot added!')));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Add Plot'),
          ),
        ],
      ),
    );
  }

  void _showEditPlotDialog(BuildContext context, WidgetRef ref, dynamic plot) {
    final nameController = TextEditingController(text: plot.name);
    final addressController = TextEditingController(text: plot.address);
    final descController = TextEditingController(text: plot.description);
    final priceController = TextEditingController(text: plot.price?.toString());
    final imageController = TextEditingController(text: plot.imageUrl);
    final latController = TextEditingController(text: plot.latitude?.toString());
    final lngController = TextEditingController(text: plot.longitude?.toString());
    final mapLinkController = TextEditingController(text: plot.googleMapsLink);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Plot'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Plot Name', prefixIcon: Icon(Icons.title))),
              const SizedBox(height: 12),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on))),
              const SizedBox(height: 12),
               Row(
                children: [
                  Expanded(child: TextField(controller: latController, decoration: const InputDecoration(labelText: 'Latitude', hintText: 'e.g. 23.81'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: lngController, decoration: const InputDecoration(labelText: 'Longitude', hintText: 'e.g. 90.41'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: mapLinkController, decoration: const InputDecoration(labelText: 'Google Maps Link', prefixIcon: Icon(Icons.link))),
              const SizedBox(height: 12),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)), maxLines: 2),
              const SizedBox(height: 12),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price', prefixIcon: Icon(Icons.attach_money)), keyboardType: TextInputType.number),
               const SizedBox(height: 12),
              TextField(controller: imageController, decoration: const InputDecoration(labelText: 'Image URL', prefixIcon: Icon(Icons.image))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
               if (nameController.text.isEmpty) return;
              try {
                final price = double.tryParse(priceController.text) ?? 0.0;
                final lat = double.tryParse(latController.text);
                final lng = double.tryParse(lngController.text);
                
                Navigator.pop(context);

               await ref.read(adminControllerProvider).updatePlot(
                      id: plot.id,
                      name: nameController.text,
                      address: addressController.text,
                      description: descController.text,
                      price: price,
                      imageUrl: imageController.text.isNotEmpty ? imageController.text : null,
                      latitude: lat,
                      longitude: lng,
                      googleMapsLink: mapLinkController.text.isNotEmpty ? mapLinkController.text : null,
                    );
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plot updated!')));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Update Plot'),
          ),
        ],
      ),
    );
  }
}

class _AdminRequestsTab extends ConsumerWidget {
  const _AdminRequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep existing implementation but ensure it matches the new style if modified
    // Or just import and use checking the previous implementation logic
    // For safety, I'll copy the existing logic from the view_file for requests
    final requestsAsync = ref.watch(bookingRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Requests')),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) return const Center(child: Text('No requests'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              final user = req['profiles'] ?? {};
              final plot = req['plots'] ?? {};
              final status = req['status'] as String? ?? 'pending';
              Color statusColor = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.person_outline, color: Colors.purple),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(user['name'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text(user['email'] ?? 'No Email', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.grass, size: 14, color: Colors.green),
                                            const SizedBox(width: 4),
                                            Text('Requested Plot: ', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                            Text(plot['name'] ?? 'Unknown Plot', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: statusColor),
                                    ),
                                    child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              if (req['details'] != null) ...[
                                const Divider(height: 24),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Burial Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 8),
                                      _buildDetailRow('Deceased', req['details']['deceased_name']),
                                      _buildDetailRow('Relation', req['details']['relation']),
                                      _buildDetailRow('Burial Date', req['details']['burial_date']),
                                      _buildDetailRow('Notes', req['details']['notes']),
                                    ],
                                  ),
                                ),
                              ],
                              if (status == 'pending') ...[
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => ref.read(adminControllerProvider).rejectRequest(req['id']),
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('Reject'),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                      onPressed: () => ref.read(adminControllerProvider).approveRequest(req['id'], req['plot_id']),
                                      style: FilledButton.styleFrom(backgroundColor: Colors.green),
                                      child: const Text('Approve'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
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

  Widget _buildDetailRow(String label, dynamic value) {
    if (value == null || (value is String && value.isEmpty)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text('$label:', style: const TextStyle(color: Colors.grey, fontSize: 12))),
          Expanded(child: Text(value.toString(), style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

class SoldPlotsScreen extends ConsumerWidget {
  const SoldPlotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soldPlotsAsync = ref.watch(soldPlotsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sold Plots Analysis')),
      backgroundColor: Colors.grey[50],
      body: soldPlotsAsync.when(
        data: (plots) {
          if (plots.isEmpty) {
            return const Center(child: Text('No plots sold yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plots.length,
            itemBuilder: (context, index) {
              final plot = plots[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle, color: Colors.green),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plot.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(plot.address ?? 'No address', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('\$${plot.price}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
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
}
