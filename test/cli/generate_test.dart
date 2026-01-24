import 'dart:io';

import 'package:coal/args.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:unrouter/src/cli/commands/generate.dart';

void main() {
  late Directory original;
  late Directory temp;

  setUp(() async {
    original = Directory.current;
    temp = await Directory.systemTemp.createTemp('unrouter_generate_');
    Directory.current = temp;
  });

  tearDown(() {
    Directory.current = original;
    temp.deleteSync(recursive: true);
  });

  Args parseArgs({String? pages, String? output}) {
    final args = <String>[];
    if (pages != null) {
      args
        ..add('--pages')
        ..add(pages);
    }
    if (output != null) {
      args
        ..add('--output')
        ..add(output);
    }
    return Args.parse(args, string: const ['pages', 'output']);
  }

  void writePubspec(String dirPath) {
    File(p.join(dirPath, 'pubspec.yaml')).writeAsStringSync('name: test');
  }

  void writePage(String path, String className) {
    File(path).writeAsStringSync('''
import 'package:flutter/widgets.dart';

class $className extends StatelessWidget {
  const $className({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');
  }

  test('generate emits const routes with literal metadata', () async {
    writePubspec(temp.path);

    final pagesDir = Directory(p.join(temp.path, 'lib', 'pages'))
      ..createSync(recursive: true);

    writePage(p.join(pagesDir.path, 'index.dart'), 'HomePage');

    final userDir = Directory(p.join(pagesDir.path, 'users'))
      ..createSync(recursive: true);
    File(p.join(userDir.path, '[id].dart')).writeAsStringSync('''
import 'package:flutter/widgets.dart';

class Helper extends StatelessWidget {
  const Helper({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');

    final userDetailDir = Directory(p.join(userDir.path, '[id]'))
      ..createSync(recursive: true);
    File(p.join(userDetailDir.path, 'settings.dart')).writeAsStringSync('''
import 'package:flutter/widgets.dart';

class UserSettingsPage extends StatelessWidget {
  const UserSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');

    final shopDir = Directory(
      p.join(pagesDir.path, 'shops', '[shopId]', 'products'),
    )..createSync(recursive: true);
    File(p.join(shopDir.path, '[productId].dart')).writeAsStringSync('''
import 'package:flutter/widgets.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');

    final adminDir = Directory(p.join(pagesDir.path, 'admin'))
      ..createSync(recursive: true);
    File(p.join(adminDir.path, 'dashboard.dart')).writeAsStringSync('''
import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart';

Future<GuardResult> adminGuard(GuardContext context) async {
  return GuardResult.allow;
}

const route = RouteMeta(
  name: 'adminDashboard',
  guards: const [adminGuard],
);

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');

    final guardsDir = Directory(p.join(pagesDir.path, 'guards'))
      ..createSync(recursive: true);
    File(p.join(guardsDir.path, 'name_only.dart')).writeAsStringSync('''
import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart';

const route = RouteMeta(
  name: 'nameOnly',
);

class NameOnlyPage extends StatelessWidget {
  const NameOnlyPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');

    File(p.join(guardsDir.path, 'guards_only.dart')).writeAsStringSync('''
import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart';

Future<GuardResult> onlyGuard(GuardContext context) async {
  return GuardResult.allow;
}

const route = RouteMeta(
  guards: const [onlyGuard],
);

class GuardsOnlyPage extends StatelessWidget {
  const GuardsOnlyPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');

    final guardLibDir = Directory(p.join(temp.path, 'lib', 'guards'))
      ..createSync(recursive: true);
    File(p.join(guardLibDir.path, 'auth_guard.dart')).writeAsStringSync('''
import 'package:unrouter/unrouter.dart';

Future<GuardResult> authGuard(GuardContext context) async {
  return GuardResult.allow;
}
''');

    File(p.join(guardsDir.path, 'imported_guard.dart')).writeAsStringSync('''
import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart';
import 'package:test/guards/auth_guard.dart' as auth;

const route = RouteMeta(
  guards: const [auth.authGuard],
);

class ImportedGuardPage extends StatelessWidget {
  const ImportedGuardPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');

    final code = await runGenerate(parseArgs());
    expect(code, 0);

    final outputFile = File(p.join(temp.path, 'lib', 'routes.dart'));
    expect(outputFile.existsSync(), true);

    final contents = outputFile.readAsStringSync();
    expect(contents, contains("import './pages/index.dart' as page_index;"));
    expect(
      contents,
      contains("import './pages/users/[id].dart' as page_users_id;"),
    );
    expect(
      contents,
      contains(
        "import './pages/shops/[shopId]/products/[productId].dart' as page_shops_shopid_products_productid;",
      ),
    );
    expect(
      contents,
      contains(
        "import './pages/users/[id]/settings.dart' as page_users_id_settings;",
      ),
    );
    expect(
      contents,
      contains(
        "import './pages/admin/dashboard.dart' as page_admin_dashboard;",
      ),
    );
    expect(
      contents,
      contains("Inlet(path: '', factory: page_index.HomePage.new),"),
    );
    expect(contents, contains('const routes = <Inlet>['));
    expect(contents, contains("Inlet(\n    path: 'users/:id',"));
    expect(contents, contains("children: [\n      Inlet(path: 'settings',"));
    expect(
      contents,
      contains(
        "Inlet(path: 'settings', factory: page_users_id_settings.UserSettingsPage.new),",
      ),
    );
    expect(
      contents,
      contains(
        "Inlet(path: 'shops/:shopId/products/:productId', factory: page_shops_shopid_products_productid.ProductDetailPage.new),",
      ),
    );
    expect(contents, contains("name: 'adminDashboard',"));
    expect(contents, contains('guards: [page_admin_dashboard.adminGuard],'));
    expect(contents, contains("name: 'nameOnly',"));
    expect(contents, contains('guards: [page_guards_guards_only.onlyGuard],'));
    expect(contents, contains('guards: [auth.authGuard],'));
    expect(
      contents,
      contains("import 'package:test/guards/auth_guard.dart' as auth;"),
    );
  });

  test(
    'generate falls back for non-literal guards and keeps const nodes',
    () async {
      writePubspec(temp.path);

      final pagesDir = Directory(p.join(temp.path, 'lib', 'pages'))
        ..createSync(recursive: true);

      writePage(p.join(pagesDir.path, 'index.dart'), 'HomePage');

      final guardsDir = Directory(p.join(pagesDir.path, 'guards'))
        ..createSync(recursive: true);
      File(p.join(guardsDir.path, 'anonymous_guard.dart')).writeAsStringSync('''
import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart';

final route = RouteMeta(
  guards: [
    (context) => GuardResult.allow,
  ],
);

class AnonymousGuardPage extends StatelessWidget {
  const AnonymousGuardPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');

      File(p.join(guardsDir.path, 'private_guard.dart')).writeAsStringSync('''
import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart';

Future<GuardResult> _privateGuard(GuardContext context) async {
  return GuardResult.allow;
}

const route = RouteMeta(
  guards: const [_privateGuard],
);

class PrivateGuardPage extends StatelessWidget {
  const PrivateGuardPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');

      final userDir = Directory(p.join(pagesDir.path, 'users'))
        ..createSync(recursive: true);
      File(p.join(userDir.path, '[id].dart')).writeAsStringSync('''
import 'package:flutter/widgets.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');
      final userDetailDir = Directory(p.join(userDir.path, '[id]'))
        ..createSync(recursive: true);
      File(p.join(userDetailDir.path, 'settings.dart')).writeAsStringSync('''
import 'package:flutter/widgets.dart';

class UserSettingsPage extends StatelessWidget {
  const UserSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');

      final code = await runGenerate(parseArgs());
      expect(code, 0);

      final outputFile = File(p.join(temp.path, 'lib', 'routes.dart'));
      final contents = outputFile.readAsStringSync();

      expect(contents, contains('final routes = <Inlet>['));
      expect(contents, contains("path: 'guards/anonymous_guard',"));
      expect(
        contents,
        contains('guards: page_guards_anonymous_guard.route.guards,'),
      );
      expect(contents, contains("path: 'guards/private_guard',"));
      expect(
        contents,
        contains('guards: page_guards_private_guard.route.guards,'),
      );
      expect(
        contents,
        contains("const Inlet(path: '', factory: page_index.HomePage.new),"),
      );
      expect(
        contents,
        contains(
          "const Inlet(\n    path: 'users/:id',\n    factory: page_users_id.UserPage.new,\n    children: [",
        ),
      );
    },
  );

  test('generate handles non-literal name and mixed guards', () async {
    writePubspec(temp.path);

    final pagesDir = Directory(p.join(temp.path, 'lib', 'pages'))
      ..createSync(recursive: true);

    final guardsDir = Directory(p.join(pagesDir.path, 'guards'))
      ..createSync(recursive: true);

    final guardLibDir = Directory(p.join(temp.path, 'lib', 'guards'))
      ..createSync(recursive: true);
    File(p.join(guardLibDir.path, 'auth_guard.dart')).writeAsStringSync('''
import 'package:unrouter/unrouter.dart';

Future<GuardResult> authGuard(GuardContext context) async {
  return GuardResult.allow;
}
''');

    File(p.join(guardsDir.path, 'mixed_guard.dart')).writeAsStringSync('''
import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart';
import 'package:test/guards/auth_guard.dart' as auth;

const guardName = 'mixedGuardPage';

Future<GuardResult> localGuard(GuardContext context) async {
  return GuardResult.allow;
}

const route = RouteMeta(
  name: guardName,
  guards: const [localGuard, auth.authGuard],
);

class MixedGuardPage extends StatelessWidget {
  const MixedGuardPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');

    final code = await runGenerate(parseArgs());
    expect(code, 0);

    final contents = File(
      p.join(temp.path, 'lib', 'routes.dart'),
    ).readAsStringSync();

    expect(contents, contains('final routes = <Inlet>['));
    expect(contents, contains('name: page_guards_mixed_guard.route.name,'));
    expect(
      contents,
      contains('guards: [page_guards_mixed_guard.localGuard, auth.authGuard],'),
    );
    expect(
      contents,
      contains("import 'package:test/guards/auth_guard.dart' as auth;"),
    );
  });

  test('generate fails when guard import prefix conflicts', () async {
    writePubspec(temp.path);

    final pagesDir = Directory(p.join(temp.path, 'lib', 'pages'))
      ..createSync(recursive: true);
    final guardLibDir = Directory(p.join(temp.path, 'lib', 'guards'))
      ..createSync(recursive: true);
    File(p.join(guardLibDir.path, 'auth_guard.dart')).writeAsStringSync('''
import 'package:unrouter/unrouter.dart';

Future<GuardResult> authGuard(GuardContext context) async {
  return GuardResult.allow;
}
''');

    File(p.join(pagesDir.path, 'a.dart')).writeAsStringSync('''
import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart';
import 'package:test/guards/auth_guard.dart' as auth;

Future<GuardResult> localGuard(GuardContext context) async {
  return GuardResult.allow;
}

const route = RouteMeta(
  guards: const [localGuard, auth.authGuard],
);

class APage extends StatelessWidget {
  const APage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');

    File(p.join(pagesDir.path, 'b.dart')).writeAsStringSync('''
import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart';
import '../guards/auth_guard.dart' as auth;

Future<GuardResult> localGuard(GuardContext context) async {
  return GuardResult.allow;
}

const route = RouteMeta(
  guards: const [localGuard, auth.authGuard],
);

class BPage extends StatelessWidget {
  const BPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');

    final code = await runGenerate(parseArgs());
    expect(code, 1);
  });

  test('generate supports group layouts and ignores group segments', () async {
    writePubspec(temp.path);

    final pagesDir = Directory(p.join(temp.path, 'lib', 'pages'))
      ..createSync(recursive: true);

    writePage(p.join(pagesDir.path, '(auth).dart'), 'AuthLayout');

    final authDir = Directory(p.join(pagesDir.path, '(auth)'))
      ..createSync(recursive: true);
    writePage(p.join(authDir.path, 'login.dart'), 'LoginPage');

    final marketingDir = Directory(p.join(pagesDir.path, '(marketing)'))
      ..createSync(recursive: true);
    writePage(p.join(marketingDir.path, 'about.dart'), 'MarketingAboutPage');

    final code = await runGenerate(parseArgs());
    expect(code, 0);

    final contents = File(
      p.join(temp.path, 'lib', 'routes.dart'),
    ).readAsStringSync();

    expect(contents, contains("import './pages/(auth).dart' as page_auth;"));
    expect(
      contents,
      contains("import './pages/(auth)/login.dart' as page_auth_login;"),
    );
    expect(
      contents,
      contains(
        "import './pages/(marketing)/about.dart' as page_marketing_about;",
      ),
    );
    expect(
      contents,
      contains(
        "Inlet(\n    path: '',\n    factory: page_auth.AuthLayout.new,\n    children: [",
      ),
    );
    expect(
      contents,
      contains(
        "Inlet(path: 'login', factory: page_auth_login.LoginPage.new),",
      ),
    );
    expect(
      contents,
      contains(
        "Inlet(path: 'about', factory: page_marketing_about.MarketingAboutPage.new),",
      ),
    );
  });

  test('generate supports layout file with index child', () async {
    writePubspec(temp.path);

    final pagesDir = Directory(p.join(temp.path, 'lib', 'pages'))
      ..createSync(recursive: true);

    writePage(p.join(pagesDir.path, 'users.dart'), 'UsersLayout');
    final usersDir = Directory(p.join(pagesDir.path, 'users'))
      ..createSync(recursive: true);
    writePage(p.join(usersDir.path, 'index.dart'), 'UsersIndexPage');

    final code = await runGenerate(parseArgs());
    expect(code, 0);

    final contents = File(
      p.join(temp.path, 'lib', 'routes.dart'),
    ).readAsStringSync();

    expect(contents, contains("import './pages/users.dart' as page_users;"));
    expect(
      contents,
      contains("import './pages/users/index.dart' as page_users_index;"),
    );
    expect(
      contents,
      contains(
        "Inlet(\n    path: 'users',\n    factory: page_users.UsersLayout.new,\n    children: [",
      ),
    );
    expect(
      contents,
      contains(
        "Inlet(path: '', factory: page_users_index.UsersIndexPage.new),",
      ),
    );
  });
}
