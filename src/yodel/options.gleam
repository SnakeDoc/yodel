pub opaque type Options {
  Options(format: Format, resolve: ResolveOptions, validate: Bool)
}

pub type Format {
  Auto
  Json
  Toml
  Yaml
}

pub type ResolveOptions {
  ResolveOptions(enabled: Bool, mode: ResolveMode)
}

pub type ResolveMode {
  Strict
  Lenient
}

pub fn new(
  format format: Format,
  resolve_enabled resolve_enabled: Bool,
  resolve_mode resolve_mode: ResolveMode,
  validate validate: Bool,
) -> Options {
  Options(
    format:,
    resolve: new_resolve_options(enabled: resolve_enabled, mode: resolve_mode),
    validate:,
  )
}

pub fn new_resolve_options(
  enabled enabled: Bool,
  mode mode: ResolveMode,
) -> ResolveOptions {
  ResolveOptions(enabled:, mode:)
}

pub fn default() -> Options {
  new(Auto, True, Lenient, True)
}

pub fn with_format(options options: Options, format format: Format) -> Options {
  new(format, options.resolve.enabled, options.resolve.mode, options.validate)
}

pub fn with_resolve_enabled(
  options options: Options,
  enabled enabled: Bool,
) -> Options {
  new(options.format, enabled, options.resolve.mode, options.validate)
}

pub fn with_resolve_mode(
  options options: Options,
  mode mode: ResolveMode,
) -> Options {
  new(options.format, options.resolve.enabled, mode, options.validate)
}

pub fn with_validation_enabled(
  options options: Options,
  validate validate: Bool,
) -> Options {
  new(options.format, options.resolve.enabled, options.resolve.mode, validate)
}

pub fn get_format(options options: Options) -> Format {
  options.format
}

pub fn is_resolve_enabled(options options: Options) -> Bool {
  options.resolve.enabled
}

pub fn get_resolve_mode(options options: Options) -> ResolveMode {
  options.resolve.mode
}

pub fn is_validation_enabled(options options: Options) -> Bool {
  options.validate
}
