/// Unrouter - 一个简单、灵活的 Flutter 路由库
///
/// Unrouter 提供了一个不依赖于 MaterialApp、CupertinoApp 或 WidgetsApp 的
/// 独立路由解决方案，同时也可以与这些 Widget 无缝集成。
///
/// 主要特性：
/// - 独立的 History 管理，支持多种历史模式
/// - 声明式路由配置
/// - 嵌套路由和命名 outlet
/// - 与 Flutter Navigator 2.0 兼容
library unrouter;

// History API
export 'src/history/history.dart' show History;
export 'src/history/listener.dart' show Listener, Unlisten;
export 'src/history/location.dart' show Location;
export 'src/history/memory_history.dart' show MemoryHistory;
export 'src/history/update.dart' show Action, Update;
