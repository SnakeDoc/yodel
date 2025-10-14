//// Yodel is a type-safe configuration loader for Gleam that handles JSON,
//// YAML, and TOML configs with automatic format detection, environment variable
//// resolution, and an intuitive dot-notation API for accessing your config
//// values.
////
//// ```gleam
//// import yodel
////
//// let assert Ok(ctx) = yodel.load("config.toml")
//// yodel.get_string(ctx, "foo.bar") // "fooey"
//// ```
////
//// Yodel can resolve placeholders in the configuration content, using environment variables.
//// - Placeholders are defined as `${foo}` where `foo` is the placeholder key.
//// - Placeholders can have default values like `${foo:bar}` where `bar` is the default value.
//// - Placeholders can be nested like `${foo:${bar}}` where `bar` is another placeholder key.
////
//// ```bash
//// # system environment variables
//// echo $FOO # "fooey"
//// echo $BAR # <empty>
//// ```
////
//// ```toml
//// # config.toml
//// foo = "${FOO}"
//// bar = "${BAR:default}"
//// ```
//// ```gleam
//// import yodel
////
//// let ctx = case yodel.load("config.toml") {
////   Ok(ctx) -> ctx
////   Error(e) -> Error(e) // check your config!
//// }
////
//// yodel.get_string(ctx, "foo") // "fooey"
//// yodel.get_string(ctx, "bar") // "default"
//// ```
////
//// Yodel makes it easy to access configuration values in your Gleam code.
//// - Access values from your configuration using dot-notation.
//// - Get string, integer, float, and boolean values from the configuration.
//// - Optional return default values if the key is not found.

import gleam/list
import gleam/result
import yodel/errors
import yodel/internal/context
import yodel/internal/format.{FormatDetector}
import yodel/internal/input.{Directory}
import yodel/internal/parser
import yodel/internal/parsers/toml
import yodel/internal/parsers/yaml
import yodel/internal/profiles.{type ConfigFile}
import yodel/internal/properties.{type Properties}
import yodel/internal/resolver
import yodel/internal/validator
import yodel/options
import yodel/value

/// The Context type, representing a loaded configuration.
///
/// This is an opaque type that holds your parsed configuration values.
/// Create a context using `load()` or `load_with_options()`, then access
/// values using the getter functions like `get_string()`, `get_int()`, etc.
///
/// ```gleam
/// let assert Ok(ctx) = yodel.load("config.yaml")
/// let value = yodel.get_string(ctx, "database.host")
/// ```
pub type Context =
  context.Context

/// Configuration options for loading config files.
///
/// Create using `default_options()` and configure using builder functions:
///
/// ```gleam
/// let ctx =
///   yodel.default_options()
///   |> yodel.as_yaml()
///   |> yodel.with_resolve_strict()
///   |> yodel.load_with_options("config.yaml")
/// ```
pub type Options =
  options.Options

/// The format of a configuration file.
///
/// Use the constants `format_auto` **(default)**, `format_json`, `format_toml`, or `format_yaml`,
/// or pass this type to `with_format()`.
pub type Format =
  options.Format

/// The resolve mode for environment variable placeholders.
///
/// Use the constants `resolve_strict` or `resolve_lenient`, or pass this type
/// to `with_resolve_mode()`.
///
/// - `resolve_strict`: Fail if any placeholder cannot be resolved
/// - `resolve_lenient`: Preserve unresolved placeholders as-is **(default)**
pub type ResolveMode =
  options.ResolveMode

/// Errors that can occur when loading or parsing configuration.
pub type ConfigError =
  errors.ConfigError

/// Errors that occur when reading configuration files from disk.
pub type FileError =
  errors.FileError

/// Errors that occur when parsing configuration content.
pub type ParseError =
  errors.ParseError

/// Syntax errors with location information.
pub type SyntaxError =
  errors.SyntaxError

/// Location of a syntax error in the source file.
pub type Location =
  errors.Location

/// Errors that occur when resolving environment variable placeholders.
pub type ResolverError =
  errors.ResolverError

/// Errors that occur during configuration validation.
pub type ValidationError =
  errors.ValidationError

/// Errors that occur when accessing configuration values.
pub type PropertiesError =
  errors.PropertiesError

/// Type mismatch errors when accessing configuration values.
///
/// The `got` field contains the actual value that was found, which can be
/// helpful for debugging configuration issues.
pub type TypeError =
  errors.TypeError

/// Represents a value stored in the configuration.
///
/// This type appears in `TypeError` when a type mismatch occurs, allowing
/// you to see what value was actually present in the configuration.
pub type Value =
  value.Value

/// Attempt to automatically detect the format of the configuration file.
///
/// If the input is a file, we first try to detect the format from the file extension.
/// If that fails, we try to detect the format from the content of the file.
///
/// If the input is a string, we try to detect the format from the content.
///
/// If Auto Detection fails, an error will be returned because we can't safely proceed.
/// If this happens, try specifying the format using `as_json`, `as_toml`, `as_yaml`, or `with_format`.
///
/// **This is the default.**
pub const format_auto = options.Auto

/// Parse the configuration file as JSON.
pub const format_json = options.Json

/// Parse the configuration file as TOML.
pub const format_toml = options.Toml

/// Parse the configuration file as YAML.
pub const format_yaml = options.Yaml

/// Strict Resolve Mode - Fail if any placeholder is unresolved.
pub const resolve_strict = options.Strict

/// Lenient Resolve Mode - Preserve unresolved placeholders.
///
/// This means `${foo}` will remain as `${foo}` if `foo` is not defined.
///
/// **This is the default.**
pub const resolve_lenient = options.Lenient

/// Load a configuration file.
///
/// This function will read the config content, detect the format,
/// resolve the placeholders, parse the config content, returning a `Context` if successful.
///
/// `input` can be a file path or a string containing the configuration content.
///
/// Example with file path:
///
/// ```gleam
/// let assert Ok(ctx) = yodel.load("config.toml")
/// ```
///
/// Example with string content:
///
/// ```gleam
/// let yaml_content = "database:\n  host: localhost"
/// case yodel.load(yaml_content) {
///   Ok(ctx) -> ctx
///   Error(e) -> {
///     // Handle error appropriately
///     panic as yodel.format_config_error(e)
///   }
/// }
/// ```
pub fn load(from input: String) -> Result(Context, ConfigError) {
  load_with_options(default_options(), input)
}

/// Load a configuration file with options.
///
/// This function will use the provided options to read and parse the config content,
/// returning a `Context` if successful.
///
/// Example:
///
/// ```gleam
/// let assert Ok(ctx) =
///   yodel.default_options()
///   |> yodel.as_yaml()
///   |> yodel.with_resolve_strict()
///   |> yodel.load_with_options("config.yaml")
/// ```
pub fn load_with_options(
  with options: Options,
  from input: String,
) -> Result(Context, ConfigError) {
  case input.detect_input(input) {
    Directory(dir) -> load_from_directory(dir, options)
    _ -> load_single_file(input, options)
  }
}

/// Get a string value from the configuration.
/// If the value is not a string, an error will be returned.
///
/// Example:
///
/// ```gleam
/// case yodel.get_string(ctx, "foo") {
///   Ok(value) -> value // "bar"
///   Error(e) -> Error(e)
/// }
/// ```
pub fn get_string(ctx: Context, key: String) -> Result(String, PropertiesError) {
  context.get_string(ctx, key)
}

/// Get a string value from the configuration, or a default value if the key is not found.
///
/// Example:
///
/// ```gleam
/// let value = yodel.get_string_or(ctx, "foo", "default")
/// ```
pub fn get_string_or(ctx: Context, key: String, default: String) -> String {
  context.get_string_or(ctx, key, default)
}

/// Parse a string value from the configuration.
///
/// If the value is not a string, it will be converted to a string.
/// An error will be returned if the value is not a string or cannot be
/// converted to a string.
///
/// Example:
///
/// ```gleam
/// case yodel.parse_string(ctx, "foo") {
///   Ok(value) -> value // "42"
///   Error(e) -> Error(e)
/// }
pub fn parse_string(
  ctx: Context,
  key: String,
) -> Result(String, PropertiesError) {
  context.parse_string(ctx, key)
}

/// Get an integer value from the configuration.
/// If the value is not an integer, an error will be returned.
///
/// Example:
///
/// ```gleam
/// case yodel.get_int(ctx, "foo") {
///   Ok(value) -> value // 42
///   Error(e) -> Error(e)
/// }
/// ```
pub fn get_int(ctx: Context, key: String) -> Result(Int, PropertiesError) {
  context.get_int(ctx, key)
}

/// Get an integer value from the configuration, or a default value if the key is not found.
///
/// Example:
///
/// ```gleam
/// let value = yodel.get_int_or(ctx, "foo", 42)
/// ```
pub fn get_int_or(ctx: Context, key: String, default: Int) -> Int {
  context.get_int_or(ctx, key, default)
}

/// Parse an integer value from the configuration.
///
/// If the value is not an integer, it will be converted to an integer.
/// An error will be returned if the value is not an integer or cannot be
/// converted to an integer.
///
/// Example:
///
/// ```gleam
/// case yodel.parse_int(ctx, "foo") {
///   Ok(value) -> value // 42
///   Error(e) -> Error(e)
/// }
/// ```
pub fn parse_int(ctx: Context, key: String) -> Result(Int, PropertiesError) {
  context.parse_int(ctx, key)
}

/// Get a float value from the configuration.
/// If the value is not a float, an error will be returned.
///
/// Example:
///
/// ```gleam
/// case yodel.get_float(ctx, "foo") {
///   Ok(value) -> value // 42.0
///   Error(e) -> Error(e)
/// }
pub fn get_float(ctx: Context, key: String) -> Result(Float, PropertiesError) {
  context.get_float(ctx, key)
}

/// Get a float value from the configuration, or a default value if the key is not found.
///
/// Example:
///
/// ```gleam
/// let value = yodel.get_float_or(ctx, "foo", 42.0)
/// ```
pub fn get_float_or(ctx: Context, key: String, default: Float) -> Float {
  context.get_float_or(ctx, key, default)
}

/// Parse a float value from the configuration.
///
/// If the value is not a float, it will be converted to a float.
/// An error will be returned if the value is not a float or cannot be
/// converted to a float.
///
/// Example:
///
/// ```gleam
/// case yodel.parse_float(ctx, "foo") {
///   Ok(value) -> value // 99.999
///   Error(e) -> Error(e)
/// }
/// ```
pub fn parse_float(ctx: Context, key: String) -> Result(Float, PropertiesError) {
  context.parse_float(ctx, key)
}

/// Get a boolean value from the configuration.
/// If the value is not a boolean, an error will be returned.
///
/// Example:
///
/// ```gleam
/// case yodel.get_bool(ctx, "foo") {
///   Ok(value) -> value // True
///   Error(e) -> Error(e)
/// }
pub fn get_bool(ctx: Context, key: String) -> Result(Bool, PropertiesError) {
  context.get_bool(ctx, key)
}

/// Get a boolean value from the configuration, or a default value if the key is not found.
///
/// Example:
///
/// ```gleam
/// let value = yodel.get_bool_or(ctx, "foo", False)
/// ```
pub fn get_bool_or(ctx: Context, key: String, default: Bool) -> Bool {
  context.get_bool_or(ctx, key, default)
}

/// Parse a bool value from the configuration.
///
/// If the value is not a bool, it will be converted to a bool.
/// An error will be returned if the value is not a bool or cannot be
/// converted to a bool.
///
/// Example:
///
/// ```gleam
/// case yodel.parse_bool(ctx, "foo") {
///   Ok(value) -> value // True
///   Error(e) -> Error(e)
/// }
/// ```
pub fn parse_bool(ctx: Context, key: String) -> Result(Bool, PropertiesError) {
  context.parse_bool(ctx, key)
}

/// The default options for loading a configuration file.
///
/// Default Options:
///
/// - Format: `format_auto`
/// - Resolve Enabled: `True`
/// - Resolve Mode: `resolve_lenient`
///
/// Example:
///
/// ```gleam
/// let assert Ok(ctx) =
///   yodel.default_options()
///   |> yodel.load_with_options("config.toml")
/// ```
pub fn default_options() -> Options {
  options.default()
}

/// Set the format of the configuration file.
///
/// Example:
///
/// ```gleam
/// let assert Ok(ctx) =
///   yodel.default_options()
///   |> yodel.with_format(yodel.format_json)
///   |> yodel.load_with_options("config.json")
/// ```
pub fn with_format(options options: Options, format format: Format) -> Options {
  options.with_format(options:, format:)
}

/// Set the format of the configuration file to JSON.
///
/// Example:
///
/// ```gleam
/// let assert Ok(ctx) =
///   yodel.default_options()
///   |> yodel.as_json()
///   |> yodel.load_with_options(config_content)
/// ```
pub fn as_json(options options: Options) -> Options {
  with_format(options, format_json)
}

/// Set the format of the configuration file to TOML.
///
/// Example:
///
/// ```gleam
/// let assert Ok(ctx) =
///   yodel.default_options()
///   |> yodel.as_toml()
///   |> yodel.load_with_options("config.toml")
/// ```
pub fn as_toml(options options: Options) -> Options {
  with_format(options, format_toml)
}

/// Set the format of the configuration file to YAML.
///
/// Example:
///
/// ```gleam
/// let assert Ok(ctx) =
///   yodel.default_options()
///   |> yodel.as_yaml()
///   |> yodel.load_with_options("config.json")
/// ```
pub fn as_yaml(options options: Options) -> Options {
  with_format(options, format_yaml)
}

/// Attempt to automatically detect the format of the configuration file.
///
/// If the input is a file, we first try to detect the format from the file extension.
/// If that fails, we try to detect the format from the content of the file.
///
/// If the input is a string, we try to detect the format from the content.
///
/// If Auto Detection fails, an error will be returned because we can't safely proceed.
/// If this happens, try specifying the format using `as_json`, `as_toml`, `as_yaml`, or `with_format`.
///
/// Example:
///
/// ```gleam
/// let assert Ok(ctx) =
///   yodel.default_options()
///   |> yodel.as_auto()
///   |> yodel.load_with_options("config.yaml")
/// ```
pub fn as_auto(options options: Options) -> Options {
  with_format(options, format_auto)
}

/// Enable or disable placeholder resolution.
///
/// Example:
///
/// ```gleam
/// let assert Ok(ctx) =
///   yodel.default_options()
///   |> yodel.with_resolve_enabled(False)
///   |> yodel.load_with_options("config.yaml")
/// ```
pub fn with_resolve_enabled(
  options options: Options,
  resolve_enabled resolve_enabled: Bool,
) -> Options {
  options.with_resolve_enabled(options:, resolve_enabled:)
}

/// Enable placeholder resolution.
///
/// Example:
///
/// ```gleam
/// let assert Ok(ctx) =
///   yodel.default_options()
///   |> yodel.resolve_enabled()
///   |> yodel.load_with_options("config.yaml")
/// ```
pub fn resolve_enabled(options options: Options) -> Options {
  with_resolve_enabled(options, True)
}

/// Disable placeholder resolution.
///
/// Example:
///
/// ```gleam
/// let assert Ok(ctx) =
///   yodel.default_options()
///   |> yodel.resolve_disabled()
///   |> yodel.load_with_options("config.yaml")
/// ```
pub fn resolve_disabled(options options: Options) -> Options {
  with_resolve_enabled(options, False)
}

/// Set the resolve mode.
///
/// Example:
///
/// ```gleam
/// let assert Ok(ctx) =
///   yodel.default_options()
///   |> yodel.with_resolve_mode(yodel.resolve_strict)
///   |> yodel.load_with_options("config.json")
/// ```
pub fn with_resolve_mode(
  options options: Options,
  resolve_mode resolve_mode: ResolveMode,
) -> Options {
  options.with_resolve_mode(options:, resolve_mode:)
}

/// Set the resolve mode to strict.
///
/// Example:
/// ```gleam
/// let assert Ok(ctx) =
///   yodel.default_options()
///   |> yodel.with_resolve_strict()
///   |> yodel.load_with_options(config_content)
/// ```
pub fn with_resolve_strict(options options: Options) -> Options {
  with_resolve_mode(options, resolve_strict)
}

/// Set the resolve mode to lenient.
///
/// Example:
///
/// ```gleam
/// let assert Ok(ctx) =
///   yodel.default_options()
///   |> yodel.with_resolve_lenient()
///   |> yodel.load_with_options(config_content)
pub fn with_resolve_lenient(options options: Options) -> Options {
  with_resolve_mode(options, resolve_lenient)
}

/// Set the base name for configuration files when loading from a directory.
///
/// The base name is used to identify configuration files matching the pattern
/// `{base_name}[-{profile}].{ext}`. For example, with base name `"settings"`:
///
/// - `settings.yaml` → base config
/// - `settings-dev.yaml` → dev profile
/// - `settings-prod.toml` → prod profile
///
/// **Default:** `"config"`
///
/// Example:
///
/// ```gleam
/// let assert Ok(ctx) =
///   yodel.default_options()
///   |> yodel.with_config_base_name("settings")
///   |> yodel.load_with_options("./config-dir")
/// // Looks for: settings.yaml, settings-dev.yaml, etc.
/// ```
pub fn with_config_base_name(
  options options: Options,
  config_base_name config_base_name: String,
) -> Options {
  options.with_config_base_name(options:, config_base_name:)
}

/// Set the active configuration profiles to load.
///
/// Profiles allow environment-specific configuration overrides.
/// Profile configs are merged in the order specified, with later profiles
/// overriding earlier ones.
///
/// **Note:** The `YODEL_PROFILES` environment variable takes precedence over
/// programmatically set profiles.
///
/// Example:
///
/// ```gleam
/// let assert Ok(ctx) =
///   yodel.default_options()
///   |> yodel.with_profiles(["dev", "local"])
///   |> yodel.load_with_options("./config-dir")
/// // Loads: config.yaml, config-dev.yaml, config-local.yaml
/// // Values in config-local.yaml override config-dev.yaml
/// // Values in config-dev.yaml override config.yaml
/// ```
pub fn with_profiles(
  options options: Options,
  profiles profiles: List(String),
) -> Options {
  options.with_profiles(options:, profiles:)
}

/// Format a `ConfigError` into a human-readable string.
pub fn describe_config_error(error: ConfigError) -> String {
  errors.format_config_error(error)
}

/// Loads a single configuration file or string content.
fn load_single_file(
  input: String,
  options: Options,
) -> Result(Context, ConfigError) {
  load_to_properties(input, options) |> result.map(context.new)
}

/// Loads a single content source into Properties.
fn load_to_properties(
  input: String,
  options: Options,
) -> Result(Properties, ConfigError) {
  use content <- read(input)
  use format <- select(input, content, options)
  use resolved <- resolve(content, options)
  use parsed <- parse(resolved, format)
  use validated <- validate(parsed)
  Ok(validated)
}

/// Loads multiple configuration files from a directory.
///
/// Discovers and loads files in order: base config, then active profile configs.
/// Later configs override values from earlier ones.
fn load_from_directory(
  directory: String,
  options: Options,
) -> Result(Context, ConfigError) {
  let base_name = options.get_config_base_name(options)

  use config_files <- discover(directory, base_name, options)
  use properties_list <- load_dirs(config_files, options)
  use merged <- merge(properties_list)
  use validated <- result.try(validator.validate_properties(merged))

  Ok(context.new(validated))
}

fn read(
  input: String,
  next: fn(String) -> Result(Properties, ConfigError),
) -> Result(Properties, ConfigError) {
  case input.get_content(input) {
    Ok(content) -> Ok(content)
    Error(e) -> Error(e)
  }
  |> result.try(next)
}

fn select(
  input: String,
  content: String,
  options: Options,
  next: fn(Format) -> Result(Properties, ConfigError),
) -> Result(Properties, ConfigError) {
  let formats = [
    FormatDetector("toml", toml.detect),
    FormatDetector("json/yaml", yaml.detect),
  ]
  case format.get_format(input, content, options, formats) {
    options.Json -> format_json
    options.Toml -> format_toml
    options.Yaml -> format_yaml
    options.Auto -> format_auto
  }
  |> Ok
  |> result.try(next)
}

fn resolve(
  input: String,
  options: Options,
  next: fn(String) -> Result(Properties, ConfigError),
) -> Result(Properties, ConfigError) {
  case options.is_resolve_enabled(options) {
    True -> resolver.resolve_placeholders(input, options)
    False -> input |> Ok
  }
  |> result.try(next)
}

fn parse(
  input: String,
  format: Format,
  next: fn(Properties) -> Result(Properties, ConfigError),
) -> Result(Properties, ConfigError) {
  parser.parse(input, format)
  |> result.try(next)
}

fn validate(
  props: Properties,
  handler: fn(Properties) -> Result(Properties, ConfigError),
) -> Result(Properties, ConfigError) {
  validator.validate_properties(props)
  |> result.try(handler)
}

fn discover(
  directory: String,
  base_name: String,
  options: Options,
  next: fn(List(ConfigFile)) -> Result(Context, ConfigError),
) -> Result(Context, ConfigError) {
  profiles.discover_configs(directory, base_name, options)
  |> result.try(next)
}

fn load_dirs(
  config_files: List(ConfigFile),
  options: Options,
  next: fn(List(Properties)) -> Result(Context, ConfigError),
) -> Result(Context, ConfigError) {
  list.try_map(config_files, fn(cf) { load_to_properties(cf.path, options) })
  |> result.try(next)
}

fn merge(
  properties_list: List(Properties),
  next: fn(Properties) -> Result(Context, ConfigError),
) -> Result(Context, ConfigError) {
  list.fold(properties_list, properties.new(), properties.merge)
  |> next
}
