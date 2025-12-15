import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'history.dart';
import 'listener.dart';
import 'location.dart';
import 'update.dart';

/// HashHistory 的 web 平台实现。
///
/// 在 web 平台上，HashHistory 使用 URL 的 hash 部分（#）来管理导航历史。
/// 例如：`https://example.com#/users/123?page=1`
///
/// 特性：
/// - 与旧版浏览器兼容（不需要 pushState API）
/// - 不需要服务器端配置（hash 部分不会发送到服务器）
/// - 支持浏览器的前进/后退按钮
/// - 监听 hashchange 事件
///
/// 与 BrowserHistory 相比的优点：
/// - 更简单的服务器配置（不需要处理所有路由）
/// - 与旧版浏览器兼容
///
/// 缺点：
/// - URL 中包含 # 符号，看起来不太美观
/// - SEO 支持较差
///
/// 示例：
/// ```dart
/// final history = HashHistory();
///
/// // 导航到新页面（URL 会变成 https://example.com#/users）
/// history.push(Location(pathname: '/users'));
///
/// // 浏览器的后退按钮会触发 history 监听器
/// history.listen((update) {
///   print('位置变化: ${update.location.pathname}');
/// });
/// ```
class HashHistory extends History {
  /// 创建一个新的 HashHistory 实例。
  ///
  /// 会自动从当前浏览器 hash 初始化，并监听 hashchange 事件。
  HashHistory() {
    // 从当前浏览器 hash 初始化
    _location = _getLocationFromHash();
    _action = Action.pop;

    // 监听 hashchange 事件（浏览器前进/后退按钮或 hash 变化）
    _hashChangeHandler = _handleHashChange.toJS;
    web.window.addEventListener('hashchange', _hashChangeHandler);
  }

  /// 当前位置。
  late Location _location;

  /// 最后一次操作类型。
  late Action _action;

  /// 监听器列表。
  final List<Listener> _listeners = [];

  /// hashchange 事件处理器。
  JSFunction? _hashChangeHandler;

  /// 是否忽略下一个 hashchange 事件。
  ///
  /// 当我们主动调用 push/replace 时，会触发 hashchange 事件。
  /// 但我们已经在 push/replace 中通知了监听器，所以需要忽略这个事件。
  bool _ignoreNextHashChange = false;

  @override
  Location get location => _location;

  @override
  Action get action => _action;

  @override
  void push(Location location) {
    _action = Action.push;

    // 设置浏览器 hash
    _ignoreNextHashChange = true;
    web.window.location.hash = _encodeLocation(location);

    _location = location;

    // 通知监听器
    _notifyListeners();
  }

  @override
  void replace(Location location) {
    _action = Action.replace;

    // 替换浏览器 hash
    _ignoreNextHashChange = true;
    web.window.location.replace('#${_encodeLocation(location)}');

    _location = location;

    // 通知监听器
    _notifyListeners();
  }

  @override
  void go(int delta) {
    if (delta == 0) {
      // delta 为 0，刷新当前位置
      _notifyListeners();
      return;
    }

    // 使用浏览器的 go API
    web.window.history.go(delta);

    // 注意：实际的位置更新会在 hashchange 事件中处理
  }

  @override
  Unlisten listen(Listener listener) {
    _listeners.add(listener);

    // 返回取消订阅函数
    return () {
      _listeners.remove(listener);
    };
  }

  @override
  String createHref(Location location) {
    return '#${_encodeLocation(location)}';
  }

  /// 从浏览器 hash 获取当前位置。
  Location _getLocationFromHash() {
    // 获取 hash 部分（去掉前导的 #）
    String hash = web.window.location.hash;
    if (hash.startsWith('#')) {
      hash = hash.substring(1);
    }

    // 如果 hash 为空，默认为根路径
    if (hash.isEmpty) {
      return Location(pathname: '/');
    }

    // 解析 hash 中的路径
    return Location.fromPath(hash);
  }

  /// 将 Location 对象编码为 hash 字符串。
  String _encodeLocation(Location location) {
    return location.toUrl();
  }

  /// 处理 hashchange 事件。
  void _handleHashChange(web.Event event) {
    // 如果是我们主动触发的，忽略
    if (_ignoreNextHashChange) {
      _ignoreNextHashChange = false;
      return;
    }

    _action = Action.pop;
    _location = _getLocationFromHash();

    // 通知监听器
    _notifyListeners();
  }

  /// 通知所有监听器位置已更改。
  void _notifyListeners() {
    final update = Update(action: _action, location: _location);

    // 复制监听器列表以避免在迭代时修改
    final listeners = List<Listener>.from(_listeners);

    for (final listener in listeners) {
      listener(update);
    }
  }

  /// 释放资源。
  ///
  /// 取消 hashchange 事件监听。
  void dispose() {
    if (_hashChangeHandler != null) {
      web.window.removeEventListener('hashchange', _hashChangeHandler);
      _hashChangeHandler = null;
    }
    _listeners.clear();
  }
}
