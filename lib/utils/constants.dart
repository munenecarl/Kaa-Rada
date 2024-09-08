// lib/utils/constants.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
final String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
