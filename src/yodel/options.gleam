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
  Options(
    format: Format,
    resolve: ResolveOptions,
    config_base_name: String,
    profile_env_var: String,
    profiles: List(String),
  )
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
  config_base_name config_base_name: String,
  profile_env_var profile_env_var: String,
  profiles profiles: List(String),
) -> Options {
  Options(
    format:,
    resolve: new_resolve_options(enabled: resolve_enabled, mode: resolve_mode),
    config_base_name:,
    profile_env_var:,
    profiles:,
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
  new(Auto, True, Lenient, "config", "YODEL_PROFILES", [])
}

@internal
pub fn with_format(options options: Options, format format: Format) -> Options {
  new(
    format:,
    resolve_enabled: options.resolve.enabled,
    resolve_mode: options.resolve.mode,
    config_base_name: options.config_base_name,
    profile_env_var: options.profile_env_var,
    profiles: options.profiles,
  )
}

@internal
pub fn with_resolve_enabled(
  options options: Options,
  resolve_enabled resolve_enabled: Bool,
) -> Options {
  new(
    format: options.format,
    resolve_enabled:,
    resolve_mode: options.resolve.mode,
    config_base_name: options.config_base_name,
    profile_env_var: options.profile_env_var,
    profiles: options.profiles,
  )
}

@internal
pub fn with_resolve_mode(
  options options: Options,
  resolve_mode resolve_mode: ResolveMode,
) -> Options {
  new(
    format: options.format,
    resolve_enabled: options.resolve.enabled,
    resolve_mode:,
    config_base_name: options.config_base_name,
    profile_env_var: options.profile_env_var,
    profiles: options.profiles,
  )
}

@internal
pub fn with_config_base_name(
  options options: Options,
  config_base_name config_base_name: String,
) -> Options {
  new(
    format: options.format,
    resolve_enabled: options.resolve.enabled,
    resolve_mode: options.resolve.mode,
    config_base_name:,
    profile_env_var: options.profile_env_var,
    profiles: options.profiles,
  )
}

@internal
pub fn with_profile_env_var(
  options options: Options,
  profile_env_var profile_env_var: String,
) -> Options {
  new(
    format: options.format,
    resolve_enabled: options.resolve.enabled,
    resolve_mode: options.resolve.mode,
    config_base_name: options.config_base_name,
    profile_env_var:,
    profiles: options.profiles,
  )
}

@internal
pub fn with_profiles(
  options options: Options,
  profiles profiles: List(String),
) -> Options {
  new(
    format: options.format,
    resolve_enabled: options.resolve.enabled,
    resolve_mode: options.resolve.mode,
    config_base_name: options.config_base_name,
    profile_env_var: options.profile_env_var,
    profiles:,
  )
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

@internal
pub fn get_config_base_name(options options: Options) -> String {
  options.config_base_name
}

@internal
pub fn get_profile_env_var(options options: Options) -> String {
  options.profile_env_var
}

@internal
pub fn get_profiles(options options: Options) -> List(String) {
  options.profiles
}
