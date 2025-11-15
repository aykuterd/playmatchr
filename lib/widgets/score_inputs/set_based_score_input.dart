import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:playmatchr/theme/app_spacing.dart';

/// Set bazlı skor input widget'ı
/// Tenis, Voleybol, Badminton gibi sporlar için
class SetBasedScoreInput extends StatefulWidget {
  final List<TextEditingController> player1SetControllers;
  final List<TextEditingController> player2SetControllers;
  final String player1Name;
  final String player2Name;
  final Function(String)? onChanged;
  final int initialNumberOfSets;

  const SetBasedScoreInput({
    super.key,
    required this.player1SetControllers,
    required this.player2SetControllers,
    required this.player1Name,
    required this.player2Name,
    this.onChanged,
    this.initialNumberOfSets = 3,
  });

  @override
  State<SetBasedScoreInput> createState() => SetBasedScoreInputState();
}

class SetBasedScoreInputState extends State<SetBasedScoreInput> {
  late int _numberOfSets;

  @override
  void initState() {
    super.initState();
    _numberOfSets = widget.initialNumberOfSets;
  }

  /// Set skorlarından kazananı hesapla
  String? calculateWinner(String? player1Id, String? player2Id) {
    int player1WonSets = 0;
    int player2WonSets = 0;

    for (int i = 0; i < _numberOfSets; i++) {
      final p1Score = int.tryParse(widget.player1SetControllers[i].text);
      final p2Score = int.tryParse(widget.player2SetControllers[i].text);

      if (p1Score != null && p2Score != null) {
        if (p1Score > p2Score) {
          player1WonSets++;
        } else if (p2Score > p1Score) {
          player2WonSets++;
        }
      }
    }

    // Kazananı belirle (best of 3: 2 set, best of 5: 3 set kazanmalı)
    final setsToWin = (_numberOfSets == 3) ? 2 : 3;

    if (player1WonSets >= setsToWin) {
      return player1Id;
    } else if (player2WonSets >= setsToWin) {
      return player2Id;
    } else {
      return null;
    }
  }

  /// Skorları Map formatında al
  Map<String, dynamic> getScoreData() {
    final Map<String, dynamic> player1Score = {};
    final Map<String, dynamic> player2Score = {};

    for (int i = 0; i < _numberOfSets; i++) {
      final p1Score = widget.player1SetControllers[i].text;
      final p2Score = widget.player2SetControllers[i].text;

      if (p1Score.isNotEmpty && p2Score.isNotEmpty) {
        player1Score['set${i + 1}'] = int.parse(p1Score);
        player2Score['set${i + 1}'] = int.parse(p2Score);
      }
    }

    return {
      'player1Score': player1Score,
      'player2Score': player2Score,
    };
  }

  /// Skorları validate et
  String? _validateScore(String? value, int setIndex) {
    if (value == null || value.isEmpty) {
      return null; // Set girilmemiş olabilir
    }

    final score = int.tryParse(value);
    if (score == null) {
      return 'Geçerli bir sayı girin';
    }

    if (score < 0) {
      return 'Negatif olamaz';
    }

    // Tenis/Voleybol kuralları: Set skoru genellikle 0-7 arası (tie-break hariç)
    if (score > 7) {
      // 7'den büyükse muhtemelen tie-break veya voleybol
      if (score > 30) {
        return 'Geçersiz skor';
      }
    }

    // Her iki oyuncunun skoru girildiyse kontrol et
    final player1Score = int.tryParse(widget.player1SetControllers[setIndex].text);
    final player2Score = int.tryParse(widget.player2SetControllers[setIndex].text);

    if (player1Score != null && player2Score != null) {
      // Tenis kuralları: Fark en az 2 olmalı (6-4, 7-5, vb.)
      final diff = (player1Score - player2Score).abs();

      if ((player1Score >= 6 || player2Score >= 6) &&
          diff < 2 &&
          player1Score < 7 &&
          player2Score < 7) {
        return 'Fark en az 2 olmalı';
      }

      // Her iki skor da 6'dan azsa geçersiz (Tenis için)
      if (player1Score < 6 && player2Score < 6) {
        return 'En az biri 6+ olmalı';
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Set selection
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Maç Formatı',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 3,
                      label: Text('Best of 3'),
                      icon: Icon(Icons.looks_3),
                    ),
                    ButtonSegment(
                      value: 5,
                      label: Text('Best of 5'),
                      icon: Icon(Icons.looks_5),
                    ),
                  ],
                  selected: {_numberOfSets},
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() {
                      _numberOfSets = newSelection.first;
                    });
                    if (widget.onChanged != null) {
                      widget.onChanged!('');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Score input
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set Skorları',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Her set için oyuncu skorlarını girin (örn: 6-4)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...List.generate(_numberOfSets, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildSetRow(index),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSetRow(int setIndex) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            'Set ${setIndex + 1}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: widget.player1SetControllers[setIndex],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: const InputDecoration(
              hintText: '0',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.md,
              ),
            ),
            validator: (value) => _validateScore(value, setIndex),
            onChanged: (value) {
              if (widget.onChanged != null) {
                widget.onChanged!(value);
              }
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            '-',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: widget.player2SetControllers[setIndex],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: const InputDecoration(
              hintText: '0',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.md,
              ),
            ),
            validator: (value) => _validateScore(value, setIndex),
            onChanged: (value) {
              if (widget.onChanged != null) {
                widget.onChanged!(value);
              }
            },
          ),
        ),
      ],
    );
  }
}
