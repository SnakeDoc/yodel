//// Configuration options for loading and parsing config files.
////
//// **Note:** These types are re-exported from the main `yodel` module.
//// Use the builder functions in `yodel` to construct options rather than
//// importing this module directly.

/// Configuration options for loading config files.
///
/// Create options using `yodel.default_options()` and configure using
/// builder functions like `yodel.with_format()` and `yodel.with_resolve_mode()`.
pub opaque type Options {
  Options(format: Format, resolve: ResolveOptions)
}

/// The format of the configuration file.
pub type Format {
  /// Automatically detect format
  Auto
  /// Parse as JSON
  Json
  /// Parse as TOML
  Toml
  /// Parse as YAML
  Yaml
}

/// The resolve mode for environment variable placeholders.
pub type ResolveMode {
  /// Fail if any placeholder cannot be resolved
  Strict
  /// Preserve unresolved placeholders in the output
  Lenient
}

@internal
pub type ResolveOptions {
  ResolveOptions(enabled: Bool, mode: ResolveMode)
}

@internal
pub fn new(
  format format: Format,
  resolve_enabled resolve_enabled: Bool,
  resolve_mode resolve_mode: ResolveMode,
) -> Options {
  Options(
    format:,
    resolve: new_resolve_options(enabled: resolve_enabled, mode: resolve_mode),
  )
}

@internal
pub fn new_resolve_options(
  enabled enabled: Bool,
  mode mode: ResolveMode,
) -> ResolveOptions {
  ResolveOptions(enabled:, mode:)
}

@internal
pub fn default() -> Options {
  new(Auto, True, Lenient)
}

@internal
pub fn with_format(options options: Options, format format: Format) -> Options {
  new(format, options.resolve.enabled, options.resolve.mode)
}

@internal
pub fn with_resolve_enabled(
  options options: Options,
  enabled enabled: Bool,
) -> Options {
  new(options.format, enabled, options.resolve.mode)
}

@internal
pub fn with_resolve_mode(
  options options: Options,
  mode mode: ResolveMode,
) -> Options {
  new(options.format, options.resolve.enabled, mode)
}

@internal
pub fn get_format(options options: Options) -> Format {
  options.format
}

@internal
pub fn is_resolve_enabled(options options: Options) -> Bool {
  options.resolve.enabled
}

@internal
pub fn get_resolve_mode(options options: Options) -> ResolveMode {
  options.resolve.mode
}
