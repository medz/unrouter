import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  group('MemoryHistory', () {
    group('初始化', () {
      test('默认从单个根路径开始', () {
        final history = MemoryHistory();
        expect(history.location.pathname, '/');
        expect(history.index, 0);
        expect(history.length, 1);
        expect(history.action, Action.pop);
      });

      test('可以使用初始条目初始化', () {
        final history = MemoryHistory(
          initialEntries: [
            Location(pathname: '/home'),
            Location(pathname: '/users'),
            Location(pathname: '/users/123'),
          ],
        );
        expect(history.location.pathname, '/users/123');
        expect(history.index, 2);
        expect(history.length, 3);
      });

      test('可以指定初始索引', () {
        final history = MemoryHistory(
          initialEntries: [
            Location(pathname: '/home'),
            Location(pathname: '/users'),
            Location(pathname: '/users/123'),
          ],
          initialIndex: 1,
        );
        expect(history.location.pathname, '/users');
        expect(history.index, 1);
        expect(history.length, 3);
      });

      test('可以使用 Location 对象初始化', () {
        final history = MemoryHistory(
          initialEntries: [
            Location(pathname: '/home'),
            Location(pathname: '/users', search: '?page=1'),
            Location(pathname: '/users/123', hash: '#profile'),
          ],
        );
        expect(history.location.pathname, '/users/123');
        expect(history.location.hash, '#profile');
        expect(history.length, 3);
      });

      test('初始索引超出范围时抛出错误', () {
        expect(
          () => MemoryHistory(
            initialEntries: [
              Location(pathname: '/home'),
              Location(pathname: '/users'),
            ],
            initialIndex: 5,
          ),
          throwsRangeError,
        );

        expect(
          () => MemoryHistory(
            initialEntries: [
              Location(pathname: '/home'),
              Location(pathname: '/users'),
            ],
            initialIndex: -1,
          ),
          throwsRangeError,
        );
      });
    });

    group('push', () {
      test('添加新条目并更新位置', () {
        final history = MemoryHistory();
        history.push(Location(pathname: '/users'));

        expect(history.location.pathname, '/users');
        expect(history.index, 1);
        expect(history.length, 2);
        expect(history.action, Action.push);
      });

      test('支持带查询参数的路径', () {
        final history = MemoryHistory();
        history.push(Location.fromPath('/users?page=1&sort=desc'));

        expect(history.location.pathname, '/users');
        expect(history.location.search, '?page=1&sort=desc');
      });

      test('支持带哈希的路径', () {
        final history = MemoryHistory();
        history.push(Location.fromPath('/users#section1'));

        expect(history.location.pathname, '/users');
        expect(history.location.hash, '#section1');
      });

      test('支持完整的 URL', () {
        final history = MemoryHistory();
        history.push(Location.fromPath('/users/123?page=1#profile'));

        expect(history.location.pathname, '/users/123');
        expect(history.location.search, '?page=1');
        expect(history.location.hash, '#profile');
      });

      test('支持 Location 对象', () {
        final history = MemoryHistory();
        history.push(Location(
          pathname: '/users',
          search: '?page=1',
          state: {'from': 'home'},
        ));

        expect(history.location.pathname, '/users');
        expect(history.location.search, '?page=1');
        expect(history.location.state, {'from': 'home'});
      });

      test('支持状态对象', () {
        final history = MemoryHistory();
        history.push(Location.fromPath('/users', state: {'id': 123}));

        expect(history.location.pathname, '/users');
        expect(history.location.state, {'id': 123});
      });

      test('截断当前索引后的条目', () {
        final history = MemoryHistory(
          initialEntries: [
            Location(pathname: '/home'),
            Location(pathname: '/users'),
            Location(pathname: '/settings'),
          ],
        );

        // 后退到 /users
        history.back();
        expect(history.location.pathname, '/users');
        expect(history.length, 3);

        // 推入新条目，应该截断 /settings
        history.push(Location(pathname: '/profile'));
        expect(history.location.pathname, '/profile');
        expect(history.length, 3);
        expect(history.index, 2);

        // 无法前进到 /settings
        history.forward();
        expect(history.location.pathname, '/profile');
      });

      test('触发监听器', () {
        final history = MemoryHistory();
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
        final history = MemoryHistory(
          initialEntries: [
            Location(pathname: '/home'),
            Location(pathname: '/users'),
          ],
        );

        history.replace(Location(pathname: '/settings'));

        expect(history.location.pathname, '/settings');
        expect(history.index, 1);
        expect(history.length, 2);
        expect(history.action, Action.replace);
      });

      test('不改变堆栈大小', () {
        final history = MemoryHistory();
        final initialLength = history.length;

        history.replace(Location(pathname: '/new-path'));

        expect(history.length, initialLength);
      });

      test('支持状态对象', () {
        final history = MemoryHistory();
        history.replace(Location.fromPath('/users', state: {'replaced': true}));

        expect(history.location.pathname, '/users');
        expect(history.location.state, {'replaced': true});
      });

      test('触发监听器', () {
        final history = MemoryHistory();
        Update? lastUpdate;

        history.listen((update) {
          lastUpdate = update;
        });

        history.replace(Location(pathname: '/users'));

        expect(lastUpdate, isNotNull);
        expect(lastUpdate!.action, Action.replace);
        expect(lastUpdate!.location.pathname, '/users');
      });
    });

    group('go', () {
      test('后退指定步数', () {
        final history = MemoryHistory(
          initialEntries: [
            Location(pathname: '/home'),
            Location(pathname: '/users'),
            Location(pathname: '/users/123'),
            Location(pathname: '/settings'),
          ],
        );

        history.go(-2);

        expect(history.location.pathname, '/users');
        expect(history.index, 1);
        expect(history.action, Action.pop);
      });

      test('前进指定步数', () {
        final history = MemoryHistory(
          initialEntries: [
            Location(pathname: '/home'),
            Location(pathname: '/users'),
            Location(pathname: '/users/123'),
          ],
          initialIndex: 0,
        );

        history.go(2);

        expect(history.location.pathname, '/users/123');
        expect(history.index, 2);
        expect(history.action, Action.pop);
      });

      test('delta 为 0 时刷新当前位置', () {
        final history = MemoryHistory();
        final initialPathname = history.location.pathname;
        final initialIndex = history.index;

        var notificationCount = 0;
        history.listen((_) => notificationCount++);

        history.go(0);

        expect(history.location.pathname, initialPathname);
        expect(history.index, initialIndex);
        expect(notificationCount, 1);
      });

      test('超出范围时不执行任何操作', () {
        final history = MemoryHistory(
          initialEntries: [
            Location(pathname: '/home'),
            Location(pathname: '/users'),
          ],
        );

        final initialPathname = history.location.pathname;
        final initialIndex = history.index;

        var notificationCount = 0;
        history.listen((_) => notificationCount++);

        // 尝试后退太多
        history.go(-10);
        expect(history.location.pathname, initialPathname);
        expect(history.index, initialIndex);
        expect(notificationCount, 0);

        // 尝试前进太多
        history.go(10);
        expect(history.location.pathname, initialPathname);
        expect(history.index, initialIndex);
        expect(notificationCount, 0);
      });

      test('触发监听器', () {
        final history = MemoryHistory(
          initialEntries: [
            Location(pathname: '/home'),
            Location(pathname: '/users'),
            Location(pathname: '/settings'),
          ],
        );
        Update? lastUpdate;

        history.listen((update) {
          lastUpdate = update;
        });

        history.go(-1);

        expect(lastUpdate, isNotNull);
        expect(lastUpdate!.action, Action.pop);
        expect(lastUpdate!.location.pathname, '/users');
      });
    });

    group('back', () {
      test('后退一步', () {
        final history = MemoryHistory(
          initialEntries: [
            Location(pathname: '/home'),
            Location(pathname: '/users'),
            Location(pathname: '/settings'),
          ],
        );

        history.back();

        expect(history.location.pathname, '/users');
        expect(history.index, 1);
      });

      test('等同于 go(-1)', () {
        final history1 = MemoryHistory(
          initialEntries: [
            Location(pathname: '/home'),
            Location(pathname: '/users'),
            Location(pathname: '/settings'),
          ],
        );
        final history2 = MemoryHistory(
          initialEntries: [
            Location(pathname: '/home'),
            Location(pathname: '/users'),
            Location(pathname: '/settings'),
          ],
        );

        history1.back();
        history2.go(-1);

        expect(history1.location.pathname, history2.location.pathname);
        expect(history1.index, history2.index);
      });
    });

    group('forward', () {
      test('前进一步', () {
        final history = MemoryHistory(
          initialEntries: [
            Location(pathname: '/home'),
            Location(pathname: '/users'),
            Location(pathname: '/settings'),
          ],
          initialIndex: 0,
        );

        history.forward();

        expect(history.location.pathname, '/users');
        expect(history.index, 1);
      });

      test('等同于 go(1)', () {
        final history1 = MemoryHistory(
          initialEntries: [
            Location(pathname: '/home'),
            Location(pathname: '/users'),
            Location(pathname: '/settings'),
          ],
          initialIndex: 0,
        );
        final history2 = MemoryHistory(
          initialEntries: [
            Location(pathname: '/home'),
            Location(pathname: '/users'),
            Location(pathname: '/settings'),
          ],
          initialIndex: 0,
        );

        history1.forward();
        history2.go(1);

        expect(history1.location.pathname, history2.location.pathname);
        expect(history1.index, history2.index);
      });
    });

    group('listen', () {
      test('监听位置变化', () {
        final history = MemoryHistory();
        final updates = <Update>[];

        history.listen((update) {
          updates.add(update);
        });

        history.push(Location(pathname: '/users'));
        history.replace(Location(pathname: '/settings'));
        history.back();

        expect(updates.length, 3);
        expect(updates[0].action, Action.push);
        expect(updates[1].action, Action.replace);
        expect(updates[2].action, Action.pop);
      });

      test('可以取消监听', () {
        final history = MemoryHistory();
        var notificationCount = 0;

        final unlisten = history.listen((_) {
          notificationCount++;
        });

        history.push(Location(pathname: '/users'));
        expect(notificationCount, 1);

        unlisten();

        history.push(Location(pathname: '/settings'));
        expect(notificationCount, 1); // 没有增加
      });

      test('支持多个监听器', () {
        final history = MemoryHistory();
        var count1 = 0;
        var count2 = 0;

        history.listen((_) => count1++);
        history.listen((_) => count2++);

        history.push(Location(pathname: '/users'));

        expect(count1, 1);
        expect(count2, 1);
      });

      test('在迭代时移除监听器不影响通知', () {
        final history = MemoryHistory();
        var count1 = 0;
        var count2 = 0;
        late Unlisten unlisten1;

        unlisten1 = history.listen((_) {
          count1++;
          unlisten1(); // 在回调中取消订阅
        });

        history.listen((_) => count2++);

        history.push(Location(pathname: '/users'));
        history.push(Location(pathname: '/settings'));

        expect(count1, 1); // 只通知一次
        expect(count2, 2); // 通知两次
      });
    });

    group('createHref', () {
      test('生成正确的 URL', () {
        final history = MemoryHistory();

        expect(
          history.createHref(Location(pathname: '/users')),
          '/users',
        );

        expect(
          history.createHref(Location(
            pathname: '/users',
            search: '?page=1',
          )),
          '/users?page=1',
        );

        expect(
          history.createHref(Location(
            pathname: '/users',
            search: '?page=1',
            hash: '#profile',
          )),
          '/users?page=1#profile',
        );
      });
    });

    group('Location', () {
      test('生成唯一的 key', () {
        final location1 = Location(pathname: '/users');
        final location2 = Location(pathname: '/users');

        expect(location1.key, isNot(location2.key));
      });

      test('copyWith 复制属性', () {
        final location = Location(
          pathname: '/users',
          search: '?page=1',
          hash: '#profile',
          state: {'id': 123},
        );

        final copy = location.copyWith(pathname: '/settings');

        expect(copy.pathname, '/settings');
        expect(copy.search, location.search);
        expect(copy.hash, location.hash);
        expect(copy.state, location.state);
        expect(copy.key, location.key);
      });

      test('toUrl 生成 URL 字符串', () {
        final location = Location(
          pathname: '/users',
          search: '?page=1',
          hash: '#profile',
        );

        expect(location.toUrl(), '/users?page=1#profile');
      });

      test('相等性比较', () {
        final location1 = Location(
          pathname: '/users',
          key: 'test-key',
        );
        final location2 = Location(
          pathname: '/users',
          key: 'test-key',
        );
        final location3 = Location(
          pathname: '/settings',
          key: 'test-key',
        );

        expect(location1, location2);
        expect(location1, isNot(location3));
      });
    });

    group('Location.fromPath', () {
      test('解析简单路径', () {
        final location = Location.fromPath('/users');
        expect(location.pathname, '/users');
        expect(location.search, '');
        expect(location.hash, '');
      });

      test('解析带查询参数的路径', () {
        final location = Location.fromPath('/users?page=1&sort=desc');
        expect(location.pathname, '/users');
        expect(location.search, '?page=1&sort=desc');
        expect(location.hash, '');
      });

      test('解析带哈希的路径', () {
        final location = Location.fromPath('/users#section');
        expect(location.pathname, '/users');
        expect(location.search, '');
        expect(location.hash, '#section');
      });

      test('解析完整的 URL', () {
        final location = Location.fromPath('/users/123?page=1#profile');
        expect(location.pathname, '/users/123');
        expect(location.search, '?page=1');
        expect(location.hash, '#profile');
      });

      test('支持状态对象', () {
        final location = Location.fromPath('/users', state: {'id': 123});
        expect(location.pathname, '/users');
        expect(location.state, {'id': 123});
      });
    });

    group('复杂导航场景', () {
      test('完整的导航流程', () {
        final history = MemoryHistory();
        final visitedPaths = <String>[];

        history.listen((update) {
          visitedPaths.add(update.location.pathname);
        });

        // 推入多个页面
        history.push(Location(pathname: '/users'));
        history.push(Location(pathname: '/users/123'));
        history.push(Location(pathname: '/users/123/posts'));

        expect(visitedPaths, ['/users', '/users/123', '/users/123/posts']);
        expect(history.length, 4);

        // 后退
        history.back();
        expect(history.location.pathname, '/users/123');
        expect(visitedPaths.last, '/users/123');

        // 从中间推入新页面
        history.push(Location(pathname: '/settings'));
        expect(history.length, 4); // /users/123/posts 被截断
        expect(history.location.pathname, '/settings');

        // 后退到起点
        history.go(-3);
        expect(history.location.pathname, '/');
      });

      test('带状态的导航', () {
        final history = MemoryHistory();

        history.push(Location.fromPath('/users', state: {'from': 'home'}));
        expect(history.location.state, {'from': 'home'});

        history.push(Location.fromPath('/users/123', state: {'id': 123}));
        expect(history.location.state, {'id': 123});

        history.back();
        expect(history.location.state, {'from': 'home'});
      });
    });
  });
}
