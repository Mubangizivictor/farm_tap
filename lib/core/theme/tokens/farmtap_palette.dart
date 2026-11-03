// ============================================================================
//  RAW COLOUR PALETTE — the ONLY file in the app allowed to contain hex colours.
//  Widgets never use these directly. They use semantic names from
//  ColorScheme (context.colors) and FarmTapSemanticColors (context.status).
// ============================================================================
import 'package:flutter/painting.dart';

abstract final class FarmTapPalette {
  // ---- Kraal Green ----
  static const green50 = Color(0xFFE8F4EF);
  static const green100 = Color(0xFFCFE9DF);
  static const green200 = Color(0xFFA6D6C3);
  static const green300 = Color(0xFF7BC1A6);
  static const green400 = Color(0xFF5FB89A); // brand green (dark mode)
  static const green500 = Color(0xFF3A8B6E);
  static const green600 = Color(0xFF2B7359);
  static const green700 = Color(0xFF1F5E4A); // brand green (light mode)
  static const green800 = Color(0xFF135040);
  static const green900 = Color(0xFF0B2A20);
  static const green950 = Color(0xFF00382A);
  static const green10 = Color(0xFFC4EEDD);

  // ---- Kraal Gold ----
  static const gold50 = Color(0xFFFFF6E0);
  static const gold100 = Color(0xFFFBE7B8);
  static const gold150 = Color(0xFFFFDFA0);
  static const gold200 = Color(0xFFF7D486);
  static const gold300 = Color(0xFFF0B83A); // brand gold (dark mode)
  static const gold400 = Color(0xFFDDA021);
  static const gold500 = Color(0xFFC98A0E); // brand gold (light mode)
  static const gold600 = Color(0xFFA36E05);
  static const gold700 = Color(0xFF7A5200);
  static const gold800 = Color(0xFF5C4100);
  static const gold900 = Color(0xFF3A2700);
  static const gold925 = Color(0xFF3D2A00);
  static const gold950 = Color(0xFF1E1400);

  // ---- Light neutrals ----
  static const white = Color(0xFFFFFFFF);
  static const cream = Color(0xFFF7F5EF); // light background
  static const sand100 = Color(0xFFF2F0E9);
  static const sand200 = Color(0xFFECEAE3);
  static const sand300 = Color(0xFFE6E4DC);
  static const sand400 = Color(0xFFE0DED6);
  static const sand500 = Color(0xFFDEDCD4);
  static const stone300 = Color(0xFFC8CEC9);
  static const stone500 = Color(0xFF79827D);
  static const stone700 = Color(0xFF49524D);
  static const inkSoft = Color(0xFF2E3330);
  static const ink = Color(0xFF1B1F1C); // text on light

  // ---- Dark neutrals ----
  static const night0 = Color(0xFF0A110E);
  static const night = Color(0xFF0F1714); // dark background
  static const night100 = Color(0xFF141D19);
  static const night200 = Color(0xFF18221E);
  static const night300 = Color(0xFF1F2A25);
  static const night400 = Color(0xFF27332D);
  static const night500 = Color(0xFF343D39);
  static const slate700 = Color(0xFF3F4944);
  static const slate500 = Color(0xFF89938D);
  static const slate300 = Color(0xFFBFC9C3);
  static const mistSoft = Color(0xFFEFF1EE);
  static const mistDim = Color(0xFF2B322E);
  static const mist = Color(0xFFE3EAE6); // text on dark
  static const black = Color(0xFF000000);
  static const transparent = Color(0x00000000);
  static const scrimLight = Color(0x6B000000); // black 42%
  static const scrimDark = Color(0x99000000); // black 60%
  static const veilLight = Color(0x1AFFFFFF); // white 10%: watermark on green
  static const veilDark = Color(0x0FFFFFFF); // white 6%: watermark on deep green

  // ---- Blue (information / tertiary) ----
  static const blue50 = Color(0xFFD3E4FF);
  static const blue100 = Color(0xFFD6E4FA);
  static const blue300 = Color(0xFF9CC2FF);
  static const blue600 = Color(0xFF2F5D8C);
  static const blue650 = Color(0xFF1E5AA8);
  static const blue800 = Color(0xFF16457A);
  static const blue900 = Color(0xFF0A2E5C);
  static const blue950 = Color(0xFF002F65);
  static const blue990 = Color(0xFF001C38);

  // ---- Success ----
  static const success50 = Color(0xFFDCEFDD);
  static const success100 = Color(0xFFB9EBC0);
  static const success300 = Color(0xFF7BD389);
  static const success600 = Color(0xFF2E7D32);
  static const success800 = Color(0xFF1E4D24);
  static const success900 = Color(0xFF0F3D12);
  static const success950 = Color(0xFF00390A);

  // ---- Warning ----
  static const warning50 = Color(0xFFFFE7C2);
  static const warning100 = Color(0xFFFFDDB0);
  static const warning300 = Color(0xFFFFB74D);
  static const warning600 = Color(0xFFB26A00);
  static const warning800 = Color(0xFF5A3C00);
  static const warning900 = Color(0xFF4A2B00);
  static const warning950 = Color(0xFF3E2600);

  // ---- Danger / error ----
  static const danger50 = Color(0xFFF9DEDC);
  static const danger300 = Color(0xFFF2B8B5);
  static const danger600 = Color(0xFFB3261E);
  static const danger800 = Color(0xFF8C1D18);
  static const danger900 = Color(0xFF601410);
  static const danger950 = Color(0xFF410E0B);
}
