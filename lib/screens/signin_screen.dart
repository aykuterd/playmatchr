import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/controllers/signin_controller.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SigninController controller = Get.put(SigninController());

    return Scaffold(
      appBar: AppBar(title: const Text('Playmatchr\'a Giriş Yap')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Tekrar Hoş Geldiniz!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Obx(
                () => TextField(
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-posta',
                    hintText: 'E-posta adresinizi girin',
                    prefixIcon: const Icon(Icons.email),
                    errorText: controller.emailError.value,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => TextField(
                  controller: controller.passwordController,
                  obscureText: !controller.passwordVisible.value,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    hintText: 'Şifrenizi girin',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.passwordVisible.value
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                    errorText: controller.passwordError.value,
                  ),
                ),
              ),
              Obx(
                () => controller.generalError.value != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Text(
                          controller.generalError.value!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),
              Obx(
                () => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: controller.termsAccepted.value,
                      onChanged: (value) => controller.toggleTermsAcceptance(),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                            children: [
                              const TextSpan(text: 'Devam ederek '),
                              TextSpan(
                                text: 'Kullanım Şartları',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    final url = Uri.parse('https://aykuterd.github.io/playmatchr/terms.html');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url, mode: LaunchMode.externalApplication);
                                    }
                                  },
                              ),
                              const TextSpan(text: ' ve '),
                              TextSpan(
                                text: 'Gizlilik Politikası',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    final url = Uri.parse('https://aykuterd.github.io/playmatchr/privacy.html');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url, mode: LaunchMode.externalApplication);
                                    }
                                  },
                              ),
                              const TextSpan(text: '\'nı kabul etmiş olursunuz.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.signInWithEmailAndPassword,
                  child: Text(
                    'Giriş Yap',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'VEYAYA',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: controller.signInWithGoogle,
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    height: 24.0,
                  ),
                  label: Text(
                    'Google ile Giriş Yap',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Apple Sign In butonu (sadece iOS'ta göster)
              if (Platform.isIOS)
                SizedBox(
                  width: double.infinity,
                  child: SignInWithAppleButton(
                    text: 'Apple ile Giriş Yap',
                    height: 50,
                    onPressed: controller.signInWithApple,
                  ),
                ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Get.offAllNamed('/signup');
                },
                child: Text(
                  'Hesabınız yok mu? Kaydolun',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    //);
  }
}
