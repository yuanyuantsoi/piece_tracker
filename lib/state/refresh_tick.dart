// lib/state/refresh_tick.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// v1.0.1：sqflite 无 watch，因此用 tick 作为“刷新信号”
/// 约定：任何写入成功后 tick++
/// 所有读 provider 都 watch 这个 tick，以触发重新 query
final refreshTickProvider = StateProvider<int>((ref) => 0);
