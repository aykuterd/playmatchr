import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/screens/match_result_confirmation_screen.dart';
import 'package:playmatchr/screens/match_result_screen.dart';
import 'package:playmatchr/screens/rate_match_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  // ... (rest of the file is unchanged until _buildResultActionButton)

  Widget _buildResultActionButton(Match match, String userId) {
    final bool hasUserRated = match.playerRatings.any(
      (rating) => rating['raterId'] == userId,
    );

    if (match.resultStatus == 'no_result') {
      // User can submit result
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Get.back(); // Close bottom sheet
            Get.to(() => MatchResultScreen(matchId: match.id));
          },
          icon: const Icon(Icons.sports_score),
          label: const DefaultTextStyle(
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Roboto',
            ),
            child: Text('Maç Sonucunu Gir'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    } else if (match.resultStatus == 'pending_confirmation') {
      // Check if user has already confirmed
      if (match.resultConfirmedBy.contains(userId)) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.hourglass_empty, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                  child: const Text(
                    'Sonucu onayladınız. Diğer oyuncuların onayı bekleniyor.',
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // User needs to confirm
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Get.back(); // Close bottom sheet
              Get.to(() => MatchResultConfirmationScreen(matchId: match.id));
            },
            icon: const Icon(Icons.check_circle),
            label: const DefaultTextStyle(
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Roboto',
              ),
              child: Text('Maç Sonucunu Onayla'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      }
    } else if (match.resultStatus == 'confirmed') {
      if (hasUserRated) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green[700]),
              const SizedBox(width: 12),
              Expanded(
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                  child: const Text(
                    'Oyuncuları zaten değerlendirdiniz. Teşekkürler!',
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Get.back(); // Close bottom sheet
              Get.to(() => RateMatchScreen(match: match));
            },
            icon: const Icon(Icons.star_rate_rounded),
            label: const DefaultTextStyle(
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Roboto',
              ),
              child: Text('Oyuncuları Değerlendir'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      }
    } else if (match.resultStatus == 'disputed') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[700]),
            const SizedBox(width: 12),
            Expanded(
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Roboto',
                ),
                child: const Text(
                  'Maç sonucunda anlaşmazlık var. Bu maç için puan işlemi yapılmayacak.',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

// Wave Clipper for Home Header
class _HomeWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 20);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 40);
    var secondEndPoint = Offset(size.width, size.height - 10);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
