import envoy
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regexp.{type CompileError, type Regexp}
import gleam/result
import gleam/string
import yodel/errors.{
  type ConfigError, RegexError, ResolverError, UnresolvedPlaceholder,
}
import yodel/options.{type Options, type ResolveMode, Lenient, Strict}

const placeholder_pattern = "\\$\\{([^:}]+)(?::((?:[^${}]+|\\$\\{(?:[^{}]*\\{[^{}]*\\})*[^{}]*\\})*))?\\}"

type Placeholder {
  Placeholder(content: String, env_var: String, default: Option(String))
}

pub fn resolve_placeholders(
  input: String,
  options: Options,
) -> Result(String, ConfigError) {
  use pattern <- result.try(compile_placeholder_regex())

  case resolve_value(input, pattern, options.get_resolve_mode(options), []) {
    Ok(resolved_value) -> Ok(resolved_value)
    Error(e) -> Error(e)
  }
}

fn resolve_value(
  value: String,
  pattern: Regexp,
  mode: ResolveMode,
  attempted: List(String),
) -> Result(String, ConfigError) {
  case find_next_placeholder(value, pattern) {
    None -> Ok(value)
    Some(placeholder) -> {
      case list.contains(attempted, placeholder.env_var) {
        True ->
          case mode {
            Lenient -> Ok(value)
            Strict ->
              Error(
                ResolverError(UnresolvedPlaceholder(
                  placeholder.env_var,
                  placeholder.content,
                )),
              )
          }
        False -> {
          use resolved <- result.try(resolve_placeholder(placeholder, mode))
          let updated = string.replace(value, placeholder.content, resolved)
          resolve_value(updated, pattern, mode, [
            placeholder.env_var,
            ..attempted
          ])
        }
      }
    }
  }
}

fn find_next_placeholder(value: String, pattern: Regexp) -> Option(Placeholder) {
  case regexp.scan(pattern, value) {
    [] -> None
    [match, ..] -> {
      case match.submatches {
        [Some(env_var), default] ->
          Some(Placeholder(match.content, env_var, default))
        [Some(env_var)] -> Some(Placeholder(match.content, env_var, None))
        _ -> None
      }
    }
  }
}

fn resolve_placeholder(
  placeholder: Placeholder,
  mode: ResolveMode,
) -> Result(String, ConfigError) {
  case envoy.get(placeholder.env_var) {
    Ok(value) -> Ok(value)
    Error(_) ->
      case placeholder.default, mode {
        Some(default_value), _ -> Ok(default_value)
        None, Lenient -> Ok(placeholder.content)
        None, Strict ->
          Error(
            ResolverError(UnresolvedPlaceholder(
              placeholder.env_var,
              placeholder.content,
            )),
          )
      }
  }
}

fn compile_placeholder_regex() -> Result(Regexp, ConfigError) {
  regexp.from_string(placeholder_pattern) |> result.map_error(map_compile_error)
}

fn map_compile_error(error: CompileError) -> ConfigError {
  ResolverError(RegexError(
    error.error <> " at " <> int.to_string(error.byte_index),
  ))
}
