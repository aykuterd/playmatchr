import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/controllers/auth_controller.dart';

class SigninController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  var emailError = Rxn<String>();
  var passwordError = Rxn<String>();
  var generalError = Rxn<String>();
  var passwordVisible = false.obs;
  var termsAccepted = false.obs;

  @override
  void onInit() {
    super.onInit();
    emailController.addListener(_validateEmail);
    passwordController.addListener(_validatePassword);
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void _validateEmail() {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      emailError.value = 'E-posta boş bırakılamaz.';
    } else if (!GetUtils.isEmail(email)) {
      emailError.value = 'Geçerli bir e-posta adresi girin.';
    } else {
      emailError.value = null;
    }
  }

  void _validatePassword() {
    final password = passwordController.text.trim();
    if (password.isEmpty) {
      passwordError.value = 'Şifre boş bırakılamaz.';
    } else if (password.length < 6) {
      passwordError.value = 'Şifre en az 6 karakter olmalı.';
    } else if (!password.contains(RegExp(r'[0-9]'))) {
      passwordError.value = 'Şifre en az bir sayı içermeli.';
    } else if (!password.contains(RegExp(r'[a-z]'))) {
      passwordError.value = 'Şifre en az bir küçük harf içermeli.';
    } else if (!password.contains(RegExp(r'[A-Z]'))) {
      passwordError.value = 'Şifre en az bir büyük harf içermeli.';
    } else {
      passwordError.value = null;
    }
  }

  void togglePasswordVisibility() {
    passwordVisible.value = !passwordVisible.value;
  }

  void toggleTermsAcceptance() {
    termsAccepted.value = !termsAccepted.value;
  }

  Future<void> signInWithEmailAndPassword() async {
    _validateEmail();
    _validatePassword();

    if (emailError.value != null || passwordError.value != null) {
      return; // Do not proceed if there are validation errors
    }

    if (!termsAccepted.value) {
      generalError.value = 'Devam etmek için Kullanım Şartları ve Gizlilik Politikası\'nı kabul etmelisiniz.';
      return;
    }

    generalError.value = null; // Clear previous general errors

    await _authController.login(emailController.text.trim(), passwordController.text.trim());
  }

  Future<void> signInWithGoogle() async {
    if (!termsAccepted.value) {
      generalError.value = 'Devam etmek için Kullanım Şartları ve Gizlilik Politikası\'nı kabul etmelisiniz.';
      return;
    }

    generalError.value = null; // Clear previous general errors
    await _authController.signInWithGoogle();
  }

  Future<void> signInWithApple() async {
    if (!termsAccepted.value) {
      generalError.value = 'Devam etmek için Kullanım Şartları ve Gizlilik Politikası\'nı kabul etmelisiniz.';
      return;
    }

    generalError.value = null; // Clear previous general errors
    await _authController.signInWithApple();
  }
}
