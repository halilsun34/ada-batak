import 'package:flutter/material.dart';
import '../../domain/models/game_settings.dart';

/// Ada Batak'a özgü altın ve maun/arduvaz detaylı, kategorize edilmiş
/// tamamen özgün ayarlar ve mod seçimi paneli.
/// Online butonu kesinlikle yoktur; yerine "NASIL OYNANIR" rehberi bulunur.
class SettingsModal extends StatelessWidget {
  final GameSettings settings;
  final ValueChanged<GameMode> onGameModeSelected;
  final VoidCallback onHowToPlayTap;
  final VoidCallback onTogglePlayHelp;
  final VoidCallback onToggleEqualCardsOrder;
  final VoidCallback onToggleSound;
  final VoidCallback onCycleTargetRounds;
  final VoidCallback onToggleDifficulty;
  final VoidCallback onToggleTrumpRule;
  final VoidCallback onSwitchTheme;
  final VoidCallback onClose;

  const SettingsModal({
    super.key,
    required this.settings,
    required this.onGameModeSelected,
    required this.onHowToPlayTap,
    required this.onTogglePlayHelp,
    required this.onToggleEqualCardsOrder,
    required this.onToggleSound,
    required this.onCycleTargetRounds,
    required this.onToggleDifficulty,
    required this.onToggleTrumpRule,
    required this.onSwitchTheme,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 344),
        child: Container(
          key: const Key('settings_modal_panel'),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xF6131C24),
                Color(0xF60A1015),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE5B84B),
              width: 1.8,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xB3000000),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Özgün Ada Batak Başlık Barı + Kapatma Butonu
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0x26E5B84B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0x66E5B84B),
                        ),
                      ),
                      child: const Icon(
                        Icons.style_rounded,
                        color: Color(0xFFE5B84B),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ADA BATAK',
                            style: TextStyle(
                              color: Color(0xFFE5B84B),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'Oyun Modu & Masa Ayarları',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      key: const Key('close_settings_button'),
                      onTap: onClose,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFD32F2F),
                              Color(0xFF9A0007),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFF8A80),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Divider(
                  color: const Color(0xFFE5B84B).withValues(alpha: 0.22),
                  height: 1,
                ),
                const SizedBox(height: 8),

                // 2. OYUN MODU SEÇİMİ Başlığı
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 5),
                  child: Text(
                    'OYUN MODLARI',
                    style: TextStyle(
                      color: Color(0xFF80CBC4),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),

                // 5 Oyun Modu Butonları (Zümrüt-Altın Kulüp Kartları)
                ...GameMode.values.map((mode) {
                  final isSelected = settings.gameMode == mode;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: _AdaModeButton(
                      key: Key('mode_btn_${mode.name}'),
                      label: mode.title,
                      icon: _iconForMode(mode),
                      isSelected: isSelected,
                      onTap: () => onGameModeSelected(mode),
                    ),
                  );
                }),

                const SizedBox(height: 4),

                // 3. MASA & OYUN TERCİHLERİ (2 Sütunlu Kompakt Kutu Grid)
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 5),
                  child: Text(
                    'MASA TERCİHLERİ',
                    style: TextStyle(
                      color: Color(0xFF80CBC4),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),

                // Satır 1: Yardım & Eş Kartları
                Row(
                  children: [
                    Expanded(
                      child: _AdaOptionTile(
                        key: const Key('toggle_help_button'),
                        icon: settings.playHelpEnabled
                            ? Icons.lightbulb_rounded
                            : Icons.lightbulb_outline_rounded,
                        label: settings.playHelpEnabled
                            ? 'YARDIM: AÇIK'
                            : 'YARDIM: KAPALI',
                        accentColor: const Color(0xFF26A69A),
                        onTap: onTogglePlayHelp,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AdaOptionTile(
                        key: const Key('toggle_equal_cards_button'),
                        icon: Icons.swap_vert_rounded,
                        label: settings.equalCardsOrder.label,
                        accentColor: const Color(0xFF26A69A),
                        onTap: onToggleEqualCardsOrder,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Satır 2: Ses & Bitiş Tur Sayısı
                Row(
                  children: [
                    Expanded(
                      child: _AdaOptionTile(
                        key: const Key('toggle_sound_button'),
                        icon: settings.soundEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        label: settings.soundEnabled
                            ? 'SES AÇIK'
                            : 'SES KAPALI',
                        accentColor: const Color(0xFF42A5F5),
                        onTap: onToggleSound,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AdaOptionTile(
                        key: const Key('cycle_target_rounds_button'),
                        icon: Icons.flag_rounded,
                        label: 'BİTİŞ : ${settings.targetRounds}',
                        accentColor: const Color(0xFF42A5F5),
                        onTap: onCycleTargetRounds,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Satır 3: Bot Zorluğu & Koz Kuralı
                Row(
                  children: [
                    Expanded(
                      child: _AdaOptionTile(
                        key: const Key('toggle_difficulty_button'),
                        icon: Icons.psychology_rounded,
                        label: settings.difficulty.label,
                        accentColor: const Color(0xFFEF5350),
                        onTap: onToggleDifficulty,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AdaOptionTile(
                        key: const Key('toggle_trump_rule_button'),
                        icon: Icons.shield_rounded,
                        label: settings.trumpRule == TrumpRule.alwaysSpades
                            ? 'KOZ: MAÇA'
                            : 'KOZ: SEÇMELİ',
                        accentColor: const Color(0xFFAB47BC),
                        onTap: onToggleTrumpRule,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Alt Satır: Diğer Temaya Geç & Nasıl Oynanır Rehberi
                Row(
                  children: [
                    Expanded(
                      child: _AdaActionFooterButton(
                        key: const Key('switch_theme_button'),
                        icon: Icons.palette_outlined,
                        label: 'DİĞER TEMAYA GEÇ',
                        gradientColors: const [
                          Color(0xFF00897B),
                          Color(0xFF004D40),
                        ],
                        borderColor: const Color(0xFF4DB6AC),
                        onTap: onSwitchTheme,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AdaActionFooterButton(
                        key: const Key('how_to_play_button'),
                        icon: Icons.menu_book_rounded,
                        label: 'NASIL OYNANIR',
                        gradientColors: const [
                          Color(0xFFC58B1B),
                          Color(0xFF7D5206),
                        ],
                        borderColor: const Color(0xFFFFD54F),
                        onTap: onHowToPlayTap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForMode(GameMode mode) {
    switch (mode) {
      case GameMode.ihaleli:
        return Icons.gavel_rounded;
      case GameMode.ihalesiz:
        return Icons.bolt_rounded;
      case GameMode.esli:
        return Icons.handshake_rounded;
      case GameMode.gommeli3lu:
        return Icons.layers_rounded;
      case GameMode.ucBesSekiz:
        return Icons.filter_3_rounded;
    }
  }
}

class _AdaModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AdaModeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isSelected
                  ? const [Color(0xFF146C54), Color(0xFF0C4736)]
                  : const [Color(0xFF1C2833), Color(0xFF151E27)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFE5B84B)
                  : Colors.white.withValues(alpha: 0.12),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? const Color(0xFFE5B84B)
                    : Colors.white60,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFFFFF59D)
                        : Colors.white.withValues(alpha: 0.88),
                    fontSize: 13.8,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x33E5B84B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'AKTİF',
                    style: TextStyle(
                      color: Color(0xFFE5B84B),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdaOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _AdaOptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2530),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFECEFF1),
                    fontSize: 11.8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdaActionFooterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final Color borderColor;
  final VoidCallback onTap;

  const _AdaActionFooterButton({
    super.key,
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
