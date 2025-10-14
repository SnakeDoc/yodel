//// Error types returned when loading, parsing, or accessing configuration.
////
//// **Note:** These types are re-exported from the main `yodel` module.
//// Import them via `import yodel` rather than importing this module directly.

import gleam/int
import yodel/value.{type Value}

/// Errors that can occur when loading configuration.
pub type ConfigError {
  FileError(FileError)
  ParseError(ParseError)
  ResolverError(ResolverError)
  ValidationError(ValidationError)
}

/// Errors that occur when reading configuration files.
pub type FileError {
  FileNotFound(path: String)
  FilePermissionDenied(path: String)
  FileReadError(details: String)
  NotAFile(path: String)
}

/// Errors that occur when parsing configuration content.
pub type ParseError {
  InvalidSyntax(SyntaxError)
  InvalidStructure(details: String)
  UnknownFormat
}

/// Syntax errors with location information.
pub type SyntaxError {
  SyntaxError(format: String, location: Location, message: String)
}

/// Location of a syntax error in the source file.
pub type Location {
  Location(line: Int, column: Int)
}

/// Errors that occur when resolving environment variable placeholders.
pub type ResolverError {
  UnresolvedPlaceholder(placeholder: String, value: String)
  RegexError(details: String)
  NoPlaceholderFound
}

/// Errors that occur during configuration validation.
pub type ValidationError {
  EmptyConfig
  InvalidConfig(details: String)
}

/// Errors that occur when accessing configuration values.
pub type PropertiesError {
  PathNotFound(path: String)
  TypeError(path: String, error: TypeError)
}

/// Type mismatch errors when accessing configuration values.
///
/// Contains the expected type and the actual value that was found.
pub type TypeError {
  ExpectedString(got: Value)
  ExpectedInt(got: Value)
  ExpectedFloat(got: Value)
  ExpectedBool(got: Value)
}

/// Format a `ConfigError` into a human-readable string.
pub fn format_config_error(error: ConfigError) -> String {
  case error {
    FileError(file_error) -> format_file_error(file_error)
    ParseError(parse_error) -> format_parse_error(parse_error)
    ResolverError(resolve_error) -> format_resolve_error(resolve_error)
    ValidationError(validation_error) ->
      format_validation_error(validation_error)
  }
}

fn format_file_error(error: FileError) -> String {
  case error {
    FileNotFound(path) -> "File not found: " <> path
    FilePermissionDenied(path) -> "Permission denied: " <> path
    FileReadError(details) -> "Error reading file: " <> details
    NotAFile(path) -> "Not a file: " <> path
  }
}

fn format_parse_error(error: ParseError) -> String {
  case error {
    InvalidSyntax(error) -> format_syntax_error(error)
    InvalidStructure(details) -> details
    UnknownFormat -> "Unable to determine config format"
  }
}

fn format_syntax_error(error: SyntaxError) -> String {
  let SyntaxError(format, location, message) = error
  let Location(line, column) = location
  "Syntax error in "
  <> format
  <> " at line "
  <> int.to_string(line)
  <> ", column "
  <> int.to_string(column)
  <> ": "
  <> message
}

fn format_resolve_error(error: ResolverError) -> String {
  case error {
    UnresolvedPlaceholder(placeholder, value) ->
      "Could not resolve placeholder '"
      <> placeholder
      <> "' in value \""
      <> value
      <> "\""
    RegexError(details) -> "Regex error: " <> details
    NoPlaceholderFound -> "No placeholder found"
  }
}

fn format_validation_error(error: ValidationError) -> String {
  case error {
    EmptyConfig -> "Empty config"
    InvalidConfig(details) -> "Invalid config: " <> details
  }
}
