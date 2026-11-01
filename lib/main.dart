import 'package:farm_tap/app/app.dart';
import 'package:farm_tap/app/flavor.dart';
import 'package:flutter/material.dart';

void main() => runApp(FarmTapApp(config: AppConfig.forFlavor(Flavor.dev)));
