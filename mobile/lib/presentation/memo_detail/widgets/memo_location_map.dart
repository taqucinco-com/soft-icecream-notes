import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:icecream_log/features/memo/domain/entities/memo.dart';

/// Figma 04フレームの店舗位置表示。座標をFutureで非同期に解決し、
/// 解決までは1:1のスケルトンを表示する。位置情報が無いメモでは
/// その旨のメッセージを表示し、GoogleMapは表示しない（REQ-10）。
class MemoLocationMap extends StatefulWidget {
  const MemoLocationMap({super.key, required this.memo});

  final Memo memo;

  @override
  State<MemoLocationMap> createState() => _MemoLocationMapState();
}

class _MemoLocationMapState extends State<MemoLocationMap> {
  late Future<LatLng?> _locationFuture;

  @override
  void initState() {
    super.initState();
    _locationFuture = _resolveLocation(widget.memo);
  }

  @override
  void didUpdateWidget(covariant MemoLocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memo.id != widget.memo.id) {
      _locationFuture = _resolveLocation(widget.memo);
    }
  }

  Future<LatLng?> _resolveLocation(Memo memo) async {
    if (!memo.hasLocation) return null;
    return LatLng(memo.latitude!, memo.longitude!);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LatLng?>(
      future: _locationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LocationSkeleton();
        }

        final location = snapshot.data;
        if (location == null) {
          return const _NoLocationPlaceholder();
        }

        return AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: location, zoom: 16),
              markers: {
                Marker(markerId: MarkerId(widget.memo.id), position: location),
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              scrollGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
            ),
          ),
        );
      },
    );
  }
}

class _LocationSkeleton extends StatelessWidget {
  const _LocationSkeleton();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _NoLocationPlaceholder extends StatelessWidget {
  const _NoLocationPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            const Text('位置情報がありません'),
          ],
        ),
      ),
    );
  }
}
