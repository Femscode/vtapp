class AppConfig {
  /// Base API URL for VTUBiz services.
  static const String liveUrl = String.fromEnvironment(
    'LIVE_URL',
    defaultValue: 'https://vtubiz.com/api',
  );

  // Future variables can be added here easily, for example:
  // static const String apiKey = String.fromEnvironment('API_KEY', defaultValue: '');
}
