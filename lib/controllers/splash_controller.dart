import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onReady() {
    super.onReady();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Splash ekranının en az 1.5 saniye görünmesini sağlar
    await Future.delayed(const Duration(milliseconds: 1500));

    final user = _auth.currentUser;

    if (user == null) {
      Get.offAllNamed('/welcome');
    } else {
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists ||
            (userDoc.data() as Map<String, dynamic>)['username'] == null ||
            (userDoc.data() as Map<String, dynamic>)['username'].isEmpty) {
          Get.offAllNamed('/profile_setup');
        } else {
          Get.offAllNamed('/main_screen');
        }
      } catch (e) {
        // Hata durumunda (örn. internet yok), giriş ekranına yönlendir
        Get.offAllNamed('/welcome');
      }
    }
  }
}
