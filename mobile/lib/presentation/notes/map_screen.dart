import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:icecream_log/features/memo/application/providers/memo_list.dart';
import 'package:icecream_log/features/memo/domain/entities/memo.dart';
import 'package:icecream_log/presentation/format/date_format.dart';

// TODO: 位置情報を持つメモが無い場合の初期表示地点。今は仮の座標を使う。
const _defaultCenter = LatLng(45.521563, -122.677433);

class MapScreen extends HookConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memosAsync = ref.watch(memoListProvider);
    final controller = useMemoized(() => Completer<GoogleMapController>());

    void showMessage(String message) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> zoomIn() async {
      final mapController = await controller.future;
      unawaited(mapController.animateCamera(CameraUpdate.zoomIn()));
    }

    Future<void> zoomOut() async {
      final mapController = await controller.future;
      unawaited(mapController.animateCamera(CameraUpdate.zoomOut()));
    }

    Future<Position?> determinePosition() async {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        showMessage('位置情報サービスが無効になっています');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == .denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == .denied || permission == .deniedForever) {
        showMessage('位置情報の権限が許可されていません');
        return null;
      }

      return Geolocator.getCurrentPosition();
    }

    Future<void> moveToCurrentLocation() async {
      final position = await determinePosition();
      if (position == null || !context.mounted) return;
      final mapController = await controller.future;
      unawaited(
        mapController.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        ),
      );
    }

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
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                onMapCreated: controller.complete,
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
            Positioned(
              top: 16,
              right: 16,
              child: _MapControls(
                onZoomIn: zoomIn,
                onZoomOut: zoomOut,
                onMoveToCurrentLocation: moveToCurrentLocation,
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

class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMoveToCurrentLocation,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onMoveToCurrentLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MapButtonGroup(
          children: [
            _MapIconButton(
              icon: Icons.add,
              tooltip: 'ズームイン',
              onPressed: onZoomIn,
            ),
            const Divider(height: 1),
            _MapIconButton(
              icon: Icons.remove,
              tooltip: 'ズームアウト',
              onPressed: onZoomOut,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MapButtonGroup(
          children: [
            _MapIconButton(
              icon: Icons.my_location,
              tooltip: '現在地へ移動',
              onPressed: onMoveToCurrentLocation,
            ),
          ],
        ),
      ],
    );
  }
}

class _MapButtonGroup extends StatelessWidget {
  const _MapButtonGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: onPressed);
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
                        if (memo.servingMachine != null) memo.servingMachine!,
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
