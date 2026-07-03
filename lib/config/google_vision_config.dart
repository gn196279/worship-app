/// Google Cloud Vision API key — optional fallback for scanned PDF pages only.
/// Screenshot upload uses on-device ML Kit (no key or billing required).
class GoogleVisionConfig {
  GoogleVisionConfig._();

  static const String apiKey = String.fromEnvironment('GCV_API_KEY');

  static bool get isConfigured => apiKey.isNotEmpty;
}
