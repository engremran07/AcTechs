import 'dart:convert';
import 'dart:typed_data';

/// Encodes and decodes image bytes to Base64 for Firestore-only persistence.
///
/// This keeps the app free-tier friendly by avoiding Firebase Storage usage
/// for image payloads. Prefer compressed images and small payload sizes.
class Base64ImageCodec {
  const Base64ImageCodec._();

  static String encode(Uint8List bytes) => base64Encode(bytes);

  static Uint8List decode(String value) => base64Decode(value);
}
