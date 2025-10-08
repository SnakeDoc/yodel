pub opaque type Options {
  Options(format: Format, resolve: ResolveOptions)
}

pub type Format {
  Auto
  Json
  Toml
  Yaml
}

pub type ResolveMode {
  Strict
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
