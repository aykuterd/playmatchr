import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:playmatchr/controllers/match_controller.dart';
import 'package:playmatchr/models/firestore_models.dart';

class InvitationsScreen extends StatelessWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MatchController matchController = Get.find<MatchController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Davetiyeler'),
      ),
      body: Obx(
        () => ListView.builder(
          itemCount: matchController.invitations.value.length,
          itemBuilder: (context, index) {
            final Invitation invitation = matchController.invitations.value[index];
            return ListTile(
              title: Text('New invitation from ${invitation.fromUserId}'),
              subtitle: Text('Match ID: ${invitation.matchId}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {
                      matchController.acceptInvitation(invitation);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      matchController.declineInvitation(invitation);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}