import envoy
import gleam/dict
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import yodel/errors.{type ConfigError, InvalidConfig, ValidationError}
import yodel/internal/input
import yodel/internal/parser
import yodel/options.{type Options}

/// Represents a configuration file with its path and optional profile.
pub type ConfigFile {
  ConfigFile(path: String, profile: Option(String))
}

/// Get active profiles from options and environment variable.
///
/// Environment variable (`YODEL_PROFILES`) takes precedence over programmatically set profiles.
/// Returns a list of profile names parsed from comma-separated values.
pub fn active_profiles(options: Options) -> List(String) {
  case options |> options.get_profile_env_var |> envoy.get {
    Ok(value) ->
      value
      |> string.trim
      |> string.split(",")
      |> list.map(string.trim)
      |> list.filter(fn(p) { p != "" })
    Error(_) -> options |> options.get_profiles
  }
}

/// Discover config files in a directory matching the base name pattern.
///
/// Finds all config files matching the pattern `{base_name}[-{profile}].{ext}` and returns them ordered as:
/// base config (if present) followed by active profile configs in the order specified by `active_profiles`.
///
/// Returns an error if duplicate base or profile configs are found.
pub fn discover_configs(
  directory: String,
  base_name: String,
  options: Options,
) -> Result(List(ConfigFile), ConfigError) {
  use files <- result.try(input.list_files(directory))

  let active_profiles = active_profiles(options)

  let config_files =
    files |> list.filter_map(fn(path) { parse_config_file(path, base_name) })

  use _ <- result.try(config_files |> check_for_duplicates)

  let base_configs = config_files |> list.filter(fn(cf) { cf.profile == None })

  let active_configs =
    active_profiles
    |> list.filter_map(fn(profile_name) {
      config_files
      |> list.find(fn(cf) {
        case cf.profile {
          Some(p) -> p == profile_name
          None -> False
        }
      })
      |> result.replace_error(Nil)
    })

  case base_configs {
    [] -> Ok(active_configs)
    [base] -> Ok([base, ..active_configs])
    // This should be caught by check_for_duplicates, but just in case.
    [first, second, ..] -> {
      let error_msg =
        "Multiple base config files found: "
        <> first.path
        <> " and "
        <> second.path
      Error(ValidationError(InvalidConfig(error_msg)))
    }
  }
}

/// Verifies no duplicate base or profile configs exist.
///
/// Returns an error if any profile (including base) has multiple config files.
fn check_for_duplicates(
  config_files: List(ConfigFile),
) -> Result(Nil, ConfigError) {
  config_files |> group_by_profile |> check_groups_for_duplicates
}

/// Groups config files by their profile name.
///
/// Base configs (no profile) are grouped under `None`.
/// Profile configs are grouped under `Some(profile_name)`.
fn group_by_profile(
  config_files: List(ConfigFile),
) -> List(#(Option(String), List(ConfigFile))) {
  config_files
  |> list.group(fn(cf) { cf.profile })
  |> dict.to_list
}

/// Validates that each profile (including base) has only one config file.
fn check_groups_for_duplicates(
  groups: List(#(Option(String), List(ConfigFile))),
) -> Result(Nil, ConfigError) {
  case groups {
    [] -> Ok(Nil)
    [#(profile, configs), ..rest] -> {
      case configs {
        [] | [_] -> check_groups_for_duplicates(rest)
        [first, second, ..] -> {
          let error_msg = case profile {
            None ->
              "Multiple base config files found: "
              <> first.path
              <> " and "
              <> second.path
            Some(name) ->
              "Multiple config files found for profile '"
              <> name
              <> "': "
              <> first.path
              <> " and "
              <> second.path
          }
          Error(ValidationError(InvalidConfig(error_msg)))
        }
      }
    }
  }
}

/// Parses a file path to determine if it's a valid config file.
///
/// Returns `ConfigFile` with extracted profile name, or `Error(Nil)` if the
/// file doesn't match the config pattern.
fn parse_config_file(path: String, base_name: String) -> Result(ConfigFile, Nil) {
  let filename = extract_filename(path)

  case matches_base_pattern(filename, base_name) {
    True -> {
      case extract_profile(filename, base_name) {
        Some(profile) -> Ok(ConfigFile(path, Some(profile)))
        None -> Ok(ConfigFile(path, None))
      }
    }
    False -> Error(Nil)
  }
}

/// Checks if a filename matches the config file pattern.
///
/// Pattern: `{base_name}[-{profile}].{ext}` where ext is a supported format.
fn matches_base_pattern(filename: String, base_name: String) -> Bool {
  string.starts_with(filename, base_name) && has_config_extension(filename)
}

/// Checks if a filename has a supported configuration file extension.
fn has_config_extension(filename: String) -> Bool {
  let ext = input.get_extension_from_path(filename)
  parser.supported_extensions() |> list.contains(ext)
}

/// Extracts the profile name from a config filename.
///
/// Examples:
/// - `"config-dev.yaml"` → `Some("dev")`
/// - `"config.yaml"` → `None`
/// - `"config-prod-us.toml"` → `Some("prod-us")`
fn extract_profile(filename: String, base_name: String) -> Option(String) {
  let without_ext = remove_extension(filename)

  case without_ext == base_name {
    True -> None
    False -> {
      let prefix = base_name <> "-"
      case string.starts_with(without_ext, prefix) {
        True -> {
          string.drop_start(without_ext, string.length(prefix)) |> Some
        }
        False -> None
      }
    }
  }
}

/// Extracts just the filename from a full file path.
fn extract_filename(path: String) -> String {
  path |> string.split("/") |> list.last |> result.unwrap("")
}

/// Removes the file extension from a filename.
fn remove_extension(filename: String) -> String {
  let parts = string.split(filename, ".")
  parts |> list.take(list.length(parts) - 1) |> string.join(".")
}
