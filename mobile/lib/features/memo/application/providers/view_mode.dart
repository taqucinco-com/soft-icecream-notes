import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'view_mode.g.dart';

enum NotesViewMode { list, map }

@riverpod
class ViewMode extends _$ViewMode {
  @override
  NotesViewMode build() => NotesViewMode.list;

  void set(NotesViewMode mode) => state = mode;

  void toggle() {
    state = state == NotesViewMode.list ? NotesViewMode.map : NotesViewMode.list;
  }
}
