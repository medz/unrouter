import 'package:nocterm/nocterm.dart';
import 'package:nocterm_unrouter/nocterm_unrouter.dart';
import 'package:unstory/unstory.dart';

Unrouter buildExampleRouter() {
  return createRouter(
    history: MemoryHistory(initialEntries: [HistoryLocation(Uri(path: '/'))]),
    routes: const [
      Inlet(path: '/', view: HomeView.new),
      Inlet(
        path: '/docs',
        view: DocsLayout.new,
        children: [Inlet(path: 'intro', view: DocsIntroView.new)],
      ),
      Inlet(name: 'profile', path: '/users/:id', view: ProfileView.new),
    ],
  );
}

Future<void> runExampleApp() async {
  await runApp(
    NoctermApp(
      title: 'Nocterm Unrouter Example',
      child: ExampleApp(router: buildExampleRouter()),
    ),
  );
}

class ExampleApp extends StatefulComponent {
  const ExampleApp({required this.router, super.key});

  final Unrouter router;

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  @override
  void initState() {
    super.initState();
    component.router.addListener(_handleRouteChange);
  }

  @override
  void didUpdateComponent(covariant ExampleApp oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.router == component.router) {
      return;
    }

    oldComponent.router.removeListener(_handleRouteChange);
    component.router.addListener(_handleRouteChange);
  }

  @override
  void dispose() {
    component.router.removeListener(_handleRouteChange);
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final path = component.router.history.location.path;

    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        switch (event.logicalKey) {
          case LogicalKey.digit1:
            component.router.push('/docs/intro');
            return true;
          case LogicalKey.digit2:
            component.router.push(
              'profile',
              params: {'id': '42'},
              query: URLSearchParams({'tab': 'activity'}),
              state: 'opened-from-shell',
            );
            return true;
          case LogicalKey.keyB:
            component.router.pop();
            return true;
          case LogicalKey.keyH:
            component.router.replace('/');
            return true;
          case LogicalKey.keyQ:
            shutdownApp();
            return true;
          default:
            return false;
        }
      },
      child: Container(
        decoration: BoxDecoration(border: BoxBorder.all(color: Colors.cyan)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: const BoxDecoration(color: Colors.cyan),
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
              child: Text(
                ' Nocterm Unrouter Example  route:$path  1:docs  2:profile  b:back  h:home  q:quit ',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: UnrouterHost(router: component.router),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleRouteChange() {
    if (!mounted) return;
    setState(() {});
  }
}

class HomeView extends StatelessComponent {
  const HomeView({super.key});

  @override
  Component build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Home'),
        SizedBox(height: 1),
        Text('Press 1 to open a nested docs route.'),
        Text('Press 2 to open a named profile route.'),
        Text('Press b to go back, h to return home, q to quit.'),
      ],
    );
  }
}

class DocsLayout extends StatelessComponent {
  const DocsLayout({super.key});

  @override
  Component build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Docs Layout'),
        const SizedBox(height: 1),
        const Text('This parent view stays mounted while child routes swap.'),
        const SizedBox(height: 1),
        Expanded(child: const Outlet()),
      ],
    );
  }
}

class DocsIntroView extends StatelessComponent {
  const DocsIntroView({super.key});

  @override
  Component build(BuildContext context) {
    final from = useFromLocation(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Docs Intro'),
        const SizedBox(height: 1),
        Text('from:${from?.path ?? 'null'}'),
        const Text('Nested rendering is handled by Outlet + UnrouterHost.'),
      ],
    );
  }
}

class ProfileView extends StatelessComponent {
  const ProfileView({super.key});

  @override
  Component build(BuildContext context) {
    final params = useRouteParams(context);
    final query = useQuery(context);
    final state = useRouteState<String>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Profile'),
        const SizedBox(height: 1),
        Text('id:${params.required('id')}'),
        Text('tab:${query.get('tab') ?? 'none'}'),
        Text('state:${state ?? 'null'}'),
      ],
    );
  }
}
