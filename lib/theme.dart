import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Nutrimate design tokens.
///
/// Values mirror `Nutrimate Design System/colors_and_type.css` so the Flutter
/// app, marketing site and admin dashboard share one source of truth.
class NV {
  // Brand — single green. Used at most once per viewport.
  static const accent = Color(0xFF2F7D4A);
  static const accentSoft = Color(0xFFE6F1E9);
  static const accentDeep = Color(0xFF1F5C36);

  // Sage — quiet secondary used on dark cards / illustration accents.
  static const sage = Color(0xFF4E7A59);
  static const sageSoft = Color(0xFFDDE9E1);

  // Surfaces — clean white for light mode.
  static const bg = Color(0xFFFFFFFF);
  static const bgAlt = Color(0xFFF5F5F5);
  static const bgDark = Color(0xFF0F1512);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF161D19);
  static const surfaceMuted = Color(0xFFF7F7F8);
  static const surfaceMutedDark = Color(0xFF1B2420);
  static const surfaceInk = Color(0xFF111111);
  static const border = Color(0xFFE5E7EB);
  static const borderDark = Color(0xFF22302A);
  static const borderStrong = Color(0xFFD1D5DB);

  // Text — warm near-black. Tabular numerals are enabled in textTheme.
  static const text = Color(0xFF14110E);
  static const textDark = Color(0xFFF1F4ED);
  static const textMuted = Color(0xFF5A6358);
  static const textMutedDark = Color(0xFF8FA191);
  static const textSoft = Color(0xFF8C9587);

  // Semantic
  static const warn = Color(0xFFA66B14);
  static const warnSoft = Color(0xFFFAF1DC);
  static const err = Color(0xFFB13338);
  static const errSoft = Color(0xFFFAEAEB);
  static const ok = Color(0xFF2F7D4A);
}

/// Spacing scale — multiples of 4. Use these instead of magic numbers.
class NVSpace {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
  static const double x16 = 64;
}

/// Corner radii — three sizes only.
class NVRadius {
  static const double card = 20;
  static const double cardLg = 28;
  static const double chip = 999;
  static const double field = 16;
  static const double cardSm = 14;
}

/// Motion tokens.
class NVMotion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 480);
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);
}

class VitaminHue {
  final Color fill;
  final Color bg;
  const VitaminHue(this.fill, this.bg);
}

const Map<String, VitaminHue> vitaminColors = {
  'A': VitaminHue(Color(0xFF8A6010), Color(0xFFFBF3E0)),
  'B1': VitaminHue(Color(0xFFC68B1C), Color(0xFFF5E8C8)),
  'B2': VitaminHue(Color(0xFFB6A322), Color(0xFFF2EFCB)),
  'B3': VitaminHue(Color(0xFFC06B2F), Color(0xFFF5E1D3)),
  'B5': VitaminHue(Color(0xFF26827D), Color(0xFFDDEDEB)),
  'C': VitaminHue(Color(0xFF1F5C36), Color(0xFFE6F1E9)),
  'D': VitaminHue(Color(0xFF8A6010), Color(0xFFFBF3E0)),
  'E': VitaminHue(Color(0xFF5A4592), Color(0xFFEBE6F6)),
  'K': VitaminHue(Color(0xFF3A6B88), Color(0xFFDDE7EE)),
  'B6': VitaminHue(Color(0xFFB23A5C), Color(0xFFF4E0E6)),
  'B7': VitaminHue(Color(0xFF9B4A8B), Color(0xFFF1E1EE)),
  'B12': VitaminHue(Color(0xFF1A6C74), Color(0xFFDDF0F2)),
  'B9': VitaminHue(Color(0xFF6B8E3A), Color(0xFFE9EFDA)),
  'Fe': VitaminHue(Color(0xFF7A3530), Color(0xFFF0E0DC)),
  'Zn': VitaminHue(Color(0xFF3F4F62), Color(0xFFE1E5EC)),
  'Mg': VitaminHue(Color(0xFF1A6E68), Color(0xFFDDF0ED)),
  'Ca': VitaminHue(Color(0xFF6B4A8A), Color(0xFFEDE0F5)),
  'Kp': VitaminHue(Color(0xFFC0782E), Color(0xFFF5E4D0)),
  'Na': VitaminHue(Color(0xFF687684), Color(0xFFE4E8EC)),
  'P': VitaminHue(Color(0xFF2E7E95), Color(0xFFDCECF0)),
  'Se': VitaminHue(Color(0xFFAA7B24), Color(0xFFF0E5CD)),
  'Mn': VitaminHue(Color(0xFF954C72), Color(0xFFF0DFE8)),
  'S': VitaminHue(Color(0xFF77723B), Color(0xFFECEAD7)),
  'Protein': VitaminHue(Color(0xFF7A3830), Color(0xFFF0DED8)),
  'Fiber': VitaminHue(Color(0xFF3A6030), Color(0xFFDDE8D8)),
  'Carbs': VitaminHue(Color(0xFF6A5C20), Color(0xFFEDE8D0)),
  'Fat': VitaminHue(Color(0xFF7A5830), Color(0xFFEDE0D0)),
};

const Map<String, String> nutrientShortLabels = {
  'Kp': 'K+',
  'Protein': 'PRO',
  'Fiber': 'FIB',
  'Carbs': 'CARB',
  'Fat': 'FAT',
};

/// Typography pairing — Inter as the body face, Fraunces only for
/// editorial display titles and the splash wordmark.
TextStyle nvDisplay(double size, {Color? color, FontWeight weight = FontWeight.w400}) {
  return GoogleFonts.fraunces(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.05,
    letterSpacing: -size * 0.025,
  );
}

TextStyle nvNumber(double size, {Color? color, FontWeight weight = FontWeight.w700}) {
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.0,
    letterSpacing: -size * 0.02,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

TextStyle nvEyebrow({Color? color}) {
  return GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: 0.88, // 0.08em at 11px
    height: 1.2,
  );
}

class NVTheme {
  static SystemUiOverlayStyle lightOverlay = const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static SystemUiOverlayStyle darkOverlay = const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: NV.bgDark,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData light() => _build(brightness: Brightness.light);
  static ThemeData dark() => _build(brightness: Brightness.dark);

  static ThemeData _build({required Brightness brightness, ColorScheme? dynamicScheme}) {
    final dark = brightness == Brightness.dark;
    final tc = dark ? NV.textDark : NV.text;
    final mc = dark ? NV.textMutedDark : NV.textMuted;
    final bg = dark ? NV.bgDark : NV.bg;
    final surface = dark ? NV.surfaceDark : NV.surface;
    final border = dark ? NV.borderDark : NV.border;

    final base = GoogleFonts.interTextTheme(
      _baseTextTheme(tc, mc),
    );

    final scheme = dynamicScheme ?? ColorScheme.fromSeed(
      seedColor: NV.accent,
      brightness: brightness,
      primary: NV.accent,
      onPrimary: Colors.white,
      secondary: NV.sage,
      onSecondary: Colors.white,
      error: NV.err,
      onError: Colors.white,
      surface: surface,
      onSurface: tc,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      dividerColor: border,
      splashFactory: InkSparkle.splashFactory,
      textTheme: base,
      iconTheme: IconThemeData(color: tc, size: 22),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: NV.accent,
        selectionColor: NV.accent.withValues(alpha: 0.22),
        selectionHandleColor: NV.accent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: tc,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: NVSpace.x5,
        systemOverlayStyle: dark ? darkOverlay : lightOverlay,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: tc,
          letterSpacing: -0.2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: mc, fontWeight: FontWeight.w400),
        labelStyle: TextStyle(color: mc, fontWeight: FontWeight.w500),
        floatingLabelStyle: const TextStyle(color: NV.accent, fontWeight: FontWeight.w600),
        prefixIconColor: mc,
        suffixIconColor: mc,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NVRadius.field),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NVRadius.field),
          borderSide: const BorderSide(color: NV.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NVRadius.field),
          borderSide: const BorderSide(color: NV.err),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NVRadius.field),
          borderSide: const BorderSide(color: NV.err, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NV.surfaceInk,
          foregroundColor: const Color(0xFFFAFAFA),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
          minimumSize: const Size.fromHeight(54),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: NV.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
          minimumSize: const Size.fromHeight(54),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: NV.accent,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.05,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NVRadius.field),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tc,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.05,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NVRadius.card),
          side: BorderSide(color: border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: dark ? NV.surfaceMutedDark : NV.surfaceMuted,
        side: BorderSide(color: border),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tc,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: const StadiumBorder(),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NVRadius.cardLg),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: tc,
          letterSpacing: -0.2,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: tc,
          height: 1.45,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: NV.surfaceInk,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFFFAFAFA),
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NVRadius.field),
        ),
        actionTextColor: NV.accent,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: NV.accent,
        linearTrackColor: NV.border,
        circularTrackColor: NV.border,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : NV.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? NV.accent : border,
        ),
      ),
    );
  }

  static TextTheme _baseTextTheme(Color tc, Color mc) {
    final tabular = [const FontFeature.tabularFigures()];
    return TextTheme(
      // Editorial display — Fraunces (set inline where needed via nvDisplay).
      displayLarge: TextStyle(
        color: tc,
        fontSize: 44,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.4,
        height: 1.05,
      ),
      displayMedium: TextStyle(
        color: tc,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
        height: 1.06,
      ),
      displaySmall: TextStyle(
        color: tc,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.9,
        height: 1.08,
      ),
      headlineLarge: TextStyle(
        color: tc,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.12,
      ),
      headlineMedium: TextStyle(
        color: tc,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.18,
      ),
      headlineSmall: TextStyle(
        color: tc,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.25,
      ),
      titleLarge: TextStyle(
        color: tc,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        color: tc,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.35,
      ),
      titleSmall: TextStyle(
        color: tc,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      bodyLarge: TextStyle(color: tc, fontSize: 15, height: 1.5),
      bodyMedium: TextStyle(color: tc, fontSize: 14, height: 1.5),
      bodySmall: TextStyle(color: mc, fontSize: 12, height: 1.45),
      labelLarge: TextStyle(
        color: tc,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        color: mc,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: TextStyle(
        color: mc,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.88,
        fontFeatures: tabular,
      ),
    );
  }
}

/// Helper to pick dark/light colors.
class NVColors {
  final bool dark;
  NVColors(this.dark);

  Color get bg => dark ? NV.bgDark : NV.bg;
  Color get surface => dark ? NV.surfaceDark : NV.surface;
  Color get surfaceMuted => dark ? NV.surfaceMutedDark : NV.surfaceMuted;
  Color get border => dark ? NV.borderDark : NV.border;
  Color get text => dark ? NV.textDark : NV.text;
  Color get textMuted => dark ? NV.textMutedDark : NV.textMuted;

  static NVColors of(BuildContext context) =>
      NVColors(Theme.of(context).brightness == Brightness.dark);
}
