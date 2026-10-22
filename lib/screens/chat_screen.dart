import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_bloom/models/user_model.dart';
import 'package:share_bloom/theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final UserModel currentUser;
  final UserModel otherUser;

  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get chatId {
    final users = [
      widget.currentUser.email,
      widget.otherUser.email
    ]..sort();
    return users.join("_");
  }

  Future<void> sendMessage() async {

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    /// SAVE MESSAGE
    await _db
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .add({
      "from": widget.currentUser.email,
      "to": widget.otherUser.email,
      "text": text,
      "createdAt": FieldValue.serverTimestamp(),
    });

    /// CREATE MESSAGE NOTIFICATION
    await _db.collection("notifications").add({
      "forUser": widget.otherUser.email,
      "title": "New Message",
      "body": "${widget.currentUser.name} sent you a message",
      "type": "chat",
      "chatId": chatId,

      /// sender info (for navigation)
      "otherUid": widget.currentUser.uid,
      "otherName": widget.currentUser.name,
      "otherEmail": widget.currentUser.email,
      "otherPhone": widget.currentUser.phone,
      "otherCity": widget.currentUser.city,
      "otherRole": widget.currentUser.role,

      "read": false,
      "status": "New",
      "createdAt": FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E1B),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(widget.otherUser.name),
      ),
      body: Column(
        children: [

          /// MESSAGE LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection("chats")
                  .doc(chatId)
                  .collection("messages")
                  .orderBy("createdAt")
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {

                    final msg =
                    messages[index].data()
                    as Map<String, dynamic>;

                    final isMe =
                        msg["from"] ==
                            widget.currentUser.email;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin:
                        const EdgeInsets.all(8),
                        padding:
                        const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppTheme.primary
                              : const Color(
                              0xFF1F1F35),
                          borderRadius:
                          BorderRadius.circular(
                              12),
                        ),
                        child: Text(
                          msg["text"] ?? "",
                          style: const TextStyle(
                              color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// MESSAGE INPUT
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style:
                    const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Type message...",
                      hintStyle: TextStyle(
                          color: Colors.white54),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send,
                      color: Colors.white),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}