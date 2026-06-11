import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://zajzfbvduhewrvaetyuk.supabase.co';
  static const String publishableKey = 'sb_publishable_X2JnnRYovgj3D7pDbhfN-A_VWSDIXEt';

  static Future<void> init() async {
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }
}

SupabaseClient get supabase => Supabase.instance.client;
