import 'update.dart';

/// 历史变化监听器的回调函数类型。
///
/// 当历史位置发生变化时，此函数会被调用，并传入一个 [Update] 对象，
/// 其中包含导致变化的操作类型和新的位置信息。
///
/// 示例：
/// ```dart
/// void myListener(Update update) {
///   print('位置已更新: ${update.location.pathname}');
///   print('操作类型: ${update.action}');
/// }
/// ```
typedef Listener = void Function(Update update);

/// 取消监听器订阅的回调函数类型。
///
/// 调用此函数将停止接收历史变化通知。
///
/// 示例：
/// ```dart
/// final unlisten = history.listen(myListener);
/// // ... 稍后
/// unlisten(); // 停止监听
/// ```
typedef Unlisten = void Function();
