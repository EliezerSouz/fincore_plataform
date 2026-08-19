import 'package:flutter/material.dart';
import 'theme_tokens.dart';

/// Tokens específicos para o botão primário (PrimaryButtonComponentToken).
class PrimaryButtonComponentToken {
  final Color backgroundColor;
  final Color foregroundColor;
  final Color hoverColor;
  final Color activeColor;
  final Color disabledBackgroundColor;
  final Color disabledForegroundColor;
  final EdgeInsetsGeometry padding;

  const PrimaryButtonComponentToken({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.hoverColor,
    required this.activeColor,
    required this.disabledBackgroundColor,
    required this.disabledForegroundColor,
    required this.padding,
  });

  factory PrimaryButtonComponentToken.resolve(ThemeTokens theme, double densityFactor) {
    return PrimaryButtonComponentToken(
      backgroundColor: theme.actionPrimary,
      foregroundColor: theme.textOnAction,
      hoverColor: theme.actionHover,
      activeColor: theme.actionActive,
      disabledBackgroundColor: theme.actionDisabled,
      disabledForegroundColor: theme.textMuted,
      padding: EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 14.0 - (2.0 * densityFactor),
      ),
    );
  }
}

/// Tokens específicos para campos de input (TextFieldComponentToken).
class TextFieldComponentToken {
  final Color fillNormal;
  final Color borderNormal;
  final Color borderFocused;
  final Color borderError;
  final Color textNormal;
  final Color textPlaceholder;
  final EdgeInsetsGeometry contentPadding;

  const TextFieldComponentToken({
    required this.fillNormal,
    required this.borderNormal,
    required this.borderFocused,
    required this.borderError,
    required this.textNormal,
    required this.textPlaceholder,
    required this.contentPadding,
  });

  factory TextFieldComponentToken.resolve(ThemeTokens theme, double densityFactor) {
    return TextFieldComponentToken(
      fillNormal: theme.inputBackground,
      borderNormal: theme.inputBorder,
      borderFocused: theme.inputBorderFocused,
      borderError: theme.danger,
      textNormal: theme.textPrimary,
      textPlaceholder: theme.textMuted,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 14.0,
        vertical: 12.0 - (2.0 * densityFactor),
      ),
    );
  }
}

/// Tokens específicos para painéis e cards (CardComponentToken).
class CardComponentToken {
  final Color backgroundColor;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  const CardComponentToken({
    required this.backgroundColor,
    required this.borderColor,
    required this.padding,
  });

  factory CardComponentToken.resolve(ThemeTokens theme) {
    return CardComponentToken(
      backgroundColor: theme.surface,
      borderColor: theme.border,
      padding: const EdgeInsets.all(16.0),
    );
  }
}
