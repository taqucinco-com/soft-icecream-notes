import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:icecream_log/features/image/data/exif_service_impl.dart';
import 'package:icecream_log/features/image/domain/repositories/exif_service.dart';

part 'generated/repository_providers.g.dart';

/// アプリ全体で使い回すシングルトンとして扱うため`keepAlive: true`とする。
@Riverpod(keepAlive: true)
ExifService exifService(Ref ref) => const ExifServiceImpl();
