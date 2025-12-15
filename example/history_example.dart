import 'package:unrouter/unrouter.dart';

/// 这个示例展示了如何使用 unrouter 的 History API。
void main() {
  // 1. 创建一个 MemoryHistory 实例
  print('=== 创建 Memory History ===');
  final history = MemoryHistory(
    initialEntries: [Location(pathname: '/home')],
  );
  print('当前位置: ${history.location.pathname}');
  print('');

  // 2. 监听历史变化
  print('=== 设置监听器 ===');
  history.listen((update) {
    print('位置已更新:');
    print('  - 操作: ${update.action}');
    print('  - 路径: ${update.location.pathname}');
    print('  - 查询: ${update.location.search}');
    print('  - 哈希: ${update.location.hash}');
    if (update.location.state != null) {
      print('  - 状态: ${update.location.state}');
    }
    print('');
  });

  // 3. 推入新位置
  print('=== 推入新位置 ===');
  history.push(Location(pathname: '/users'));
  history.push(Location.fromPath('/users/123?tab=profile#bio', state: {'userId': 123}));

  // 4. 替换当前位置
  print('=== 替换当前位置 ===');
  history.replace(Location.fromPath('/users/456', state: {'userId': 456, 'updated': true}));

  // 5. 后退
  print('=== 后退一步 ===');
  history.back();

  // 6. 前进
  print('=== 前进一步 ===');
  history.forward();

  // 7. 跳转到指定位置
  print('=== 后退两步 ===');
  history.go(-2);

  // 8. 显示历史堆栈信息
  print('=== 历史堆栈信息 ===');
  print('堆栈大小: ${history.length}');
  print('当前索引: ${history.index}');
  print('当前位置: ${history.location.toUrl()}');

  // 9. 使用 Location 对象
  print('\n=== 使用 Location 对象 ===');
  history.push(Location(
    pathname: '/settings',
    search: '?section=privacy',
    hash: '#notifications',
    state: {'from': 'profile'},
  ));

  // 10. 生成 URL
  print('\n=== 生成 URL ===');
  final url = history.createHref(Location(
    pathname: '/products/123',
    search: '?color=red&size=large',
    hash: '#reviews',
  ));
  print('生成的 URL: $url');

  // 11. 演示分支导航
  print('\n=== 演示分支导航 ===');
  final history2 = MemoryHistory(
    initialEntries: [
      Location(pathname: '/a'),
      Location(pathname: '/b'),
      Location(pathname: '/c'),
      Location(pathname: '/d'),
    ],
  );
  print('初始位置: ${history2.location.pathname} (索引: ${history2.index})');

  history2.go(-2); // 回到 /b
  print('后退到: ${history2.location.pathname} (索引: ${history2.index})');

  history2.push(Location(pathname: '/e')); // 从 /b 推入 /e
  print('推入新位置: ${history2.location.pathname}');
  print('堆栈大小: ${history2.length}'); // /c 和 /d 被截断

  history2.forward(); // 尝试前进
  print('尝试前进: ${history2.location.pathname}'); // 仍然是 /e
}
