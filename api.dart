const routes = <Route>[
  Route<DefaultLayout>('/', withNestedRoutes([])),
  Route<About>('/about', .new),
  Route<Fallback>('**', .new),
];

class DefaultLayout extends StatelessWidget {
  Widget build(context) {
    return Column(children: [Text('Default'), RouterView()]);
  }
}
