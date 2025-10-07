import gleam/int
import yodel/value.{type Value}

pub type PropertiesError {
  PathNotFound(path: String)
  TypeError(path: String, error: TypeError)
}

pub type TypeError {
  ExpectedString(got: Value)
  ExpectedInt(got: Value)
  ExpectedFloat(got: Value)
  ExpectedBool(got: Value)
}

pub type ConfigError {
  FileError(FileError)
  ParseError(ParseError)
  ResolverError(ResolverError)
  ValidationError(ValidationError)
}

pub type FileError {
  FileNotFound(path: String)
  FilePermissionDenied(path: String)
  FileReadError(details: String)
}

pub type ParseError {
  InvalidSyntax(SyntaxError)
  InvalidStructure(details: String)
  UnknownFormat
}

pub type SyntaxError {
  SyntaxError(format: String, location: Location, message: String)
}

pub type Location {
  Location(line: Int, column: Int)
}

pub type ResolverError {
  UnresolvedPlaceholder(placeholder: String, value: String)
  RegexError(details: String)
  NoPlaceholderFound
}

pub type ValidationError {
  EmptyConfig
  InvalidConfig(details: String)
}

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
