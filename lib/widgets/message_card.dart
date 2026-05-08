import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../utils/constants.dart';

/// Reusable card widget for displaying a single message
class MessageCard extends StatelessWidget {
  final MessageModel message;
  final VoidCallback? onRead;
  final VoidCallback? onDelete;

  const MessageCard({
    super.key,
    required this.message,
    this.onRead,
    this.onDelete,
  });

  IconData _getAppIcon(String appSource) {
    switch (appSource.toLowerCase()) {
      case 'whatsapp':
        return Icons.chat;
      case 'telegram':
        return Icons.send;
      case 'sms':
        return Icons.sms;
      case 'messenger':
        return Icons.messenger_outline;
      case 'instagram':
        return Icons.camera_alt;
      default:
        return Icons.notifications;
    }
  }

  Color _getAppColor(String appSource) {
    switch (appSource.toLowerCase()) {
      case 'whatsapp':
        return const Color(0xFF25D366);
      case 'telegram':
        return const Color(0xFF0088CC);
      case 'sms':
        return const Color(0xFF4CAF50);
      case 'messenger':
        return const Color(0xFF0084FF);
      case 'instagram':
        return const Color(0xFFE1306C);
      default:
        return AppConstants.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColor = _getAppColor(message.appSource);
    final timeStr = DateFormat('hh:mm a').format(message.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        onTap: onRead,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App icon circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: appColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getAppIcon(message.appSource), color: appColor, size: 22),
              ),
              const SizedBox(width: 12),
              // Message content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          message.senderName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.messageContent,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // App badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: appColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            message.appSource,
                            style: TextStyle(
                              fontSize: 11,
                              color: appColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Unread dot
                        if (!message.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Delete button
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: onDelete,
                  color: Colors.red.withOpacity(0.6),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
