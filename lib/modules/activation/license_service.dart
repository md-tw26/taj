import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:taj_license_core/taj_license_core.dart';

import '../../data/local/app_database.dart';

/// Which branch of the activation gate the app is on.
enum LicenseGatePhase {
  /// Status is still being read from local storage (branded splash).
  checking,

  /// No valid license for this device → [ActivationScreen].
  unlicensed,

  /// A license validated for this device → the normal app.
  licensed,
}

/// Result of evaluating the stored (or just-submitted) license.
@immutable
class LicenseGateState {
  const LicenseGateState.checking()
      : this._(LicenseGatePhase.checking, null, null, null);

  const LicenseGateState.unlicensed({
    LicenseStatus? status,
    LicensePayload? payload,
    String? message,
  }) : this._(LicenseGatePhase.unlicensed, status, payload, message);

  /// Licensed. [payload] is `null` only for the explicit test bypass
  /// (`testLicensed: true`), which skips the storage read entirely.
  const LicenseGateState.licensed([LicensePayload? payload])
      : this._(LicenseGatePhase.licensed, LicenseStatus.valid, payload, null);

  const LicenseGateState._(this.phase, this.status, this.payload, this.message);

  final LicenseGatePhase phase;

  /// Why the license was rejected, or [LicenseStatus.valid] when licensed.
  final LicenseStatus? status;

  /// Decoded payload — present whenever the code was structurally readable.
  final LicensePayload? payload;

  /// Safe, non-technical note (only used for storage failures).
  final String? message;

  bool get isChecking => phase == LicenseGatePhase.checking;
  bool get isUnlicensed => phase == LicenseGatePhase.unlicensed;
  bool get isLicensed => phase == LicenseGatePhase.licensed;
}

/// Typed rejection thrown by [LicenseService.activate].
class LicenseActivationException implements Exception {
  const LicenseActivationException(this.status, [this.payload]);

  final LicenseStatus status;
  final LicensePayload? payload;

  @override
  String toString() => 'LicenseActivationException($status)';
}

/// Strips every kind of whitespace/newline a paste may carry, so a code
/// wrapped across lines by a mail client still validates.
String normalizeLicenseCode(String raw) =>
    raw.replaceAll(RegExp(r'\s+'), '').trim();

/// Offline license gate: local storage + HMAC/device/date validation.
///
/// Nothing here touches the network. [loadStatus] is intentionally re-run on
/// every app start so a tampered, expired or moved license is caught again,
/// not just once at first activation.
abstract final class LicenseService {
  static Future<String>? _fingerprint;

  /// Device fingerprint for this machine (cached for the app session — the
  /// underlying sources are file/OS lookups).
  static Future<String> deviceFingerprint() =>
      _fingerprint ??= TajDeviceFingerprint.current();

  /// Reads the stored license and re-validates it against this device.
  static Future<LicenseGateState> loadStatus(AppDatabase db) async {
    try {
      final row = await db.getActiveLicense();
      if (row == null) return const LicenseGateState.unlicensed();

      final evaluation = TajLicenseValidator.evaluate(
        code: row.code,
        deviceFingerprint: await deviceFingerprint(),
      );
      if (evaluation.isValid) {
        return LicenseGateState.licensed(evaluation.payload);
      }
      return LicenseGateState.unlicensed(
        status: evaluation.status,
        payload: evaluation.payload,
      );
    } catch (_) {
      // Storage failure → behave as unlicensed with a safe message; never leak
      // raw exception text to the UI.
      return const LicenseGateState.unlicensed(
        message: 'تعذّرت قراءة بيانات الترخيص على هذا الجهاز.',
      );
    }
  }

  /// Validates [code] for this device and, when it is valid, persists it as
  /// the single active license.
  ///
  /// Throws [LicenseActivationException] carrying the exact [LicenseStatus]
  /// when the code is not valid for this device.
  static Future<LicensePayload> activate({
    required AppDatabase db,
    required String code,
    required String customerName,
  }) async {
    final normalized = normalizeLicenseCode(code);
    if (normalized.isEmpty) {
      throw const LicenseActivationException(LicenseStatus.malformed);
    }

    final evaluation = TajLicenseValidator.evaluate(
      code: normalized,
      deviceFingerprint: await deviceFingerprint(),
    );
    if (!evaluation.isValid) {
      throw LicenseActivationException(evaluation.status, evaluation.payload);
    }

    final payload = evaluation.payload!;
    // The informational field is only a fallback — the name baked into the
    // signed payload wins.
    final name = payload.customerName.trim().isNotEmpty
        ? payload.customerName.trim()
        : customerName.trim();

    await db.upsertLicense(
      id: newLicenseId(),
      code: normalized,
      customerName: name,
      fingerprint: payload.fingerprint,
      planCode: payload.planCode,
      issuedAt: payload.issuedAtDate,
      expiresAt: payload.expiresAtDate,
      activatedAt: DateTime.now().toUtc(),
    );
    return payload;
  }

  /// Removes the stored license (the device goes back to the activation gate).
  static Future<void> deactivate(AppDatabase db) => db.clearLicense();

  /// `lic_<millis>_<rand>` — unique enough for a single-row table.
  static String newLicenseId() =>
      'lic_${DateTime.now().millisecondsSinceEpoch}_'
      '${Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}
