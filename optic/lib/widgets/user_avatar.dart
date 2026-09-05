import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart' as material;
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:optic/controllers/tenant_session.dart';

/// Decodes a `data:<mime>;base64,<payload>` URI into raw bytes, or returns
/// null for anything else (a plain http(s) URL, malformed data, etc.) so
/// the caller can fall back to [material.Image.network]. `photoUrl` is
/// Base64-in-Firestore by default now (see `TenantSession.uploadPhoto`),
/// but this keeps any older real-URL value (from before that change)
/// displaying correctly too, instead of breaking on upgrade.
Uint8List? _decodeDataUri(String uri) {
  if (!uri.startsWith('data:')) return null;
  final commaIndex = uri.indexOf(',');
  if (commaIndex == -1) return null;
  try {
    return base64Decode(uri.substring(commaIndex + 1));
  } catch (_) {
    return null;
  }
}

/// The signed-in user's profile picture, with a small connectivity dot at
/// the bottom-right — green while this device has a working connection to
/// Firestore, red when it's fallen back to the local cache. Reads
/// [TenantSession.photoUrl] and [TenantSession.isOnline] directly, so any
/// screen can just drop in `const UserAvatar()` without wiring anything.
///
/// Used in the desktop top bar (in place of the old icon-circle +
/// email/business-name text) and in the Settings > Account picture editor.
/// Same [Stack]/[Positioned] badge pattern as `notification_bell.dart`'s
/// unread-count dot.
class UserAvatar extends StatelessWidget {
  final double size;
  final bool showStatusDot;

  const UserAvatar({super.key, this.size = 34, this.showStatusDot = true});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tenantSession = context.watch<TenantSession>();
    final photoUrl = tenantSession.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final photoBytes = hasPhoto ? _decodeDataUri(photoUrl) : null;

    final fallbackIcon = Icon(
      Icons.person_outline,
      size: size * 0.5,
      color: colorScheme.primary,
    );

    Widget photoChild;
    if (photoBytes != null) {
      // The common case: a Base64 data URI stored directly on the
      // Firestore doc (see TenantSession.uploadPhoto) — no network fetch,
      // decodes instantly from memory.
      photoChild = material.Image.memory(
        photoBytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallbackIcon,
      );
    } else if (hasPhoto) {
      // Falls back to treating the value as a real URL, for any doc that
      // still has one from before this app switched to Base64-in-Firestore.
      photoChild = material.Image.network(
        photoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // A broken/unreachable URL falls back to the plain icon instead of
        // leaving a red-X placeholder in the top bar.
        errorBuilder: (context, error, stackTrace) => fallbackIcon,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return fallbackIcon;
        },
      );
    } else {
      photoChild = fallbackIcon;
    }

    final avatar = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: photoChild,
    );

    if (!showStatusDot) return avatar;

    final dotSize = (size * 0.32).clamp(8.0, 14.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: tenantSession.isOnline ? Colors.green : Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.background, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
