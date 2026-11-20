/// Commercial catalog is paused; ordinary builds use manual entry.
/// Arsenal backup configuration is independent and is not changed here.
abstract final class CatalogConfig {
  static const commercialEnabled = bool.fromEnvironment(
    'COMMERCIAL_CATALOG_ENABLED',
    defaultValue: false,
  );
}
