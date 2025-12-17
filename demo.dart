import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: Unrouter(
        mode: .memory,
        Routes([.new(path: 'a', factory: () => const A())]),
      ),
    );
  }
}

class A extends StatelessWidget {
  const A({super.key});

  @override
  Widget build(BuildContext context) {
    // 因为没有依赖 unrouter 的任何 state，因此 A 永远不会 rebuild。
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: TabBar(
          tabs: [
            Tab(text: 'B'),
            Tab(text: 'C'),
          ],
          onTap: (index) {
            // TODO
          },
        ),
        body: TabBarView(
          children: [
            // 当从 /a/c 切换到 /a/b 的时候，只有这个 Unroute rebuild
            Unroute(path: 'b', factory: () => const B()),

            // 当从 /a/b 切换到 /a/c 的时候，只有这个 Unroute rebuild
            Unroute(path: 'c', factory: () => const C()),
          ],
        ),
      ),
    );
  }
}

class B extends StatelessWidget {
  const B({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('B'));
  }
}

class C extends StatelessWidget {
  const C({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('C'));
  }
}
