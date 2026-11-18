import 'package:flutter/material.dart';

/// Online butonu yerine konulan tamamen offline "Nasıl Oynanır" rehber ekranı/modalı.
class HowToPlayModal extends StatelessWidget {
  final VoidCallback onClose;

  const HowToPlayModal({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340, maxHeight: 540),
        child: Container(
          key: const Key('how_to_play_modal'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xF51F211E),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFD59B1A),
              width: 1.8,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFFFFD54F),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'ADA BATAK — NASIL OYNANIR?',
                      style: TextStyle(
                        color: Color(0xFFFFD54F),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('close_how_to_play_button'),
                    onPressed: onClose,
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const Divider(color: Colors.white24),
              const SizedBox(height: 6),
              const Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RuleSection(
                        title: '1. Temel Kurallar',
                        body:
                            '• 52 kartlık deste 4 oyuncuya 13\'er kart olarak dağıtılır.\n'
                            '• Kart büyüklüğü: As (A) > Papaz (K) > Kız (Q) > Vale (J) > 10..2.\n'
                            '• İhaleyi en yüksek sayıyı veren oyuncu alır ve ilk kartı atar.\n'
                            '• Herkes PAS geçerse el otomatik yeniden dağıtılır.',
                      ),
                      _RuleSection(
                        title: '2. El Oynama & Yükseltme Zorunluluğu',
                        body:
                            '• Ortaya atılan ilk kartın rengine uymak zorunludur.\n'
                            '• Elinizde o renkten masadaki en büyük karttan daha büyüğü varsa büyütmek zorunludur.\n'
                            '• Açılan renk elinizde yoksa KOZ (Maça ♠) atmak zorunludur.\n'
                            '• Kozunuz da yoksa istediğiniz bir kartı atabilirsiniz.\n'
                            '• Maça çıkmadan (koz kırılmadan) elinizde başka renk varken maça ile başlayamazsınız.',
                      ),
                      _RuleSection(
                        title: '3. Puanlama',
                        body:
                            '• İhaleyi alan oyuncu teklif ettiği sayı kadar veya daha fazla el alırsa ihalesi kadar puan kazanır; alamazsa ihalesi kadar puan kaybeder (batar).\n'
                            '• Diğer oyuncular aldıkları el sayısı kadar puan kazanır.',
                      ),
                      _RuleSection(
                        title: '4. Oyun Modları',
                        body:
                            '• İhaleli Oyun: Klasik 4 kişilik ihaleli batak.\n'
                            '• İhalesiz Oyun: İhale olmadan doğrudan koz Maça ile oynanır.\n'
                            '• Eşli Oyun: Siz ve karşınızdaki Bora ortak takım olursunuz.\n'
                            '• Gömmeli 3\'lü Oyun: 3 kişiyle (16 kart + 4 gömü) oynanır; ihaleyi alan yerdeki 4 kartı alıp 4 kart gömer.\n'
                            '• 3-5-8 Oyunu: 3 kişiyle oynanır; hedefler sırasıyla 3, 5 ve 8 eldir.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  onPressed: onClose,
                  child: const Text(
                    'ANLADIM',
                    style: TextStyle(fontWeight: FontWeight.w900),
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

class _RuleSection extends StatelessWidget {
  final String title;
  final String body;

  const _RuleSection({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF00E676),
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
