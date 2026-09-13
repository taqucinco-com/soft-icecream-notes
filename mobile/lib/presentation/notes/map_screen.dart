import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:icecream_log/features/memo/application/providers/memo_list.dart';
import 'package:icecream_log/features/memo/domain/entities/memo.dart';
import 'package:icecream_log/presentation/format/date_format.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  // TODO: 位置情報を持つメモが無い場合の初期表示地点。今は仮の座標を使う。
  static const _defaultCenter = LatLng(45.521563, -122.677433);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memosAsync = ref.watch(memoListProvider);
    return memosAsync.when(
      data: (memos) {
        final pinned = memos.where((memo) => memo.hasLocation).toList();
        return Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _defaultCenter,
                  zoom: 14,
                ),
                markers: {
                  for (final memo in pinned)
                    Marker(
                      markerId: MarkerId(memo.id),
                      position: LatLng(memo.latitude!, memo.longitude!),
                      onTap: () => context.push('/notes/detail/${memo.id}'),
                    ),
                },
              ),
            ),
            if (pinned.isNotEmpty)
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: _PreviewCard(
                  memo: pinned.first,
                  onTap: () => context.push('/notes/detail/${pinned.first.id}'),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('読み込みに失敗しました: $error')),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.memo, required this.onTap});

  final Memo memo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 52,
                  height: 52,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.icecream_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memo.storeName ?? '店名未設定',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (memo.eatenDate != null) formatYmd(memo.eatenDate!),
                        if (memo.servingMachines.isNotEmpty)
                          memo.servingMachines.join('、'),
                      ].join(' ・ '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
