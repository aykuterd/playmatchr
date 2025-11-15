import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/models/firestore_models.dart';
import 'package:playmatchr/services/firestore_service.dart';
import 'package:playmatchr/theme/app_colors.dart';
import 'package:playmatchr/theme/app_spacing.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];
  UserProfile? _currentUser;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final user = await _firestoreService.getUserProfile(userId);
      setState(() => _currentUser = user);
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _firestoreService.searchUsersByUsername(query);

      // Kendini sonuçlardan çıkar
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final filteredResults = results.where((user) => user.uid != currentUserId).toList();

      setState(() {
        _searchResults = filteredResults;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() => _isSearching = false);
      Get.snackbar('Hata', 'Arama sırasında bir hata oluştu');
    }
  }

  Future<void> _sendFriendRequest(String toUserId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      await _firestoreService.sendFriendRequest(currentUserId, toUserId);

      Get.snackbar('Başarılı', 'Arkadaşlık isteği gönderildi');

      // Current user'ı yeniden yükle ve arama sonuçlarını güncelle
      await _loadCurrentUser();
      await _searchUsers(_searchController.text);
    } catch (e) {
      debugPrint('Send friend request error: $e');
      Get.snackbar('Hata', 'İstek gönderilemedi');
    }
  }

  String _getButtonText(UserProfile user) {
    if (_currentUser == null) return 'Yükleniyor...';

    if (_currentUser!.friends.contains(user.uid)) {
      return 'Arkadaş';
    } else if (_currentUser!.sentFriendRequests.contains(user.uid)) {
      return 'İstek Gönderildi';
    } else if (_currentUser!.pendingFriendRequests.contains(user.uid)) {
      return 'Kabul Et';
    } else {
      return 'Arkadaş Ekle';
    }
  }

  bool _canSendRequest(UserProfile user) {
    if (_currentUser == null) return false;

    return !_currentUser!.friends.contains(user.uid) &&
           !_currentUser!.sentFriendRequests.contains(user.uid) &&
           !_currentUser!.pendingFriendRequests.contains(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arkadaş Ara'),
      ),
      body: Column(
        children: [
          // Arama çubuğu
          Padding(
            padding: AppSpacing.paddingLG,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _searchUsers(value);
              },
              decoration: InputDecoration(
                hintText: 'Kullanıcı adı ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Sonuçlar
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 80,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Kullanıcı adı ile arama yapın'
                                  : 'Sonuç bulunamadı',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: AppSpacing.paddingLG,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return _buildUserCard(user);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserProfile user) {
    final buttonText = _getButtonText(user);
    final canSend = _canSendRequest(user);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLG,
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: AppSpacing.paddingMD,
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withOpacity(0.2),
          foregroundColor: AppColors.primary,
          child: Text(
            user.displayName[0].toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${user.username}'),
            if (user.favoriteSports.isNotEmpty)
              Text(
                user.favoriteSports.join(', '),
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: canSend ? () => _sendFriendRequest(user.uid) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canSend ? AppColors.primary : AppColors.textTertiary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
          child: Text(buttonText, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
