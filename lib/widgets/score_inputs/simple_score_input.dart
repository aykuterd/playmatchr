import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:playmatchr/theme/app_spacing.dart';

/// Basit X-Y skor input widget'ı
/// Futbol, Basketbol, Hentbol gibi sporlar için
class SimpleScoreInput extends StatelessWidget {
  final TextEditingController player1Controller;
  final TextEditingController player2Controller;
  final String player1Name;
  final String player2Name;
  final Function(String)? onChanged;

  const SimpleScoreInput({
    super.key,
    required this.player1Controller,
    required this.player2Controller,
    required this.player1Name,
    required this.player2Name,
    this.onChanged,
  });

  String? _validateScore(String? value) {
    if (value == null || value.isEmpty) {
      return 'Skor giriniz';
    }

    final score = int.tryParse(value);
    if (score == null) {
      return 'Geçerli bir sayı girin';
    }

    if (score < 0) {
      return 'Negatif olamaz';
    }

    if (score > 999) {
      return 'Çok yüksek skor';
    }

    return null;
  }

  /// Kazananı hesapla
  String? calculateWinner(String? player1Id, String? player2Id) {
    final p1Score = int.tryParse(player1Controller.text);
    final p2Score = int.tryParse(player2Controller.text);

    if (p1Score == null || p2Score == null) {
      return null;
    }

    if (p1Score > p2Score) {
      return player1Id;
    } else if (p2Score > p1Score) {
      return player2Id;
    } else {
      return null; // Beraberlik - turnuvalarda genellikle olmaz ama
    }
  }

  /// Skoru Map formatında al
  Map<String, dynamic> getScoreData() {
    return {
      'player1Score': int.tryParse(player1Controller.text) ?? 0,
      'player2Score': int.tryParse(player2Controller.text) ?? 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Maç Skoru',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Her oyuncu için final skorunu girin',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Skor input'ları
            Row(
              children: [
                // Player 1
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        player1Name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: player1Controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: InputDecoration(
                          hintText: '0',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.lg,
                          ),
                        ),
                        validator: _validateScore,
                        onChanged: (value) {
                          if (onChanged != null) {
                            onChanged!(value);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Separator
                const Padding(
                  padding: EdgeInsets.only(
                    top: 48, // Offset for player name
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                  ),
                  child: Text(
                    '-',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),

                // Player 2
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        player2Name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: player2Controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: InputDecoration(
                          hintText: '0',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.lg,
                          ),
                        ),
                        validator: _validateScore,
                        onChanged: (value) {
                          if (onChanged != null) {
                            onChanged!(value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Info message
            Center(
              child: Text(
                'Örnek: Futbol için 3-2, Basketbol için 85-78',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
