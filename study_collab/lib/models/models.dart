import 'package:flutter/material.dart';

// ── Session Types ──────────────────────────────
enum SessionVisibility { public, approval, private }
enum JoinStatus { notJoined, pending, joined, host }

class StudySession {
  final String id;
  final String title;
  final String subject;
  final Color subjectColor;
  final String hostName;
  final String hostAvatar;
  final String hostId;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String? description;
  final int capacity;
  final int joined;
  final SessionVisibility visibility;
  final List<String> hashtags;
  final List<Member> members;
  final List<JoinRequest> requests;
  final JoinStatus myStatus;

  const StudySession({required this.id,required this.title,
    required this.subject,required this.subjectColor,
    required this.hostName,required this.hostAvatar,
    required this.hostId,required this.date,
    required this.startTime,required this.endTime,
    required this.location,this.description,
    required this.capacity,required this.joined,
    required this.visibility,this.hashtags=const[],
    this.members=const[],this.requests=const[],
    this.myStatus=JoinStatus.notJoined});
}

class Member {
  final String id, name, avatar;
  final bool isHost;
  const Member({required this.id,required this.name,required this.avatar,this.isHost=false});
}

class JoinRequest {
  final String id, userId, name, avatar;
  final DateTime requestedAt;
  const JoinRequest({required this.id,required this.userId,required this.name,required this.avatar,required this.requestedAt});
}

class SharedFile {
  final String id, name, url, uploaderId, uploaderName;
  final String type; // pdf, image, link, doc
  final DateTime uploadedAt;
  const SharedFile({required this.id,required this.name,required this.url,
    required this.uploaderId,required this.uploaderName,
    required this.type,required this.uploadedAt});
}

class ChatMessage {
  final String id, senderId, senderName, senderAvatar, content;
  final DateTime sentAt;
  const ChatMessage({required this.id,required this.senderId,required this.senderName,
    required this.senderAvatar,required this.content,required this.sentAt});
}

class UserProfile {
  final String id, name, email, avatar, university, major;
  final int sessionsCount, friendsCount;
  final bool isFriend;
  const UserProfile({required this.id,required this.name,required this.email,
    required this.avatar,required this.university,required this.major,
    this.sessionsCount=0,this.friendsCount=0,this.isFriend=false});
}

class AppNotification {
  final String id, title, body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? targetId;
  const AppNotification({required this.id,required this.title,required this.body,
    required this.type,required this.createdAt,this.isRead=false,this.targetId});
}

enum NotificationType { joinRequest, requestApproved, sessionStartingSoon, friendRequest, general }

class DmConversation {
  final String userId, userName, userAvatar, lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  const DmConversation({
    required this.userId, required this.userName,
    required this.userAvatar, required this.lastMessage,
    required this.lastMessageTime, this.unreadCount = 0,
  });
  DmConversation copyWith({String? lastMessage, DateTime? lastMessageTime, int? unreadCount}) =>
      DmConversation(
        userId: userId, userName: userName, userAvatar: userAvatar,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageTime: lastMessageTime ?? this.lastMessageTime,
        unreadCount: unreadCount ?? this.unreadCount,
      );
}
