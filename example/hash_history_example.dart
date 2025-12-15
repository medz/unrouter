import 'package:unrouter/unrouter.dart';

/// 这个示例展示了如何使用 HashHistory。
///
/// HashHistory（也称为 FragmentHistory）在不同平台上有不同的行为：
/// - 在 web 平台：使用 URL 的 hash 部分（#），例如 https://example.com#/users
/// - 在非 web 平台（iOS、Android 等）：使用内存历史记录
///
/// 注意：这个示例在非 web 平台上运行，所以会使用内存历史记录。
/// 要在 web 平台上测试，请使用 `flutter run -d chrome` 运行。
void main() {
  // 1. 创建 HashHistory
  print('=== 创建 Hash History ===');
  final history = HashHistory();
  print('当前位置: ${history.location.pathname}');
  print('平台说明: 在 web 平台会使用 URL hash，在非 web 平台使用内存历史');
  print('');

  // 2. 监听历史变化
  print('=== 设置监听器 ===');
  history.listen((update) {
    print('位置已更新:');
    print('  - 操作: ${update.action}');
    print('  - 路径: ${update.location.pathname}');
    if (update.location.search.isNotEmpty) {
      print('  - 查询: ${update.location.search}');
    }
    if (update.location.hash.isNotEmpty) {
      print('  - 哈希: ${update.location.hash}');
    }
    if (update.location.state != null) {
      print('  - 状态: ${update.location.state}');
    }
    print('');
  });

  // 3. 推入新位置
  print('=== 推入新位置 ===');
  print('在 web 平台: 浏览器 URL 会变成 https://example.com#/users');
  print('在非 web 平台: 仅在内存中记录');
  history.push(Location(pathname: '/users'));

  history.push(Location.fromPath('/users/123?tab=profile'));

  // 4. 替换当前位置
  print('=== 替换当前位置 ===');
  print('在 web 平台: 替换当前 hash，不会在历史堆栈中增加条目');
  history.replace(Location.fromPath('/users/456', state: {'updated': true}));

  // 5. 后退
  print('=== 后退一步 ===');
  print('在 web 平台: 触发浏览器的后退按钮效果');
  history.back();

  // 6. 前进
  print('=== 前进一步 ===');
  print('在 web 平台: 触发浏览器的前进按钮效果');
  history.forward();

  // 7. 生成 URL
  print('=== 生成 URL ===');
  final url = history.createHref(Location(
    pathname: '/products/123',
    search: '?color=red',
  ));
  print('生成的 URL: $url');
  print('注意：HashHistory 会在 URL 前加上 # 符号');
  print('');

  // 8. Hash 嵌套示例
  print('=== Hash 嵌套 ===');
  print('HashHistory 可以在路径中包含自己的 hash：');
  history.push(Location(
    pathname: '/docs/api',
    search: '?version=2',
    hash: '#methods',
  ));
  final nestedUrl = history.createHref(history.location);
  print('生成的嵌套 URL: $nestedUrl');
  print('在 web 平台会是: https://example.com#/docs/api?version=2#methods');
  print('');

  // 9. 平台差异说明
  print('=== 平台差异 ===');
  print('Web 平台特性：');
  print('  - URL 使用 hash 部分（# 后面）');
  print('  - 不需要服务器端配置');
  print('  - 与旧版浏览器兼容');
  print('  - 支持浏览器的前进/后退按钮');
  print('  - SEO 支持较差');
  print('');
  print('非 Web 平台特性：');
  print('  - 使用内存历史记录');
  print('  - 与 MemoryHistory 行为相同');
  print('  - 适合原生应用开发');
  print('');

  // 10. 使用建议
  print('=== 使用建议 ===');
  print('HashHistory 适用于：');
  print('  - 不需要 SEO 优化的单页应用');
  print('  - 服务器配置简单的项目');
  print('  - 需要兼容旧版浏览器的项目');
  print('  - 静态托管的应用（GitHub Pages 等）');
  print('');
  print('HashHistory vs BrowserHistory:');
  print('  - HashHistory: 简单，无需服务器配置，但 URL 不美观');
  print('  - BrowserHistory: URL 美观，SEO 友好，但需要服务器配置');
}
