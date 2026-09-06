import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'serving_machine_filter.g.dart';

@riverpod
class ServingMachineFilter extends _$ServingMachineFilter {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}
