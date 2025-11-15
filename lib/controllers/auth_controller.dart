import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';

import '../models/firestore_models.dart';

class AuthController extends GetxController with WidgetsBindingObserver {
  static AuthController instance = Get.find();
  final user = Rx<User?>(FirebaseAuth.instance.currentUser);
  final userProfile = Rx<UserProfile?>(null);
  FirebaseAuth auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _lastSeenTimer;

  @override
  void onInit() {
    super.onInit();
    user.bindStream(auth.authStateChanges());
    ever(user, _fetchUserProfile);
    WidgetsBinding.instance.addObserver(this);
    _startLastSeenTimer();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _lastSeenTimer?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App foreground'a geldi
      updateLastSeen();
    } else if (state == AppLifecycleState.paused) {
      // App background'a gitti
      updateLastSeen();
    }
  }

  /// Her 5 dakikada bir lastSeen'i güncelle
  void _startLastSeenTimer() {
    _lastSeenTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      updateLastSeen();
    });
  }

  /// Son görülme zamanını güncelle
  Future<void> updateLastSeen() async {
    final currentUser = user.value;
    if (currentUser != null) {
      try {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'lastSeen': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Last seen updated');
      } catch (e) {
        debugPrint('❌ Error updating last seen: $e');
      }
    }
  }

  void _fetchUserProfile(User? user) {
    if (user != null) {
      _firestore.collection('users').doc(user.uid).snapshots().listen((
        snapshot,
      ) {
        if (snapshot.exists) {
          userProfile.value = UserProfile.fromFirestore(snapshot);
        }
      });
    } else {
      userProfile.value = null;
    }
  }

  Future<void> register(String email, String password) async {
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        // Create user profile
        debugPrint('Creating new user profile for registration...');
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'displayName': email.split('@')[0], // or some default
          'photoUrl': null,
          'createdAt': FieldValue.serverTimestamp(),
          'username': null,
          'bio': null,
          'friends': [],
          'pendingFriendRequests': [],
          'sentFriendRequests': [],
          'favoriteSports': [],
          'myTeams': [],
        });
        debugPrint('User profile created, redirecting to profile setup');
        Get.offAllNamed('/profile_setup');
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Kayıt Hatası',
        e.message ?? 'Bir hata oluştu.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Beklenmedik bir hata oluştu.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> login(String email, String password) async {
    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        // Check if user profile needs completion
        debugPrint('Email/Password login successful, checking user profile...');
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          // Create basic user profile if it doesn't exist
          debugPrint('User profile does not exist, creating basic profile...');
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'email': email,
                'displayName': email.split('@')[0],
                'photoUrl': null,
                'createdAt': FieldValue.serverTimestamp(),
                'username': null,
                'bio': null,
                'friends': [],
                'pendingFriendRequests': [],
                'sentFriendRequests': [],
                'favoriteSports': [],
                'myTeams': [],
              });
          debugPrint(
            'User profile created for existing user, redirecting to profile setup',
          );
          Get.offAllNamed('/profile_setup');
        } else {
          final data = userDoc.data();
          if (data == null ||
              data['username'] == null ||
              data['username'].isEmpty) {
            debugPrint(
              'User profile found but username is missing, redirecting to profile setup',
            );
            Get.offAllNamed('/profile_setup');
          } else {
            debugPrint('User profile complete, redirecting to main screen');
            Get.offAllNamed('/main_screen');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Giriş Hatası',
        e.message ?? 'Bir hata oluştu.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Beklenmedik bir hata oluştu.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign In...');

      // Google Sign In başlatılıyor
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('User cancelled Google Sign In');
        Get.snackbar(
          'Giriş İptal Edildi',
          'Google girişi iptal edildi.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return; // The user canceled the sign-in
      }

      debugPrint('Google user obtained: ${googleUser.email}');

      // Google Authentication bilgilerini al
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint('Google auth obtained');

      // Firebase credential oluştur
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('Firebase credential created');

      // Firebase ile giriş yap
      UserCredential userCredential = await auth.signInWithCredential(
        credential,
      );

      debugPrint('Firebase sign in successful');

      if (userCredential.user != null) {
        // Kullanıcı profilini kontrol et
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          // Create user profile
          debugPrint('Creating new user profile for Google Sign In...');
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'email': userCredential.user!.email,
                'displayName': userCredential.user!.displayName,
                'photoUrl': userCredential.user!.photoURL,
                'coverPhotoUrl': null, // Google'dan cover photo alamıyoruz
                'createdAt': FieldValue.serverTimestamp(),
                'username': null,
                'bio': null,
                'friends': [],
                'pendingFriendRequests': [],
                'sentFriendRequests': [],
                'favoriteSports': [],
                'myTeams': [],
                'favoriteUsers': [],
                'achievements': [],
              });
          debugPrint(
            'Google user profile created, redirecting to profile setup',
          );
          Get.offAllNamed('/profile_setup');
        } else {
          final data = userDoc.data() as Map<String, dynamic>?;
          if (data == null ||
              data['username'] == null ||
              data['username'].isEmpty) {
            debugPrint(
              'User profile found but username is missing, redirecting to profile setup',
            );
            Get.offAllNamed('/profile_setup');
          } else {
            debugPrint('User profile found, redirecting to main screen');
            Get.offAllNamed('/main_screen');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      Get.snackbar(
        'Google Giriş Hatası',
        e.message ?? 'Firebase authentication hatası: ${e.code}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e, stackTrace) {
      debugPrint('Google Sign In Error: $e');
      debugPrint('Stack trace: $stackTrace');
      Get.snackbar(
        'Hata',
        'Google girişi sırasında beklenmedik bir hata oluştu: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Sign in with Apple için helper fonksiyon
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// SHA256 hash oluştur
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> signInWithApple() async {
    try {
      debugPrint('Starting Apple Sign In...');

      // Nonce oluştur (replay attack önleme)
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Apple Sign In isteği
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      debugPrint('Apple credential obtained');

      // OAuth credential oluştur
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Firebase ile giriş yap
      UserCredential userCredential = await auth.signInWithCredential(
        oauthCredential,
      );

      debugPrint('Firebase sign in with Apple successful');

      if (userCredential.user != null) {
        // Kullanıcı profilini kontrol et
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          // Yeni kullanıcı profili oluştur
          debugPrint('Creating new user profile for Apple Sign In...');

          // Apple'dan gelen isim bilgisi (sadece ilk girişte gelir)
          String? displayName;
          if (appleCredential.givenName != null ||
              appleCredential.familyName != null) {
            displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
          }

          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'email': userCredential.user!.email ?? appleCredential.email,
                'displayName': displayName ?? userCredential.user!.email?.split('@')[0] ?? 'Apple User',
                'photoUrl': null, // Apple photo URL vermiyor
                'coverPhotoUrl': null,
                'createdAt': FieldValue.serverTimestamp(),
                'username': null,
                'bio': null,
                'friends': [],
                'pendingFriendRequests': [],
                'sentFriendRequests': [],
                'favoriteSports': [],
                'myTeams': [],
                'favoriteUsers': [],
                'achievements': [],
              });
          debugPrint(
            'Apple user profile created, redirecting to profile setup',
          );
          Get.offAllNamed('/profile_setup');
        } else {
          final data = userDoc.data() as Map<String, dynamic>?;
          if (data == null ||
              data['username'] == null ||
              data['username'].isEmpty) {
            debugPrint(
              'User profile found but username is missing, redirecting to profile setup',
            );
            Get.offAllNamed('/profile_setup');
          } else {
            debugPrint('User profile found, redirecting to main screen');
            Get.offAllNamed('/main_screen');
          }
        }
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint('SignInWithAppleAuthorizationException: ${e.code} - ${e.message}');

      if (e.code == AuthorizationErrorCode.canceled) {
        Get.snackbar(
          'Giriş İptal Edildi',
          'Apple ile giriş iptal edildi.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Apple Giriş Hatası',
          e.message?.toString() ?? 'Bilinmeyen hata: ${e.code}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      Get.snackbar(
        'Firebase Hatası',
        e.message ?? 'Firebase authentication hatası: ${e.code}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e, stackTrace) {
      debugPrint('Apple Sign In Error: $e');
      debugPrint('Stack trace: $stackTrace');
      Get.snackbar(
        'Hata',
        'Apple girişi sırasında beklenmedik bir hata oluştu: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> signOut() async {
    await auth.signOut();
    await _googleSignIn.signOut(); // Google oturumunu da kapat
    Get.offAllNamed('/welcome');
  }
}
