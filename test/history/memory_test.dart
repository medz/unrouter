import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/src/history/memory.dart';
import 'package:unrouter/src/history/types.dart';

void main() {
  group('MemoryHistory', () {
    test('默认初始化', () {
      final history = MemoryHistory();

      expect(history.base, '/');
      expect(history.location, '');
      expect(history.state, isNull);
    });

    test('自定义 base', () {
      final history = MemoryHistory('/app');

      expect(history.base, '/app');
    });

    test('push 添加新位置', () {
      final history = MemoryHistory();

      history.push('/users');
      expect(history.location, '/users');

      history.push('/posts', {'from': 'users'});
      expect(history.location, '/posts');
      expect(history.state, {'from': 'users'});
    });

    test('replace 替换当前位置', () {
      final history = MemoryHistory();

      history.push('/users');
      history.replace('/posts');

      expect(history.location, '/posts');
    });

    test('replace 保留 state', () {
      final history = MemoryHistory();

      history.push('/users', {'count': 1});
      history.replace('/posts', {'count': 2});

      expect(history.location, '/posts');
      expect(history.state, {'count': 2});
    });

    test('go 前进和后退', () {
      final history = MemoryHistory();

      history.push('/page1');
      history.push('/page2');
      history.push('/page3');

      expect(history.location, '/page3');

      history.go(-1);
      expect(history.location, '/page2');

      history.go(-1);
      expect(history.location, '/page1');

      history.go(1);
      expect(history.location, '/page2');

      history.go(1);
      expect(history.location, '/page3');
    });

    test('go 超出范围时限制在边界', () {
      final history = MemoryHistory();

      history.push('/page1');
      history.push('/page2');

      // 超出下界
      history.go(-10);
      expect(history.location, '');

      // 超出上界
      history.go(10);
      expect(history.location, '/page2');
    });

    test('back 和 forward', () {
      final history = MemoryHistory();

      history.push('/page1');
      history.push('/page2');

      history.back();
      expect(history.location, '/page1');

      history.forward();
      expect(history.location, '/page2');
    });

    test('listen 接收导航通知', () {
      final history = MemoryHistory();

      String? notifiedTo;
      String? notifiedFrom;
      NavigationDirection? notifiedDirection;
      int? notifiedDelta;

      history.listen((to, from, info) {
        notifiedTo = to;
        notifiedFrom = from;
        notifiedDirection = info.direction;
        notifiedDelta = info.delta;
      });

      history.go(-1);

      expect(notifiedTo, isNotNull);
      expect(notifiedFrom, isNotNull);
      expect(notifiedDirection, isNotNull);
      expect(notifiedDelta, -1);
    });

    test('unlisten 取消监听', () {
      final history = MemoryHistory();

      var callCount = 0;
      final unlisten = history.listen((to, from, info) {
        callCount++;
      });

      history.go(0);
      expect(callCount, 1);

      unlisten();

      history.go(0);
      expect(callCount, 1); // 没有增加
    });

    test('多个监听器', () {
      final history = MemoryHistory();

      var count1 = 0;
      var count2 = 0;

      history.listen((to, from, info) {
        count1++;
      });

      history.listen((to, from, info) {
        count2++;
      });

      history.go(0);

      expect(count1, 1);
      expect(count2, 1);
    });

    test('createHref 生成 URL', () {
      final history = MemoryHistory('/app');

      final href = history.createHref('/users');
      expect(href, '/app/users');
    });

    test('destroy 清理资源', () {
      final history = MemoryHistory();

      history.push('/page1');
      history.push('/page2');

      history.destroy();

      // 验证队列被重置
      expect(history.location, '');
    });

    test('destroy 清除监听器', () {
      final history = MemoryHistory();

      var callCount = 0;
      history.listen((to, from, info) {
        callCount++;
      });

      history.destroy();

      history.go(0);
      expect(callCount, 0);
    });

    test('push 后 go 截断历史', () {
      final history = MemoryHistory();

      history.push('/page1');
      history.push('/page2');
      history.push('/page3');

      history.go(-2); // 回到 page1
      expect(history.location, '/page1');

      history.push('/page4'); // 应该截断 page2 和 page3

      history.go(1); // 应该无法前进到 page2
      expect(history.location, '/page4'); // 仍然在 page4
    });
  });
}
