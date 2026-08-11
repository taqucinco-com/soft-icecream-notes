class TasteRating {
  const TasteRating({
    required this.mouthfeel,
    required this.ingredientUse,
    required this.uniqueness,
    required this.flavorQuality,
    required this.temperatureControl,
  }) : assert(mouthfeel >= 1 && mouthfeel <= 5),
       assert(ingredientUse >= 1 && ingredientUse <= 5),
       assert(uniqueness >= 1 && uniqueness <= 5),
       assert(flavorQuality >= 1 && flavorQuality <= 5),
       assert(temperatureControl >= 1 && temperatureControl <= 5);

  final int mouthfeel;
  final int ingredientUse;
  final int uniqueness;
  final int flavorQuality;
  final int temperatureControl;

  TasteRating copyWith({
    int? mouthfeel,
    int? ingredientUse,
    int? uniqueness,
    int? flavorQuality,
    int? temperatureControl,
  }) {
    return TasteRating(
      mouthfeel: mouthfeel ?? this.mouthfeel,
      ingredientUse: ingredientUse ?? this.ingredientUse,
      uniqueness: uniqueness ?? this.uniqueness,
      flavorQuality: flavorQuality ?? this.flavorQuality,
      temperatureControl: temperatureControl ?? this.temperatureControl,
    );
  }
}
