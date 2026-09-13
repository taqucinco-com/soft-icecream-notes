import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// メモに紐づく店舗の位置をGoogleMap上にピンで表示するWidget。
///
/// [GoogleMap]のプラットフォームビュー生成（[GoogleMap.onMapCreated]）が完了するまでは
/// 1:1 aspectのSkeltonScreenを表示し、完了後に実際の地図描画に切り替える。
class StoreLocationMap extends StatefulWidget {
  const StoreLocationMap({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  State<StoreLocationMap> createState() => _StoreLocationMapState();
}

class _StoreLocationMapState extends State<StoreLocationMap> {
  bool _mapReady = false;

  @override
  Widget build(BuildContext context) {
    final target = LatLng(widget.latitude, widget.longitude);
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: target, zoom: 16),
              markers: {
                Marker(markerId: const MarkerId('store'), position: target),
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              onMapCreated: (_) => setState(() => _mapReady = true),
            ),
            if (!_mapReady)
              Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
          ],
        ),
      ),
    );
  }
}
