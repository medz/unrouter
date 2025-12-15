import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  group('BrowserHistory', () {
    group('初始化', () {
      test('默认从单个根路径开始', () {
        final history = BrowserHistory();

        expect(history.location.pathname, '/');
        expect(history.location.search, '');
        expect(history.location.hash, '');
        expect(history.action, Action.pop);
      });

      test('可以使用初始条目初始化', () {
        final history = BrowserHistory(
          initialEntries: [
            Location(pathname: '/home'),
            Location(pathname: '/users'),
          ],
        );

        expect(history.location.pathname, '/users');
        expect(history.index, 1);
        expect(history.length, 2);
      });

      test('可以指定初始索引', () {
        final history = BrowserHistory(
          initialEntries: [
            Location(pathname: '/a'),
            Location(pathname: '/b'),
            Location(pathname: '/c'),
          ],
          initialIndex: 1,
        );

        expect(history.location.pathname, '/b');
        expect(history.index, 1);
      });
    });

    group('push', () {
      test('添加新条目并更新位置', () {
        final history = BrowserHistory();

        history.push(Location(pathname: '/users'));

        expect(history.location.pathname, '/users');
        expect(history.action, Action.push);
        expect(history.length, 2);
      });

      test('触发监听器', () {
        final history = BrowserHistory();
        Update? lastUpdate;

        history.listen((update) {
          lastUpdate = update;
        });

        history.push(Location(pathname: '/users'));

        expect(lastUpdate, isNotNull);
        expect(lastUpdate!.action, Action.push);
        expect(lastUpdate!.location.pathname, '/users');
      });
    });

    group('replace', () {
      test('替换当前条目', () {
        final history = BrowserHistory();
        history.push(Location(pathname: '/users'));

        history.replace(Location(pathname: '/settings'));

        expect(history.location.pathname, '/settings');
        expect(history.action, Action.replace);
        expect(history.length, 2); // 不改变堆栈大小
      });

      test('触发监听器', () {
        final history = BrowserHistory();
        Update? lastUpdate;

        history.listen((update) {
          lastUpdate = update;
        });

        history.replace(Location(pathname: '/new'));

        expect(lastUpdate, isNotNull);
        expect(lastUpdate!.action, Action.replace);
        expect(lastUpdate!.location.pathname, '/new');
      });
    });

    group('go/back/forward', () {
      test('back 后退一步', () {
        final history = BrowserHistory();
        history.push(Location(pathname: '/a'));
        history.push(Location(pathname: '/b'));

        history.back();

        expect(history.location.pathname, '/a');
        expect(history.action, Action.pop);
      });

      test('forward 前进一步', () {
        final history = BrowserHistory();
        history.push(Location(pathname: '/a'));
        history.push(Location(pathname: '/b'));
        history.back();

        history.forward();

        expect(history.location.pathname, '/b');
        expect(history.action, Action.pop);
      });

      test('go 跳转指定步数', () {
        final history = BrowserHistory();
        history.push(Location(pathname: '/a'));
        history.push(Location(pathname: '/b'));
        history.push(Location(pathname: '/c'));

        history.go(-2);

        expect(history.location.pathname, '/a');
        expect(history.action, Action.pop);
      });
    });

    group('listen', () {
      test('监听位置变化', () {
        final history = BrowserHistory();
        final updates = <Update>[];

        history.listen((update) {
          updates.add(update);
        });

        history.push(Location(pathname: '/a'));
        history.push(Location(pathname: '/b'));

        expect(updates.length, 2);
        expect(updates[0].location.pathname, '/a');
        expect(updates[1].location.pathname, '/b');
      });

      test('可以取消监听', () {
        final history = BrowserHistory();
        final updates = <Update>[];

        final unlisten = history.listen((update) {
          updates.add(update);
        });

        history.push(Location(pathname: '/a'));
        unlisten();
        history.push(Location(pathname: '/b'));

        expect(updates.length, 1);
        expect(updates[0].location.pathname, '/a');
      });
    });

    group('createHref', () {
      test('生成正确的 URL', () {
        final history = BrowserHistory();

        final href = history.createHref(
          Location(
            pathname: '/users/123',
            search: '?page=1',
            hash: '#profile',
          ),
        );

        expect(href, '/users/123?page=1#profile');
      });
    });

    group('复杂导航场景', () {
      test('完整的导航流程', () {
        final history = BrowserHistory();
        final updates = <Update>[];

        history.listen((update) {
          updates.add(update);
        });

        // 推入多个位置
        history.push(Location(pathname: '/a'));
        history.push(Location(pathname: '/b'));
        history.push(Location(pathname: '/c'));

        // 后退
        history.back();

        // 从中间位置推入新位置（会截断 /c）
        history.push(Location(pathname: '/d'));

        expect(history.length, 4); // /, /a, /b, /d
        expect(history.location.pathname, '/d');
        expect(updates.length, 5); // 3 次 push + 1 次 back + 1 次 push
      });
    });
  });
}
