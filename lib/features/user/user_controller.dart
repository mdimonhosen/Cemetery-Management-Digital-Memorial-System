import 'package:cemetry/features/admin/admin_controller.dart' show bookingRequestsProvider;
import 'package:cemetry/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// userPlotsProvider removed. Using plotsProvider from admin_controller instead.

final userRequestsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  
  // Fetch requests joined with plot details
  final response = await supabase
      .from('requests')
      .select('*, plots(name, price)')
      .eq('user_id', user.id)
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

final userControllerProvider = Provider((ref) => UserController(ref));

class UserController {
  final Ref _ref;

  UserController(this._ref);

  Future<void> makeRequest(String plotId, Map<String, dynamic> details) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Check if a request already exists for this plot by this user
    final existing = await supabase
        .from('requests')
        .select()
        .eq('user_id', user.id)
        .eq('plot_id', plotId)
        .or('status.eq.pending,status.eq.approved')
        .maybeSingle();

    if (existing != null) {
      throw Exception('You already have a request for this plot.');
    }

    await supabase.from('requests').insert({
      'user_id': user.id,
      'plot_id': plotId,
      'status': 'pending',
      'details': details,
    });
    _ref.invalidate(userRequestsProvider);
    _ref.invalidate(bookingRequestsProvider); // Keep admin in sync
  }
}
