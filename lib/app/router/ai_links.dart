import 'package:farm_tap/app/router/routes.dart';

/// Where a finding's link goes on the phone. The AI engine is shared with
/// the web app, so its links are web paths ("/milk/", "/herd/?animal=ID");
/// null when the phone has no screen for one (the card then shows no link).
String? phoneRouteForAiLink(String href) {
  final uri = Uri.tryParse(href);
  if (uri == null) return null;
  final path = uri.path.endsWith('/') && uri.path.length > 1 ? uri.path.substring(0, uri.path.length - 1) : uri.path;
  final q = uri.queryParameters;
  switch (path) {
    case '/milk':
      return q['new'] == '1' ? AppRoutes.milkRecord : AppRoutes.milk;
    case '/herd':
      final id = q['animal'];
      return id == null || id.isEmpty ? AppRoutes.herd : AppRoutes.herdAnimal(id);
    case '/health':
      return AppRoutes.health;
    case '/feeds':
      return AppRoutes.feeding;
    case '/breeding':
      return AppRoutes.breeding;
    case '/money':
      return AppRoutes.money;
    case '/reports':
      return AppRoutes.reports;
    case '/contacts':
      return AppRoutes.moreContacts;
    case '/farmers':
      final id = q['farmer'];
      return id == null || id.isEmpty ? AppRoutes.farmers : AppRoutes.centreFarmer(id);
  }
  if (path.startsWith('/ai/')) {
    final key = path.substring(4);
    return key.isEmpty ? AppRoutes.moreAi : AppRoutes.moreAiModule(key);
  }
  return null;
}
