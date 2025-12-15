import 'location.dart';

/// 表示历史堆栈中的操作类型。
///
/// 这个枚举描述了导致当前位置变化的操作。
enum Action {
  /// 表示向历史堆栈中推入新条目。
  ///
  /// 对应 `history.push()` 操作。
  /// 会增加历史堆栈的大小，用户可以通过后退按钮返回到之前的位置。
  push,

  /// 表示替换当前历史条目。
  ///
  /// 对应 `history.replace()` 操作。
  /// 不会增加历史堆栈的大小，当前条目被新条目替换。
  replace,

  /// 表示在历史堆栈中后退或前进。
  ///
  /// 对应 `history.back()`, `history.forward()` 或 `history.go()` 操作。
  /// 这是用户通过浏览器按钮或代码导航到历史堆栈中已存在的位置。
  pop,
}

/// 表示历史状态的更新。
///
/// 当历史位置发生变化时，监听器会收到一个 Update 对象，
/// 其中包含导致变化的操作类型和新的位置。
class Update {
  /// 创建一个新的 Update 实例。
  ///
  /// [action] 是导致此更新的操作类型。
  /// [location] 是更新后的新位置。
  const Update({
    required this.action,
    required this.location,
  });

  /// 导致此更新的操作类型。
  final Action action;

  /// 更新后的新位置。
  final Location location;

  @override
  String toString() {
    return 'Update(action: $action, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Update &&
        other.action == action &&
        other.location == location;
  }

  @override
  int get hashCode => Object.hash(action, location);
}
