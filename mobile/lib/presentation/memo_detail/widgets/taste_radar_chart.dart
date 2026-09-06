import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:icecream_log/features/memo/domain/entities/taste_rating.dart';

const _axisTitles = ['口当たり', '素材', '個性的', 'フレーバー', '温度'];

/// Figma 04フレームの「味の5軸評価」。未評価時（[rating]がnull）はプレースホルダーを表示する（REQ-7）。
class TasteRadarChart extends StatelessWidget {
  const TasteRadarChart({super.key, required this.rating});

  final TasteRating? rating;

  @override
  Widget build(BuildContext context) {
    final rating = this.rating;
    if (rating == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('まだ評価が入力されていません')),
      );
    }

    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 220,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 5,
          ticksTextStyle: const TextStyle(color: Colors.transparent),
          radarBorderData: BorderSide(color: Theme.of(context).dividerColor),
          gridBorderData: BorderSide(color: Theme.of(context).dividerColor),
          tickBorderData: BorderSide(color: Theme.of(context).dividerColor),
          titleTextStyle: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontSize: 11),
          getTitle: (index, angle) => RadarChartTitle(text: _axisTitles[index]),
          dataSets: [
            RadarDataSet(
              fillColor: color.withValues(alpha: 0.2),
              borderColor: color,
              entryRadius: 2,
              dataEntries: [
                RadarEntry(value: rating.mouthfeel.toDouble()),
                RadarEntry(value: rating.ingredientUse.toDouble()),
                RadarEntry(value: rating.uniqueness.toDouble()),
                RadarEntry(value: rating.flavorQuality.toDouble()),
                RadarEntry(value: rating.temperatureControl.toDouble()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
