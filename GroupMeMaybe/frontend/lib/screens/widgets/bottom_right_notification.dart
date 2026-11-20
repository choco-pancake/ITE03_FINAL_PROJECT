import 'dart:async';

import 'package:flutter/material.dart';

enum NotificationType { success, error, info, warning }

class AppNotification {
  static void notify(
    BuildContext context,
    String message, {
    String? title,
    bool isError = false,
    NotificationType? type,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final effectiveType =
        type ?? (isError ? NotificationType.error : NotificationType.success);
    switch (effectiveType) {
      case NotificationType.error:
        _showFloating(
          context: context,
          title: title ?? 'Notice',
          message: message,
          icon: Icons.error_outline,
          iconColor: const Color(0xFFEF4444),
          borderColor: const Color(0xFFDC2626).withValues(alpha: 0.4),
          actionLabel: actionLabel,
          onAction: onAction,
        );
      case NotificationType.warning:
        _showFloating(
          context: context,
          title: title ?? 'Warning',
          message: message,
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFFBBF24),
          borderColor: const Color(0xFFD97706).withValues(alpha: 0.4),
          actionLabel: actionLabel,
          onAction: onAction,
        );
      case NotificationType.info:
        _showFloating(
          context: context,
          title: title ?? 'Info',
          message: message,
          icon: Icons.info_outline,
          iconColor: const Color(0xFF38BDF8),
          borderColor: const Color(0xFF0284C7).withValues(alpha: 0.4),
          actionLabel: actionLabel,
          onAction: onAction,
        );
      case NotificationType.success:
        _showFloating(
          context: context,
          title: title ?? 'Success',
          message: message,
          icon: Icons.check_circle_outline,
          iconColor: const Color(0xFF22C55E),
          borderColor: const Color(0xFF16A34A).withValues(alpha: 0.4),
          actionLabel: actionLabel,
          onAction: onAction,
        );
    }
  }

  static void showSuccess(
    BuildContext context,
    String messageOrTitle, [
    String? optionalMessage,
  ]) {
    _showFloating(
      context: context,
      title: optionalMessage != null ? messageOrTitle : 'Success',
      message: optionalMessage ?? messageOrTitle,
      icon: Icons.check_circle_outline,
      iconColor: const Color(0xFF22C55E),
      borderColor: const Color(0xFF16A34A).withValues(alpha: 0.4),
    );
  }

  static void showError(
    BuildContext context,
    String messageOrTitle, [
    String? optionalMessage,
  ]) {
    _showFloating(
      context: context,
      title: optionalMessage != null ? messageOrTitle : 'Notice',
      message: optionalMessage ?? messageOrTitle,
      icon: Icons.error_outline,
      iconColor: const Color(0xFFEF4444),
      borderColor: const Color(0xFFDC2626).withValues(alpha: 0.4),
    );
  }

  static void showInfo(
    BuildContext context,
    String messageOrTitle, [
    String? optionalMessage,
  ]) {
    _showFloating(
      context: context,
      title: optionalMessage != null ? messageOrTitle : 'Info',
      message: optionalMessage ?? messageOrTitle,
      icon: Icons.info_outline,
      iconColor: const Color(0xFF38BDF8),
      borderColor: const Color(0xFF0284C7).withValues(alpha: 0.4),
    );
  }

  static void showWarning(
    BuildContext context,
    String messageOrTitle, [
    String? optionalMessage,
  ]) {
    _showFloating(
      context: context,
      title: optionalMessage != null ? messageOrTitle : 'Warning',
      message: optionalMessage ?? messageOrTitle,
      icon: Icons.warning_amber_rounded,
      iconColor: const Color(0xFFFBBF24),
      borderColor: const Color(0xFFD97706).withValues(alpha: 0.4),
    );
  }

  static void _showFloating({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 24,
        right: 24,
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF0F172A),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 12,
                        ),
                      ),
                      if (actionLabel != null && onAction != null) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            if (entry.mounted) entry.remove();
                            onAction();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E40AF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              actionLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    if (entry.mounted) entry.remove();
                  },
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFF64748B),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      Timer(const Duration(seconds: 4), () {
        if (entry.mounted) entry.remove();
      });
    }
  }

  static void showMessage(BuildContext context, String title, String message) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 24,
        right: 24,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF0F172A),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        message,
                        style: const TextStyle(color: Color(0xFFCBD5E1)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      Timer(const Duration(seconds: 4), () {
        if (entry.mounted) entry.remove();
      });
    }
  }

  static void showWelcome(BuildContext context, String displayName) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) => Opacity(
              opacity: val,
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - val)),
                child: child,
              ),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Welcome Back!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Signed in as $displayName',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      Timer(const Duration(milliseconds: 3200), () {
        if (entry.mounted) {
          entry.remove();
        }
      });
    }
  }
}
