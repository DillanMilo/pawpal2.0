import '../models/account_entitlement.dart';
import 'supabase_service.dart';

class EntitlementService {
  Future<AccountEntitlement?> getCurrentEntitlement() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return null;

    final response = await SupabaseService.client
        .from('account_entitlements')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return AccountEntitlement.fromJson(response);
  }
}
