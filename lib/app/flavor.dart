enum Flavor {
  dev,
  prod;

  static Flavor? _current;
  static set current(Flavor flavor) => _current = flavor;
  static Flavor get current => _current!;
}

class AppConfig {
  const new({
    required this.flavor,
    required this.appName,
  });

  factory forFlavor(Flavor flavor) {
    return switch (flavor) {
      Flavor.dev => const AppConfig(
          flavor: Flavor.dev,
          appName: '[DEV] FarmTap',
        ),
      Flavor.prod => const AppConfig(
          flavor: Flavor.prod,
          appName: 'FarmTap',
        ),
    };
  }

  final Flavor flavor;
  final String appName;
}
