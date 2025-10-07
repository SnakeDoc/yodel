//// Yodel is a type-safe configuration loader for Gleam that handles JSON,
//// YAML, and TOML configs with automatic format detection, environment variable
//// resolution, and an intuitive dot-notation API for accessing your config
//// values.
////
//// ```gleam
//// import yodel
////
//// let ctx = yodel.load("config.toml")
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

import gleam/result
import yodel/errors.{type ConfigError, type PropertiesError}
import yodel/internal/context
import yodel/internal/format.{FormatDetector}
import yodel/internal/input
import yodel/internal/options
import yodel/internal/parser
import yodel/internal/parsers/toml
import yodel/internal/parsers/yaml
import yodel/internal/properties.{type Properties}
import yodel/internal/resolver
import yodel/internal/validator

/// The Context type, representing a configuration context.
/// This is the main type used to hold configuration values.
/// It is opaque, meaning you cannot access the properties directly.
/// Use the provided functions to access the configuration values.
pub type Context =
  context.Context

/// The Options type, representing configurable options for Yodel.
/// This is used to customize the behavior of the configuration loader.
/// It is opaque, meaning you cannot access the options directly.
/// Use the provided functions to create and modify options.
pub type Options =
  options.Options

/// The Resolve Mode to use, either `resolve_strict` or `resolve_lenient`.
/// `resolve_strict` will fail if any placeholder is unresolved.
/// `resolve_lenient`, the default, will preserve unresolved placeholders.
pub type ResolveMode =
  options.ResolveMode

/// Strict Resolve Mode - Fail if any placeholder is unresolved.
pub const resolve_strict = options.Strict

/// Lenient Resolve Mode - Preserve unresolved placeholders.
///
/// This means `${foo}` will remain as `${foo}` if `foo` is not defined.
///
/// **This is the default.**
pub const resolve_lenient = options.Lenient

/// The format of the configuration file. Defaults to `Auto`.
pub type Format =
  options.Format

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

/// Load a configuration file.
///
/// This function will read the config content, detect the format,
/// resolve the placeholders, parse the config content, returning a `Context` if successful.
///
/// `input` can be a file path or a string containing the configuration content.
///
/// Example:
///
/// ```gleam
/// let ctx = yodel.load("config.toml")
///
/// let content = "foo: bar" // yaml content
/// let ctx = yodel.load(content)
/// ```
pub fn load(from input: String) -> Result(Context, ConfigError) {
  load_with_options(default_options(), input)
}

/// Load a configuration file with options.
///
/// This function will use the provided options to read and parse the config content,
/// returning a `Context` if successful.
pub fn load_with_options(
  with options: Options,
  from input: String,
) -> Result(Context, ConfigError) {
  use content <- read(input)
  use format <- select(input, content, options)
  use resolved <- resolve(content, options)
  use parsed <- parse(resolved, format)
  use validated <- validate(parsed)
  Ok(context.new(validated))
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
/// - Format: `auto_format`
/// - Resolve Enabled: `True`
/// - Resolve Mode: `lenient_resolve`
///
/// Example:
///
/// ```gleam
/// let ctx =
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
/// let ctx =
///   yodel.default_options()
///   |> yodel.with_format(yodel.json_format)
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
/// let ctx =
///   yodel.default_options()
///   |> yodel.as_json()
///   |> yodel.load_with_options(my_config)
/// ```
pub fn as_json(options options: Options) -> Options {
  with_format(options, format_json)
}

/// Set the format of the configuration file to TOML.
///
/// Example:
///
/// ```gleam
/// let ctx =
///   yodel.default_options()
///   |> yodel.as_toml()
///   |> yodel.load_with_options(my_config)
/// ```
pub fn as_toml(options options: Options) -> Options {
  with_format(options, format_toml)
}

/// Set the format of the configuration file to YAML.
///
/// Example:
///
/// ```gleam
/// let ctx =
///   yodel.default_options()
///   |> yodel.as_yaml()
///   |> yodel.load_with_options(my_config)
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
/// let ctx =
///   yodel.default_options()
///   |> yodel.as_auto()
///   |> yodel.load_with_options(my_config)
/// ```
pub fn as_auto(options options: Options) -> Options {
  with_format(options, format_auto)
}

/// Enable or disable placeholder resolution.
///
/// Example:
///
/// ```gleam
/// let ctx =
///   yodel.default_options()
///   |> yodel.with_resolve_enabled(False)
///   |> yodel.load_with_options("config.yaml")
/// ```
pub fn with_resolve_enabled(
  options options: Options,
  enabled enabled: Bool,
) -> Options {
  options.with_resolve_enabled(options:, enabled:)
}

/// Enable placeholder resolution.
///
/// Example:
///
/// ```gleam
/// let ctx =
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
/// let ctx =
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
/// let ctx =
///   yodel.default_options()
///   |> yodel.with_resolve_mode(yodel.strict_resolve)
///   |> yodel.load_with_options("config.json")
/// ```
pub fn with_resolve_mode(
  options options: Options,
  mode mode: ResolveMode,
) -> Options {
  options.with_resolve_mode(options:, mode:)
}

/// Set the resolve mode to strict.
///
/// Example:
/// ```gleam
/// let ctx =
///   yodel.default_options()
///   |> yodel.with_resolve_strict()
///   |> yodel.load_with_options(my_config)
/// ```
pub fn with_resolve_strict(options options: Options) -> Options {
  with_resolve_mode(options, resolve_strict)
}

/// Set the resolve mode to lenient.
///
/// Example:
///
/// ```gleam
/// let ctx =
///   yodel.default_options()
///   |> yodel.with_resolve_lenient()
///   |> yodel.load_with_options(my_config)
pub fn with_resolve_lenient(options options: Options) -> Options {
  with_resolve_mode(options, resolve_lenient)
}

/// Get the format of the configuration file.
///
/// Example:
///
/// ```gleam
/// let format = yodel.get_format(options)
/// ```
pub fn get_format(options options: Options) -> Format {
  options.get_format(options)
}

/// Check if placeholder resolution is enabled.
///
/// Example:
///
/// ```gleam
/// case yodel.is_resolve_enabled(options) {
///   True -> "Resolution is enabled"
///   False -> "Resolution is disabled"
/// }
/// ```
pub fn is_resolve_enabled(options options: Options) -> Bool {
  options.is_resolve_enabled(options)
}

/// Get the resolve mode.
///
/// Example:
///
/// ```gleam
/// let mode = yodel.get_resolve_mode(options)
/// ```
pub fn get_resolve_mode(options options: Options) -> ResolveMode {
  options.get_resolve_mode(options)
}

fn parse(
  input: String,
  format: Format,
  next: fn(Properties) -> Result(Context, ConfigError),
) -> Result(Context, ConfigError) {
  parser.parse(input, format)
  |> result.try(next)
}

fn validate(
  props: Properties,
  handler: fn(Properties) -> Result(Context, ConfigError),
) -> Result(Context, ConfigError) {
  validator.validate_properties(props)
  |> result.try(handler)
}

fn resolve(
  input: String,
  options: Options,
  handler: fn(String) -> Result(Context, ConfigError),
) -> Result(Context, ConfigError) {
  case options.is_resolve_enabled(options) {
    True -> resolver.resolve_placeholders(input, options)
    False -> input |> Ok
  }
  |> result.try(handler)
}

fn read(
  input: String,
  handler: fn(String) -> Result(Context, ConfigError),
) -> Result(Context, ConfigError) {
  case input.get_content(input) {
    Ok(content) -> Ok(content)
    Error(e) -> Error(e)
  }
  |> result.try(handler)
}

fn select(
  input: String,
  content: String,
  options: Options,
  handler: fn(Format) -> Result(Context, ConfigError),
) -> Result(Context, ConfigError) {
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
  |> result.try(handler)
}
