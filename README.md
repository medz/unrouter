Unrouter 是一个基于 **zenrouter** 的极简路由：

- routes 表描述路径、组件、嵌套路由
- `<RouterView>` 递归渲染当前深度组件
- 字符串导航：`go('/path')` / `pushPath('/path')`
- 顶级函数式 API：`useRouter`、`useRoute`、`useRouterParams`、`useQueryParams`

## 安装

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  unrouter:
    path: ../unrouter # 按需修改为你的路径或发布源
```

## 基本用法

```dart
import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

const routes = <Route>[
  Route<RootLayout>(
    '/',
    RootLayout.new,
    children: [
      Route<Home>('', Home.new), // `/`
      Route<About>('about', About.new), // `/about`
      Route<Profile>('users/:id', Profile.new), // `/users/:id`
    ],
  ),
  Route<NotFound>('**', NotFound.new),
];

final router = Unrouter(routes: routes);

void main() {
  runApp(
    MaterialApp.router(
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
    ),
  );
}

class RootLayout extends StatelessWidget {
  const RootLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unrouter demo')),
      body: const RouterView(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);
    return Column(
      children: [
        const Text('Home'),
        ElevatedButton(
          onPressed: () => router.go('/about?tab=info'),
          child: const Text('Go About'),
        ),
        ElevatedButton(
          onPressed: () => router.go('/users/42'),
          child: const Text('Go Profile 42'),
        ),
      ],
    );
  }
}

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    final query = useQueryParams(context);
    return Text('About page, tab=${query['tab']}');
  }
}

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    final params = useRouterParams(context);
    return Text('Profile id=${params['id']}');
  }
}

class NotFound extends StatelessWidget {
  const NotFound({super.key});

  @override
  Widget build(BuildContext context) => const Text('404');
}
```

更多参考见 `example/`。运行示例：

```sh
flutter run -d chrome example/lib/main.dart
```
