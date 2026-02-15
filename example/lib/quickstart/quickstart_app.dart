import 'package:unrouter/unrouter.dart';

import 'quickstart_views.dart';

final List<Inlet> quickstartRoutes = [
  Inlet(
    path: '/quickstart',
    view: QuickstartLayoutView.new,
    children: [
      Inlet(name: 'home', path: '', view: QuickstartHomeView.new),
      Inlet(name: 'about', path: 'about', view: QuickstartAboutView.new),
      Inlet(
        name: 'profile',
        path: 'profile/:id',
        view: QuickstartProfileView.new,
      ),
    ],
  ),
];
