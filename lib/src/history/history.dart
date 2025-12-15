import 'location.dart';
import 'listener.dart';
import 'update.dart';

/// History 管理应用的导航历史记录。
///
/// History 提供了一个统一的接口来管理不同环境下的导航历史，
/// 包括内存历史（用于测试和原生应用）、浏览器历史和哈希历史。
///
/// 所有的 History 实现都提供相同的 API，使得可以在不同环境间
/// 无缝切换，而无需修改应用代码。
abstract class History {
  /// 获取当前位置。
  Location get location;

  /// 获取最后一次导致位置变化的操作类型。
  Action get action;

  /// 向历史堆栈中推入一个新位置。
  ///
  /// [location] 是要推入的位置对象。
  ///
  /// 此操作会增加历史堆栈的大小，用户可以通过后退按钮返回。
  ///
  /// 示例：
  /// ```dart
  /// history.push(Location(pathname: '/users/123'));
  /// history.push(Location(
  ///   pathname: '/users/123',
  ///   search: '?page=1',
  ///   state: {'from': 'home'},
  /// ));
  /// ```
  void push(Location location);

  /// 替换当前历史条目。
  ///
  /// [location] 是替换后的位置对象。
  ///
  /// 此操作不会增加历史堆栈的大小，当前条目被新条目替换。
  /// 用户无法通过后退按钮返回到被替换的位置。
  ///
  /// 示例：
  /// ```dart
  /// history.replace(Location(pathname: '/users/456'));
  /// history.replace(Location(
  ///   pathname: '/users/456',
  ///   state: {'updated': true},
  /// ));
  /// ```
  void replace(Location location);

  /// 在历史堆栈中前进或后退指定步数。
  ///
  /// [delta] 是要移动的步数：
  /// - 负数表示后退（例如 -1 表示后退一步）
  /// - 正数表示前进（例如 1 表示前进一步）
  /// - 0 会刷新当前页面（在某些实现中）
  ///
  /// 如果 [delta] 超出历史堆栈的范围，此方法可能不执行任何操作。
  ///
  /// 示例：
  /// ```dart
  /// history.go(-1); // 后退一步
  /// history.go(2);  // 前进两步
  /// history.go(0);  // 刷新
  /// ```
  void go(int delta);

  /// 在历史堆栈中后退一步。
  ///
  /// 等同于 `go(-1)`。
  ///
  /// 示例：
  /// ```dart
  /// history.back();
  /// ```
  void back() => go(-1);

  /// 在历史堆栈中前进一步。
  ///
  /// 等同于 `go(1)`。
  ///
  /// 示例：
  /// ```dart
  /// history.forward();
  /// ```
  void forward() => go(1);

  /// 监听历史位置的变化。
  ///
  /// [listener] 是一个回调函数，当位置发生变化时会被调用。
  ///
  /// 返回一个取消订阅的函数，调用它将停止接收变化通知。
  ///
  /// 示例：
  /// ```dart
  /// final unlisten = history.listen((update) {
  ///   print('新位置: ${update.location.pathname}');
  ///   print('操作: ${update.action}');
  /// });
  ///
  /// // 稍后取消监听
  /// unlisten();
  /// ```
  Unlisten listen(Listener listener);

  /// 将位置转换为 URL 字符串。
  ///
  /// [location] 要转换的位置对象。
  ///
  /// 返回一个表示该位置的 URL 字符串。不同的 History 实现
  /// 可能会返回不同格式的 URL。
  ///
  /// 示例：
  /// ```dart
  /// final url = history.createHref(Location(
  ///   pathname: '/users/123',
  ///   search: '?page=1',
  /// ));
  /// print(url); // "/users/123?page=1"
  /// ```
  String createHref(Location location);
}
