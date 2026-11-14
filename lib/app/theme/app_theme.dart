import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_mood.dart';
import 'app_radius.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() => _buildTheme(Brightness.light);

  static ThemeData dark() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textTheme = AppTypography.textTheme(brightness);
    final mood = isDark ? AppMood.dark() : AppMood.light();
    final scheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppColors.primaryLight : AppColors.primaryDark,
      onPrimary: isDark ? AppColors.ink : Colors.white,
      secondary: AppColors.softHighlight,
      onSecondary: AppColors.ink,
      error: AppColors.expense,
      onError: Colors.white,
      surface: isDark ? AppColors.cardDark : AppColors.cardLight,
      onSurface: isDark ? const Color(0xFFF2F8FF) : AppColors.ink,
      surfaceContainerLowest:
          isDark ? const Color(0xFF13253D) : AppColors.backgroundLight,
      surfaceContainerLow:
          isDark ? const Color(0xFF192E4A) : const Color(0xFFE9F5FC),
      surfaceContainer:
          isDark ? const Color(0xFF203451) : const Color(0xFFF2F8FF),
      surfaceContainerHigh:
          isDark ? const Color(0xFF293F5E) : const Color(0xFFE1F1FA),
      surfaceContainerHighest:
          isDark ? const Color(0xFF354B69) : const Color(0xFFD9EAF6),
      onSurfaceVariant: isDark ? const Color(0xFFBCD0E2) : AppColors.mutedInk,
      outline: isDark ? AppColors.borderDark : const Color(0xFFA5C7DF),
      outlineVariant:
          isDark ? const Color(0xFF455D7A) : const Color(0xFFB8D3E5),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? Colors.white : AppColors.ink,
      onInverseSurface: isDark ? AppColors.ink : Colors.white,
      inversePrimary: isDark ? AppColors.primaryDark : AppColors.primaryLight,
    );

    final dividerColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      extensions: [mood],
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF173B5A),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: isDark ? Colors.white : const Color(0xFF173B5A),
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.54),
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : const Color(0xFF8EBBD8).withValues(alpha: 0.46),
            width: 0.7,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? const Color(0xFF223C5D) : const Color(0xFF21496B),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        height: 74,
        indicatorColor: isDark
            ? Colors.white.withValues(alpha: 0.10)
            : const Color(0xFF173B5A).withValues(alpha: 0.10),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          final activeColor = isDark ? Colors.white : const Color(0xFF173B5A);
          final inactiveColor = isDark
              ? Colors.white.withValues(alpha: 0.72)
              : const Color(0xFF173B5A).withValues(alpha: 0.76);
          return textTheme.labelLarge?.copyWith(
            color: selected ? activeColor : inactiveColor,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isDark
                ? (selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.72))
                : (selected
                    ? const Color(0xFF173B5A)
                    : const Color(0xFF173B5A).withValues(alpha: 0.76)),
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: dividerColor),
          minimumSize: const Size.fromHeight(46),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? scheme.primary : const Color(0xFF1E5A8D),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.78),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        prefixStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        suffixStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : const Color(0xFFA5C7DF),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : const Color(0xFFA5C7DF),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.34)
                : const Color(0xFF357BB3),
            width: 1.0,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: textTheme.titleSmall?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle:
            textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: dividerColor),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primary.withValues(alpha: 0.14),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          side: BorderSide(color: dividerColor),
        ),
        side: BorderSide(color: dividerColor),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: dividerColor,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onPrimary;
            }
            return scheme.onSurfaceVariant;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primary;
            }
            return scheme.surfaceContainerLow;
          }),
          side: WidgetStateProperty.all(BorderSide(color: dividerColor)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          textStyle: WidgetStateProperty.all(
            textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
