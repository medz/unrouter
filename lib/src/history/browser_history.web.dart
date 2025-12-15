import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'history.dart';
import 'listener.dart';
import 'location.dart';
import 'update.dart';

/// BrowserHistory 的 web 平台实现。
///
/// 在 web 平台上，BrowserHistory 使用浏览器的 History API
/// (pushState/replaceState/popstate) 来管理导航历史。
///
/// 特性：
/// - 与浏览器 URL 同步
/// - 支持浏览器的前进/后退按钮
/// - 支持书签和分享
/// - 状态对象存储在浏览器历史中
///
/// 示例：
/// ```dart
/// final history = BrowserHistory();
///
/// // 导航到新页面（会更新浏览器 URL）
/// history.push(Location(pathname: '/users'));
///
/// // 浏览器的后退按钮会触发 history 监听器
/// history.listen((update) {
///   print('位置变化: ${update.location.pathname}');
/// });
/// ```
class BrowserHistory extends History {
  /// 创建一个新的 BrowserHistory 实例。
  ///
  /// 会自动从当前浏览器位置初始化，并监听浏览器的导航事件。
  BrowserHistory() {
    // 从当前浏览器位置初始化
    _location = _getLocationFromWindow();
    _action = Action.pop;

    // 监听 popstate 事件（浏览器前进/后退按钮）
    _popStateHandler = _handlePopState.toJS;
    web.window.addEventListener('popstate', _popStateHandler);
  }

  /// 当前位置。
  late Location _location;

  /// 最后一次操作类型。
  late Action _action;

  /// 监听器列表。
  final List<Listener> _listeners = [];

  /// popstate 事件处理器。
  JSFunction? _popStateHandler;

  @override
  Location get location => _location;

  @override
  Action get action => _action;

  @override
  void push(Location location) {
    _action = Action.push;

    // 使用浏览器的 pushState API
    web.window.history.pushState(location.state?.jsify(), '', location.toUrl());

    _location = location;

    // 通知监听器
    _notifyListeners();
  }

  @override
  void replace(Location location) {
    _action = Action.replace;

    // 使用浏览器的 replaceState API
    web.window.history.replaceState(
      location.state?.jsify(),
      '',
      location.toUrl(),
    );

    _location = location;

    // 通知监听器
    _notifyListeners();
  }

  @override
  void go(int delta) {
    if (delta == 0) {
      _notifyListeners();
      return;
    }

    // 使用浏览器的 go API
    web.window.history.go(delta);
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
    return location.toUrl();
  }

  /// 从浏览器窗口获取当前位置。
  Location _getLocationFromWindow() {
    final location = web.window.location;

    // 确保 search 和 hash 为空字符串而不是单独的 '?' 或 '#'
    final search = location.search == '?' ? '' : location.search;
    final hash = location.hash == '#' ? '' : location.hash;

    return Location(
      pathname: location.pathname.isNotEmpty ? location.pathname : '/',
      search: search,
      hash: hash,
      state: web.window.history.state?.dartify(),
    );
  }

  /// 处理 popstate 事件（浏览器前进/后退）。
  void _handlePopState(web.Event event) {
    _action = Action.pop;
    _location = _getLocationFromWindow();

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
  /// 取消 popstate 事件监听。
  void dispose() {
    if (_popStateHandler != null) {
      web.window.removeEventListener('popstate', _popStateHandler);
      _popStateHandler = null;
    }
    _listeners.clear();
  }
}
