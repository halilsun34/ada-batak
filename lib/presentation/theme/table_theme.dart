import 'package:flutter/material.dart';
import '../../domain/models/game_settings.dart';

/// Ada Batak özgün masa dokusu ve ahşap/altın renk paleti.
class TableThemeData {
  final TableThemeType type;
  final Color feltCenterColor;
  final Color feltEdgeColor;
  final Color feltTextureLineColor;
  final Color woodBaseColor;
  final Color woodDarkGrainColor;
  final Color woodHighlightColor;
  final Color goldBorderColor;
  final Color activeTurnGlowColor;

  const TableThemeData({
    required this.type,
    required this.feltCenterColor,
    required this.feltEdgeColor,
    required this.feltTextureLineColor,
    this.woodBaseColor = const Color(0xFF432616),
    this.woodDarkGrainColor = const Color(0xFF261309),
    this.woodHighlightColor = const Color(0xFF633A22),
    this.goldBorderColor = const Color(0xFFE5B84B),
    this.activeTurnGlowColor = const Color(0xFF00E5FF),
  });

  /// Ada Yeşili (Zümrüt-Turkuaz Kulüp Çuhası)
  static const TableThemeData emeraldGreen = TableThemeData(
    type: TableThemeType.emeraldGreen,
    feltCenterColor: Color(0xFF135E4B),
    feltEdgeColor: Color(0xFF072E24),
    feltTextureLineColor: Color(0x16FFFFFF),
    woodBaseColor: Color(0xFF3E2415),
    woodDarkGrainColor: Color(0xFF221108),
    woodHighlightColor: Color(0xFF5C3620),
    goldBorderColor: Color(0xFFE5B84B),
    activeTurnGlowColor: Color(0xFFFFD54F),
  );

  /// Boğaz Mavisi (Gece Safir Kulüp Çuhası)
  static const TableThemeData royalBlue = TableThemeData(
    type: TableThemeType.royalBlue,
    feltCenterColor: Color(0xFF163D6B),
    feltEdgeColor: Color(0xFF081B33),
    feltTextureLineColor: Color(0x16FFFFFF),
    woodBaseColor: Color(0xFF2D223B),
    woodDarkGrainColor: Color(0xFF171120),
    woodHighlightColor: Color(0xFF453559),
    goldBorderColor: Color(0xFFE0B44A),
    activeTurnGlowColor: Color(0xFF40C4FF),
  );

  static TableThemeData fromType(TableThemeType type) {
    switch (type) {
      case TableThemeType.emeraldGreen:
        return emeraldGreen;
      case TableThemeType.royalBlue:
        return royalBlue;
    }
  }
}
