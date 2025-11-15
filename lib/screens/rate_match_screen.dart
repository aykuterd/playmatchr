import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/controllers/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RateMatchScreen extends StatefulWidget {
  final Match match;

  const RateMatchScreen({Key? key, required this.match}) : super(key: key);

  @override
  _RateMatchScreenState createState() => _RateMatchScreenState();
}

class _RateMatchScreenState extends State<RateMatchScreen> {
  final AuthController authController = Get.find<AuthController>();
  late List<TeamPlayer> _playersToRate;
  final Map<String, double> _sportsmanshipRatings = {};
  final Map<String, String> _punctualityRatings = {}; // 'geldi' or 'gelmedi'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final currentUserId = authController.user.value?.uid;

    _playersToRate = [
      ...widget.match.team1Players,
      ...widget.match.team2Players
    ].where((player) => currentUserId != null && player.userId != currentUserId).toList();

    for (var player in _playersToRate) {
      _sportsmanshipRatings[player.userId] = 3.0; // Default to 3 stars
      _punctualityRatings[player.userId] = 'geldi'; // Default to 'geldi'
    }
  }

  Future<void> _submitRatings() async {
    if (_isLoading) return;

    final raterId = authController.user.value?.uid;
    if (raterId == null) {
      Get.snackbar(
        'Hata',
        'Kullanıcı bilgisi alınamadı. Lütfen giriş yapın.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final newRatings = <Map<String, dynamic>>[];

    for (var player in _playersToRate) {
      newRatings.add({
        'raterId': raterId,
        'ratedUserId': player.userId,
        'sportsmanship': _sportsmanshipRatings[player.userId],
        'punctuality': _punctualityRatings[player.userId],
        'ratedAt': Timestamp.now(),
      });
    }

    try {
      final matchRef = FirebaseFirestore.instance.collection('matches').doc(widget.match.id);

      // Use a transaction to safely update the ratings
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final freshSnap = await transaction.get(matchRef);
        final freshMatch = Match.fromFirestore(freshSnap);

        // Filter out any ratings this user has already submitted to prevent duplicates
        final existingRatings = freshMatch.playerRatings
            .where((rating) => rating['raterId'] != raterId)
            .toList();
        
        final updatedRatings = [...existingRatings, ...newRatings];

        transaction.update(matchRef, {'playerRatings': updatedRatings});
      });

      // TODO: In a real app, you would trigger a Cloud Function here
      // to recalculate and update the UserProfile stats for each rated user.
      // For now, we'll skip this step as it's complex for client-side.

      Get.snackbar(
        'Başarılı',
        'Değerlendirmeleriniz başarıyla gönderildi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Pop back to home screen
      Get.offAllNamed('/home');

    } catch (e) {
      debugPrint('Error submitting ratings: $e');
      Get.snackbar(
        'Hata',
        'Değerlendirmeler gönderilirken bir hata oluştu. Lütfen tekrar deneyin.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oyuncuları Değerlendir'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body: _playersToRate.isEmpty
          ? const Center(
              child: Text('Değerlendirilecek başka oyuncu bulunmuyor.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _playersToRate.length,
              itemBuilder: (context, index) {
                final player = _playersToRate[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sportmenlik',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        RatingBar.builder(
                          initialRating: _sportsmanshipRatings[player.userId]!,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: false,
                          itemCount: 5,
                          itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) {
                            setState(() {
                              _sportsmanshipRatings[player.userId] = rating;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Dakiklik',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        ToggleButtons(
                          isSelected: [
                            _punctualityRatings[player.userId] == 'geldi',
                            _punctualityRatings[player.userId] == 'gelmedi',
                          ],
                          onPressed: (int newIndex) {
                            setState(() {
                              _punctualityRatings[player.userId] =
                                  newIndex == 0 ? 'geldi' : 'gelmedi';
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          selectedColor: Colors.white,
                          fillColor: _punctualityRatings[player.userId] == 'geldi'
                              ? Colors.green
                              : Colors.red,
                          children: const <Widget>[
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text('Geldi'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text('Gelmedi'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _submitRatings,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : const Text(
                  'Değerlendirmeleri Gönder',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
        ),
      ),
    );
  }
}
