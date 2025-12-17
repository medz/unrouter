import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart';

void main(List<String> args) {}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final router = Unrouter(
      Routes([
        Unroute(path: null, factory: Home.new),
        Unroute(path: 'about', factory: About.new),
        Unroute(path: 'auth', factory: AuthLayout.new),
        Unroute(path: 'concerts', factory: Concerts.new),
      ]),
      mode: HistoryMode.memory,
    );

    // 方法 1，直接使用 Widgets 的 Router
    return Router.withConfig(config: router);

    // 方法 2，基于 Widgets.app
    return WidgetsApp.router(
      color: const Color(0xff000000),
      routerConfig: router,
    );

    // 方法 3，基于 MaterialApp
    return MaterialApp.router(routerConfig: router);

    // 方法 3，基于 CupertinoApp
    return CupertinoApp.router(routerConfig: router);
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Home');
  }
}

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('About');
  }
}

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(children: []),
        Routes([
          Unroute(path: 'login', factory: Login.new),
          Unroute(path: 'register', factory: Register.new),
        ]),
      ],
    );
  }
}

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Login');
  }
}

class Register extends StatelessWidget {
  const Register({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Register');
  }
}

class Concerts extends StatelessWidget {
  const Concerts({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Concerts');
  }
}
