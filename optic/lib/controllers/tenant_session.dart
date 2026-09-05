import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// The real session/auth layer this app didn't have before — replaces the
/// old `SessionProvider` static stub. Wraps `FirebaseAuth`'s sign-in state
/// and, once signed in, resolves which tenant (shop) the signed-in user
/// belongs to by reading their `/users/{uid}` profile doc — see the
/// migration guide's Step 3 for why that lookup has to happen at all
/// (multi-tenant: knowing *who* is signed in isn't the same as knowing
/// *which shop's data* to load).
///
/// [DataProvider]'s eventual Firestore listeners (guide Step 5) will read
/// [tenantId] from here to know which `tenants/{tenantId}/...` subtree to
/// attach to — that wiring isn't done yet; this controller only carries
/// auth + tenant identity, not the business data itself.
class TenantSession extends ChangeNotifier {
  TenantSession() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  StreamSubscription<User?>? _authSub;

  User? _user;
  String? _tenantId;
  String? _role;
  String? _shopName;
  String? _ownerName;
  String? _ownerPhone;
  String? _plan;
  String? _email;
  String? _photoUrl;
  bool _isOnline = true;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;
  bool _isResolvingTenant = false;
  bool _hasCheckedInitialAuth = false;
  String? _error;

  /// The signed-in Firebase user, or null when signed out.
  User? get user => _user;

  /// The account's email, from `/users/{uid}.email` (falls back to the
  /// Firebase Auth user's own email if the doc doesn't carry one).
  String? get email => _email ?? _user?.email;

  /// False until the very first `authStateChanges()` event has arrived.
  /// Firebase persists sessions on-device by default (native secure
  /// storage on mobile/desktop, `LOCAL` browser storage on web), so an
  /// already-logged-in device *will* come back signed in — but that first
  /// event is still async. Without this flag, `user == null` can't tell
  /// "definitely signed out" apart from "haven't heard back yet," which
  /// meant a device that was already logged in would still flash
  /// `LoginScreen` for a moment on every cold start. The auth gate shows a
  /// neutral loading state instead of `LoginScreen` while this is false.
  bool get hasCheckedInitialAuth => _hasCheckedInitialAuth;

  /// Which `tenants/{tenantId}` subtree this user's data lives under — null
  /// until resolved (or if the user has no profile doc at all, which
  /// shouldn't happen outside of a broken signup).
  String? get tenantId => _tenantId;

  /// 'owner' | 'staff' — from the user's own `/users/{uid}` doc.
  String? get role => _role;

  /// The shop's business name, from the signed-in user's own
  /// `/users/{uid}.displayName` — set at provisioning time by the
  /// licensing website, not editable from inside this app.
  String? get shopName => _shopName;

  /// The signed-in staff member's full name, from their own
  /// `/users/{uid}.name` — set at provisioning time by the licensing
  /// website, not editable from inside this app.
  String? get ownerName => _ownerName;

  /// Contact phone number, from `/users/{uid}.phone`. Same provenance as
  /// [ownerName] — read-only here.
  String? get ownerPhone => _ownerPhone;

  /// Subscription plan (e.g. 'trial' | 'active'), from
  /// `/tenants/{tenantId}.plan` — managed by the licensing website.
  String? get plan => _plan;

  /// Profile picture, from `/users/{uid}.photoUrl` — the one field on this
  /// doc a signed-in user CAN write themselves (see [updatePhotoUrl]/
  /// [uploadPhoto] and the corresponding narrow `allow update` in
  /// `firestore.rules`). Despite the name, this is no longer necessarily a
  /// real URL: [uploadPhoto] stores a `data:image/...;base64,...` URI
  /// directly on the doc (no Firebase Storage, no paid plan required) —
  /// `UserAvatar` decodes that itself. The field is still called `photoUrl`
  /// to avoid touching every read site and `firestore.rules`' `hasOnly`
  /// list for a rename that changes nothing functionally.
  String? get photoUrl => _photoUrl;

  /// Whether the live `/users/{uid}` listener is currently getting data
  /// from the server rather than the local cache — i.e. whether this
  /// device currently has a working connection to Firestore. Derived from
  /// `DocumentSnapshot.metadata.isFromCache` on every snapshot (including
  /// metadata-only ones), which Firestore emits on every
  /// connect/disconnect transition even when the underlying data hasn't
  /// changed — the same mechanism Firebase's own docs recommend for a
  /// network-status indicator, so no extra connectivity package is needed.
  bool get isOnline => _isOnline;

  /// True between "signed in" and "tenant resolved" — the login gate shows
  /// a brief loading state during this window instead of flashing the app
  /// shell with no shop context yet.
  bool get isResolvingTenant => _isResolvingTenant;

  /// True once both auth and tenant resolution are settled and there IS a
  /// signed-in, tenant-attached user — what the auth gate actually checks
  /// before showing the app.
  bool get isReady => _user != null && !_isResolvingTenant && _tenantId != null;

  String? get lastError => _error;

  Future<void> _onAuthChanged(User? user) async {
    _user = user;
    _error = null;
    await _userDocSub?.cancel();
    _userDocSub = null;
    if (user == null) {
      _tenantId = null;
      _role = null;
      _shopName = null;
      _ownerName = null;
      _ownerPhone = null;
      _plan = null;
      _email = null;
      _photoUrl = null;
      _isOnline = true;
      _isResolvingTenant = false;
      _hasCheckedInitialAuth = true;
      notifyListeners();
      return;
    }
    await _resolveTenant(user.uid);
    _hasCheckedInitialAuth = true;
    notifyListeners();
  }

  /// Looks up [key] in a Firestore doc's data, tolerating a stray leading
  /// or trailing space on the *field name itself* — this project's console
  /// data has been hand-entered field-by-field, and at least one field
  /// ('Name ' instead of 'Name') was created with a trailing space in the
  /// key. An exact match is tried first (the common case, and the cheap
  /// one); only on a miss do we fall back to scanning every key with
  /// `.trim()` applied, so a legitimately-named field never gets shadowed.
  static String? _field(Map<String, dynamic>? data, String key) {
    if (data == null) return null;
    if (data.containsKey(key)) return data[key] as String?;
    for (final entry in data.entries) {
      if (entry.key.trim() == key) return entry.value as String?;
    }
    return null;
  }

  /// Sets up a *live* listener on the signed-in user's own `/users/{uid}`
  /// doc — rather than a one-time `.get()` — for two reasons: (1) console
  /// edits to displayName/name/phone/photoUrl now show up immediately
  /// without needing to sign out and back in, and (2) passing
  /// `includeMetadataChanges: true` makes Firestore emit a snapshot on
  /// every connect/disconnect transition even when the data itself hasn't
  /// changed, which is what [isOnline] is derived from. Returns only after
  /// the *first* snapshot has been handled, so callers can still `await`
  /// this the same way they awaited the old one-shot `.get()`.
  Future<void> _resolveTenant(String uid) async {
    _isResolvingTenant = true;
    notifyListeners();
    final firstSnapshot = Completer<void>();
    _userDocSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (snap) async {
            _isOnline = !snap.metadata.isFromCache;
            final data = snap.data();
            // Field keys here match the exact names used in the Firestore
            // console for this project — NOT typical camelCase. Confirmed
            // against a live document: 'tenantID' (capital ID), 'Display
            // Name' (with a space), 'Name' (capital N), while 'email',
            // 'phone', 'role' are plain lowercase. Get any of these wrong
            // and the field silently reads as null (Firestore doesn't
            // error on an unknown map key) — which is exactly what
            // happened before this fix (business name/owner name/plan all
            // showed "not set"). Reads go through [_field], not direct map
            // indexing, since this same console data has already turned up
            // at least one field ('Name ') with a stray trailing space in
            // the key that a plain `data['Name']` lookup won't match.
            final newTenantId = _field(data, 'tenantID')?.trim();
            _role = _field(data, 'role');
            // Business name and owner name both live on the user's own
            // profile doc — 'Display Name' holds the shop's business name,
            // 'Name' holds the signed-in person's own full name. Email
            // falls back to the Firebase Auth user's email if the doc
            // doesn't carry its own copy. 'photoUrl' is the one field on
            // this doc a signed-in user can write themselves (see
            // [updatePhotoUrl]).
            _shopName = _field(data, 'Display Name');
            _ownerName = _field(data, 'Name');
            _ownerPhone = _field(data, 'phone');
            _email = _field(data, 'email') ?? _user?.email;
            _photoUrl = _field(data, 'photoUrl');
            if (newTenantId != _tenantId) {
              _tenantId = newTenantId;
              if (_tenantId != null) {
                try {
                  final tenantDoc = await FirebaseFirestore.instance
                      .collection('tenants')
                      .doc(_tenantId)
                      .get();
                  _plan = _field(tenantDoc.data(), 'plan');
                } catch (e) {
                  _error = e.toString();
                }
              } else {
                _plan = null;
              }
            }
            _isResolvingTenant = false;
            notifyListeners();
            if (!firstSnapshot.isCompleted) firstSnapshot.complete();
          },
          onError: (Object e) {
            _error = e.toString();
            _isResolvingTenant = false;
            notifyListeners();
            if (!firstSnapshot.isCompleted) firstSnapshot.complete();
          },
        );
    await firstSnapshot.future;
  }

  /// The one self-service write a signed-in user can make to their own
  /// `/users/{uid}` doc — everything else (name, role, tenantId, phone)
  /// stays provisioned externally. `firestore.rules` enforces this same
  /// narrowing server-side (`affectedKeys().hasOnly(['photoUrl'])`), so
  /// this isn't just a client-side convention.
  Future<void> updatePhotoUrl(String photoUrl) async {
    final uid = _user?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'photoUrl': photoUrl});
    // No local state mutation needed here — the live listener above will
    // pick up this same write and update `_photoUrl` on its own.
  }

  /// Firestore documents are capped at ~1 MiB total. `photoUrl` shares that
  /// doc with a handful of tiny string fields, so this is a conservative
  /// budget for the Base64 payload alone — comfortably clear of the actual
  /// limit, while still allowing a perfectly good avatar image (the
  /// picker's compression settings in `settings_screen.dart` keep uploads
  /// far below this in practice; this guard only ever fires if someone
  /// picks an unusually large or hard-to-compress image).
  static const int _maxEncodedPhotoLength = 700000;

  /// Stores a picture picked from the device (see `settings_screen.dart`'s
  /// `_AccountTab`, which uses `image_picker` to get [bytes] — the gallery
  /// on mobile, a native folder browser on desktop/web) directly on
  /// `/users/{uid}.photoUrl` as a `data:` URI — no Firebase Storage
  /// involved. Cloud Storage for Firebase requires the paid Blaze plan
  /// even for trivial usage; Base64-in-Firestore keeps this feature on the
  /// same free tier as the rest of the app, at the cost of the size cap in
  /// [_maxEncodedPhotoLength] (fine for a small avatar, not for a full-res
  /// photo). Throws [PhotoTooLargeException] if the encoded image would
  /// exceed that budget — callers should show a friendly "pick a smaller
  /// picture" message rather than a generic error.
  Future<void> uploadPhoto(Uint8List bytes, {required String contentType}) async {
    final uid = _user?.uid;
    if (uid == null) return;
    final dataUri = 'data:$contentType;base64,${base64Encode(bytes)}';
    if (dataUri.length > _maxEncodedPhotoLength) {
      throw const PhotoTooLargeException();
    }
    await updatePhotoUrl(dataUri);
  }

  /// Existing staff signing in to their shop's already-provisioned tenant.
  /// Throws [FirebaseAuthException] on failure — the login screen catches
  /// it and maps the code to a user-facing message.
  Future<void> signIn({required String email, required String password}) =>
      FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

  // Tenant + first-owner-account provisioning ("create your shop") happens
  // from the licensing website at purchase time instead of from inside
  // this app — see the migration guide's Step 3 for the `/tenants/{id}` +
  // `/users/{uid}` shape that provisioning step needs to produce. This
  // controller only ever signs an already-provisioned staff member in.

  Future<void> sendPasswordResetEmail(String email) =>
      FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => FirebaseAuth.instance.signOut();

  @override
  void dispose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    super.dispose();
  }
}

/// Thrown by [TenantSession.uploadPhoto] when the picked image, once
/// Base64-encoded, would push the `/users/{uid}` doc past the size budget
/// reserved for the self-service `photoUrl` field. Distinct from a generic
/// failure so the UI can show "pick a smaller picture" instead of a
/// catch-all error message.
class PhotoTooLargeException implements Exception {
  const PhotoTooLargeException();
}
