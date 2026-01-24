// GENERATED CODE - DO NOT MODIFY BY HAND.
import 'package:unrouter/unrouter.dart';
import './pages/(auth).dart' as page_auth;
import './pages/(auth)/login.dart' as page_auth_login;
import './pages/(auth)/register.dart' as page_auth_register;
import './pages/about.dart' as page_about;
import './pages/concerts.dart' as page_concerts;
import './pages/concerts/[city].dart' as page_concerts_city;
import './pages/concerts/index.dart' as page_concerts_index;
import './pages/concerts/trending.dart' as page_concerts_trending;
import './pages/index.dart' as page_index;
import './pages/nested_animation.dart' as page_nested_animation;
import './pages/nested_animation/details.dart' as page_nested_animation_details;
import './pages/nested_animation/index.dart' as page_nested_animation_index;
import './pages/nested_animation/reviews.dart' as page_nested_animation_reviews;
import './pages/products.dart' as page_products;
import './pages/route_animation.dart' as page_route_animation;

const routes = <Inlet>[
  Inlet(path: '', name: 'home', factory: page_index.HomePage.new),
  Inlet(
    path: '',
    factory: page_auth.AuthLayout.new,
    children: [
      Inlet(
        path: 'login',
        name: 'login',
        factory: page_auth_login.LoginPage.new,
      ),
      Inlet(
        path: 'register',
        name: 'register',
        factory: page_auth_register.RegisterPage.new,
      ),
    ],
  ),
  Inlet(path: 'about', name: 'about', factory: page_about.AboutPage.new),
  Inlet(
    path: 'concerts',
    name: 'concerts',
    factory: page_concerts.ConcertsLayout.new,
    children: [
      Inlet(
        path: '',
        name: 'concertsHome',
        factory: page_concerts_index.ConcertsHomePage.new,
      ),
      Inlet(
        path: ':city',
        name: 'concertCity',
        factory: page_concerts_city.CityPage.new,
      ),
      Inlet(
        path: 'trending',
        name: 'concertsTrending',
        factory: page_concerts_trending.TrendingPage.new,
      ),
    ],
  ),
  Inlet(
    path: 'nested_animation',
    name: 'nestedAnimation',
    factory: page_nested_animation.NestedAnimationLayout.new,
    children: [
      Inlet(
        path: '',
        name: 'nestedAnimationIntro',
        factory: page_nested_animation_index.NestedAnimationIntroPage.new,
      ),
      Inlet(
        path: 'details',
        name: 'nestedAnimationDetails',
        factory: page_nested_animation_details.NestedAnimationDetailsPage.new,
      ),
      Inlet(
        path: 'reviews',
        name: 'nestedAnimationReviews',
        factory: page_nested_animation_reviews.NestedAnimationReviewsPage.new,
      ),
    ],
  ),
  Inlet(
    path: 'products',
    name: 'products',
    factory: page_products.ProductsPage.new,
  ),
  Inlet(
    path: 'route_animation',
    name: 'routeAnimation',
    factory: page_route_animation.RouteAnimationPage.new,
  ),
];
