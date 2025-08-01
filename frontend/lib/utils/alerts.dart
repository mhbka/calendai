import 'package:flutter/material.dart';

enum AlertType {
  success,
  error,
  warning,
  info,
}

/// Opinionated info/warning/error snackbars and popup dialogs.
class Alerts {
  Alerts._();

  // Get color based on alert type
  static Color _getAlertColor(AlertType type) {
    switch (type) {
      case AlertType.success:
        return Colors.green;
      case AlertType.error:
        return Colors.red;
      case AlertType.warning:
        return Colors.orange;
      case AlertType.info:
        return Colors.blue;
    }
  }

  // Get icon based on alert type
  static IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.success:
        return Icons.check_circle;
      case AlertType.error:
        return Icons.error;
      case AlertType.warning:
        return Icons.warning;
      case AlertType.info:
        return Icons.info;
    }
  }

  // Generic snackbar method
  static void _showSnackBar(
    BuildContext context,
    String message,
    AlertType type, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    final color = _getAlertColor(type);
    final icon = _getAlertIcon(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onActionPressed ?? () {},
              )
            : null,
      ),
    );
  }

  // Success snackbar
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackBar(
      context,
      message,
      AlertType.success,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  // Error snackbar
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackBar(
      context,
      message,
      AlertType.error,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  // Warning snackbar
  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackBar(
      context,
      message,
      AlertType.warning,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  // Info snackbar
  static void showInfoSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackBar(
      context,
      message,
      AlertType.info,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  // Generic dialog method
  static Future<bool?> _showAlertDialog(
    BuildContext context,
    String title,
    String message,
    AlertType type, {
    String? confirmText,
    String? cancelText,
    bool barrierDismissible = true,
    bool useRootNavigator = false,
  }) {
    final color = _getAlertColor(type);
    final icon = _getAlertIcon(type);

    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      useRootNavigator: useRootNavigator,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
            ),
          ),
          actions: [
            if (cancelText != null)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  cancelText,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: color.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                confirmText ?? 'OK',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Success dialog
  static Future<bool?> showSuccessDialog(
    BuildContext context,
    String title,
    String message, {
    String? confirmText,
    String? cancelText,
    bool barrierDismissible = true,
    bool useRootNavigator = false,
  }) {
    return _showAlertDialog(
      context,
      title,
      message,
      AlertType.success,
      confirmText: confirmText,
      cancelText: cancelText,
      barrierDismissible: barrierDismissible,
      useRootNavigator: useRootNavigator,
    );
  }

  // Error dialog
  static Future<bool?> showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    String? confirmText,
    String? cancelText,
    bool barrierDismissible = true,
  }) {
    return _showAlertDialog(
      context,
      title,
      message,
      AlertType.error,
      confirmText: confirmText,
      cancelText: cancelText,
      barrierDismissible: barrierDismissible,
    );
  }

  // Warning dialog
  static Future<bool?> showWarningDialog(
    BuildContext context,
    String title,
    String message, {
    String? confirmText,
    String? cancelText,
    bool barrierDismissible = true,
  }) {
    return _showAlertDialog(
      context,
      title,
      message,
      AlertType.warning,
      confirmText: confirmText,
      cancelText: cancelText,
      barrierDismissible: barrierDismissible,
    );
  }

  // Info dialog
  static Future<bool?> showInfoDialog(
    BuildContext context,
    String title,
    String message, {
    String? confirmText,
    String? cancelText,
    bool barrierDismissible = true,
  }) {
    return _showAlertDialog(
      context,
      title,
      message,
      AlertType.info,
      confirmText: confirmText,
      cancelText: cancelText,
      barrierDismissible: barrierDismissible,
    );
  }

  // Confirmation dialog (returns true/false based on user choice)
  static Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String message, {
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    AlertType type = AlertType.warning,
    bool barrierDismissible = true,
  }) async {
    final result = await _showAlertDialog(
      context,
      title,
      message,
      type,
      confirmText: confirmText,
      cancelText: cancelText,
      barrierDismissible: barrierDismissible,
    );
    return result ?? false;
  }

  // Loading dialog
  static void showLoadingDialog(
    BuildContext context, {
    String message = 'Loading...',
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  // Method to show dialog that overlays on top of existing dialogs
  static Future<bool?> showOverlayDialog(
    BuildContext context,
    String title,
    String message,
    AlertType type, {
    String? confirmText,
    String? cancelText,
    bool barrierDismissible = true,
  }) {
    // Use rootNavigator to show on top of existing dialogs
    final color = _getAlertColor(type);
    final icon = _getAlertIcon(type);
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      useRootNavigator: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
            ),
          ),
          actions: [
            if (cancelText != null)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  cancelText,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: color.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                confirmText ?? 'OK',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Convenience methods for overlay dialogs
  static Future<bool?> showOverlaySuccessDialog(
    BuildContext context,
    String title,
    String message, {
    String? confirmText,
    String? cancelText,
    bool barrierDismissible = true,
  }) {
    return showOverlayDialog(
      context,
      title,
      message,
      AlertType.success,
      confirmText: confirmText,
      cancelText: cancelText,
      barrierDismissible: barrierDismissible,
    );
  }

  static Future<bool?> showOverlayErrorDialog(
    BuildContext context,
    String title,
    String message, {
    String? confirmText,
    String? cancelText,
    bool barrierDismissible = true,
  }) {
    return showOverlayDialog(
      context,
      title,
      message,
      AlertType.error,
      confirmText: confirmText,
      cancelText: cancelText,
      barrierDismissible: barrierDismissible,
    );
  }

  static Future<bool?> showOverlayWarningDialog(
    BuildContext context,
    String title,
    String message, {
    String? confirmText,
    String? cancelText,
    bool barrierDismissible = true,
  }) {
    return showOverlayDialog(
      context,
      title,
      message,
      AlertType.warning,
      confirmText: confirmText,
      cancelText: cancelText,
      barrierDismissible: barrierDismissible,
    );
  }

  static Future<bool?> showOverlayInfoDialog(
    BuildContext context,
    String title,
    String message, {
    String? confirmText,
    String? cancelText,
    bool barrierDismissible = true,
  }) {
    return showOverlayDialog(
      context,
      title,
      message,
      AlertType.info,
      confirmText: confirmText,
      cancelText: cancelText,
      barrierDismissible: barrierDismissible,
    );
  }

  // Overlay confirmation dialog
  static Future<bool> showOverlayConfirmationDialog(
    BuildContext context,
    String title,
    String message, {
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    AlertType type = AlertType.warning,
    bool barrierDismissible = true,
  }) async {
    final result = await showOverlayDialog(
      context,
      title,
      message,
      type,
      confirmText: confirmText,
      cancelText: cancelText,
      barrierDismissible: barrierDismissible,
    );
    return result ?? false;
  }
}