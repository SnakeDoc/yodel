import gleam/list
import yodel/errors.{type ConfigError, ParseError, UnknownFormat}
import yodel/internal/parsers/toml
import yodel/internal/parsers/yaml
import yodel/internal/properties.{type Properties}
import yodel/options.{type Format, Auto, Json, Toml, Yaml}

/// Get a list of all supported file extensions across all parsers.
///
/// Returns extensions for TOML, JSON, and YAML formats.
pub fn supported_extensions() -> List(String) {
  list.flatten([
    yaml.supported_extensions(),
    toml.supported_extensions(),
  ])
}

/// Parse configuration content in the specified format.
///
/// Returns an error if the format is `Auto` (format must be determined before parsing)
/// or if the content cannot be parsed.
pub fn parse(
  from content: String,
  with format: Format,
) -> Result(Properties, ConfigError) {
  case format {
    Json -> content |> parse_json
    Toml -> content |> parse_toml
    Yaml -> content |> parse_yaml
    Auto -> Error(ParseError(UnknownFormat))
  }
}

fn parse_json(content: String) -> Result(Properties, ConfigError) {
  // the yaml parser also handles json
  yaml.parse(content)
}

fn parse_toml(content: String) -> Result(Properties, ConfigError) {
  toml.parse(content)
}

fn parse_yaml(content: String) -> Result(Properties, ConfigError) {
  yaml.parse(content)
}
