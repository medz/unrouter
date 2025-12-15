import 'history.dart';
import 'listener.dart';
import 'location.dart';
import 'update.dart';

/// 在内存中管理历史记录的 History 实现。
///
/// MemoryHistory 将历史堆栈保存在内存中的数组里，不与浏览器 URL 交互。
/// 这使得它非常适合：
/// - 原生应用（iOS、Android 等）
/// - 服务器端渲染
/// - 自动化测试
/// - 不需要 URL 同步的场景
///
/// 示例：
/// ```dart
/// // 从单个根路径开始
/// final history = MemoryHistory();
///
/// // 从多个条目开始
/// final history = MemoryHistory(
///   initialEntries: [
///     Location(pathname: '/home'),
///     Location(pathname: '/users'),
///     Location(pathname: '/users/123'),
///   ],
///   initialIndex: 2, // 从 '/users/123' 开始
/// );
///
/// print(history.location.pathname); // '/users/123'
/// history.back();
/// print(history.location.pathname); // '/users'
/// ```
class MemoryHistory extends History {
  /// 创建一个新的 MemoryHistory 实例。
  ///
  /// [initialEntries] 是初始的历史条目列表。如果为空，默认为单个根路径 '/'。
  /// [initialIndex] 是起始的历史索引。默认为最后一个条目的索引。
  ///
  /// 示例：
  /// ```dart
  /// // 默认配置
  /// final history1 = MemoryHistory();
  ///
  /// // 自定义初始条目
  /// final history2 = MemoryHistory(
  ///   initialEntries: [
  ///     Location(pathname: '/home'),
  ///     Location.fromPath('/users?page=1'),
  ///   ],
  /// );
  ///
  /// // 指定初始索引
  /// final history3 = MemoryHistory(
  ///   initialEntries: [
  ///     Location(pathname: '/a'),
  ///     Location(pathname: '/b'),
  ///     Location(pathname: '/c'),
  ///   ],
  ///   initialIndex: 1, // 从 '/b' 开始
  /// );
  /// ```
  MemoryHistory({
    Iterable<Location>? initialEntries,
    int? initialIndex,
  })  : _entries = initialEntries?.toList() ?? [Location(pathname: '/')],
        _index = initialIndex ?? (initialEntries?.length ?? 1) - 1 {
    // 验证初始索引有效
    if (_index < 0 || _index >= _entries.length) {
      throw RangeError('initialIndex must be between 0 and ${_entries.length - 1}');
    }
  }

  /// 历史条目列表。
  final List<Location> _entries;

  /// 当前历史索引。
  int _index;

  /// 最后一次操作类型。
  Action _action = Action.pop;

  /// 监听器列表。
  final List<Listener> _listeners = [];

  @override
  Location get location => _entries[_index];

  @override
  Action get action => _action;

  /// 获取历史堆栈的大小（用于调试和测试）。
  int get length => _entries.length;

  /// 获取当前索引（用于调试和测试）。
  int get index => _index;

  @override
  void push(Location location) {
    _action = Action.push;

    // 截断当前索引后的所有条目
    _index++;
    if (_index < _entries.length) {
      _entries.removeRange(_index, _entries.length);
    }

    // 添加新条目
    _entries.add(location);

    // 通知监听器
    _notifyListeners();
  }

  @override
  void replace(Location location) {
    _action = Action.replace;

    // 替换当前条目
    _entries[_index] = location;

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

    final nextIndex = _index + delta;

    // 检查边界
    if (nextIndex < 0 || nextIndex >= _entries.length) {
      // 超出边界，不执行任何操作
      return;
    }

    _action = Action.pop;
    _index = nextIndex;

    // 通知监听器
    _notifyListeners();
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

  /// 通知所有监听器位置已更改。
  void _notifyListeners() {
    final update = Update(action: _action, location: location);

    // 复制监听器列表以避免在迭代时修改
    final listeners = List<Listener>.from(_listeners);

    for (final listener in listeners) {
      listener(update);
    }
  }
}
