import 'package:cemetry/core/models/plot.dart';
import 'package:cemetry/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final plotsProvider = FutureProvider<List<Plot>>((ref) async {
  final response = await supabase
      .from('plots')
      .select()
      .order('created_at', ascending: false);
  return (response as List).map((e) => Plot.fromMap(e)).toList();
});

final availablePlotsProvider = FutureProvider<List<Plot>>((ref) async {
  final response = await supabase
      .from('plots')
      .select()
      .eq('status', 'available')
      .order('created_at', ascending: false);
  return (response as List).map((e) => Plot.fromMap(e)).toList();
});

final soldPlotsProvider = FutureProvider<List<Plot>>((ref) async {
  final response = await supabase
      .from('plots')
      .select()
      .eq('status', 'sold')
      .order('created_at', ascending: false);
  return (response as List).map((e) => Plot.fromMap(e)).toList();
});

final adminControllerProvider = Provider((ref) => AdminController(ref));

class AdminController {
  final Ref _ref;

  AdminController(this._ref);

  Future<void> addPlot({
    required String name,
    required String description,
    required String address,
    required double price,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? googleMapsLink,
  }) async {
    await supabase.from('plots').insert({
      'name': name,
      'description': description,
      'address': address,
      'price': price,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'google_maps_link': googleMapsLink,
    });
    _ref.invalidate(plotsProvider);
    _ref.invalidate(availablePlotsProvider);
    _ref.invalidate(soldPlotsProvider);
  }

  Future<void> updatePlot({
    required String id,
    required String name,
    required String description,
    required String address,
    required double price,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? googleMapsLink,
  }) async {
    await supabase.from('plots').update({
      'name': name,
      'description': description,
      'address': address,
      'price': price,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'google_maps_link': googleMapsLink,
    }).eq('id', id);
    _ref.invalidate(plotsProvider);
    _ref.invalidate(availablePlotsProvider);
    _ref.invalidate(soldPlotsProvider);
  }

  Future<void> approveRequest(String requestId, String plotId) async {
    // 1. Update request status to 'approved'
    await supabase.from('requests').update({'status': 'approved'}).eq('id', requestId);
    
    // 2. Update plot status to 'sold'
    await supabase.from('plots').update({'status': 'sold'}).eq('id', plotId);
    
    // 3. Invalidate providers to refresh UI
    _ref.invalidate(bookingRequestsProvider);
    _ref.invalidate(plotsProvider);
    _ref.invalidate(availablePlotsProvider);
    _ref.invalidate(soldPlotsProvider);
  }

  Future<void> rejectRequest(String requestId) async {
    await supabase.from('requests').update({'status': 'rejected'}).eq('id', requestId);
    _ref.invalidate(bookingRequestsProvider);
  }

  Future<void> bookPlotDirectly({required String plotId}) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // 1. Create an approved request (admin booking)
    await supabase.from('requests').insert({
      'user_id': user.id,
      'plot_id': plotId,
      'status': 'approved',
      'details': {'type': 'admin_direct_booking'},
    });

    // 2. Mark plot as sold
    await supabase.from('plots').update({'status': 'sold'}).eq('id', plotId);

    // 3. Invalidate providers
    _ref.invalidate(plotsProvider);
    _ref.invalidate(availablePlotsProvider);
    _ref.invalidate(soldPlotsProvider);
    _ref.invalidate(bookingRequestsProvider);
  }
}

final bookingRequestsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  // Fetch requesting user details and plot details joined
  final data = await supabase
      .from('requests')
      .select('*, profiles:user_id(name, email, mobile), plots:plot_id(name, price)')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data);
});
