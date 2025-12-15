import 'package:flutter/services.dart';
import 'package:unrouter/unrouter.dart';

/// 这个示例展示了如何使用 BrowserHistory。
///
/// BrowserHistory 在不同平台上有不同的行为：
/// - 在 web 平台：使用浏览器的 History API (pushState/replaceState)
/// - 在非 web 平台（iOS、Android 等）：使用内存历史记录
///
/// 注意：这个示例在非 web 平台上运行，所以会使用内存历史记录。
/// 要在 web 平台上测试，请使用 `flutter run -d chrome` 运行。
void main() {
  // 1. 创建 BrowserHistory
  print('=== 创建 Browser History ===');
  final history = BrowserHistory();
  print('当前位置: ${history.location.pathname}');
  print('平台说明: 在 web 平台会同步浏览器 URL，在非 web 平台使用内存历史');
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
  print('在 web 平台: 浏览器 URL 会变成 /users');
  print('在非 web 平台: 仅在内存中记录');
  history.push(Location(pathname: '/users'));

  history.push(Location.fromPath('/users/123?tab=profile#bio'));

  // 4. 替换当前位置
  print('=== 替换当前位置 ===');
  print('在 web 平台: 使用 replaceState，不会在历史堆栈中增加条目');
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
  final url = history.createHref(
    Location(pathname: '/products/123', search: '?color=red', hash: '#reviews'),
  );
  print('生成的 URL: $url');
  print('');

  // 8. 平台差异说明
  print('=== 平台差异 ===');
  print('Web 平台特性：');
  print('  - URL 与浏览器地址栏同步');
  print('  - 支持浏览器的前进/后退按钮');
  print('  - 支持书签和分享');
  print('  - 需要服务器配置以处理所有路由');
  print('');
  print('非 Web 平台特性：');
  print('  - 使用内存历史记录');
  print('  - 与 MemoryHistory 行为相同');
  print('  - 适合原生应用开发');
  print('');

  // 9. 使用建议
  print('=== 使用建议 ===');
  print('BrowserHistory 适用于：');
  print('  - 需要 SEO 优化的 web 应用');
  print('  - 需要美观 URL 的项目（无 # 符号）');
  print('  - 可以控制服务器配置的项目');
  print('');
  print('如果不需要 SEO 或服务器配置复杂，考虑使用 HashHistory');
}
