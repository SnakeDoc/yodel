import envoy
import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}
import gleam/string
import yodel.{type Format}

/// Convert a Format to its string representation.
pub fn to_string(format: Format) {
  format
  |> string.inspect
  |> string.lowercase
}

/// Temporarily set environment variables for the duration of a test.
///
/// Preserves existing environment variables and restores them after the test.
/// Use this when tests need specific environment variable states.
///
/// Example:
/// ```gleam
/// let env = dict.from_list([#("YODEL_PROFILES", Some("dev"))])
/// use <- with_env(env)
/// // Test code that needs YODEL_PROFILES=dev
/// ```
pub fn with_env(envs: Dict(String, Option(String)), handler: fn() -> Nil) {
  use old_envs <- preserve_envs(envs)
  use <- set_envs(envs)
  use <- do_then_restore_envs(old_envs)
  handler()
}

fn preserve_envs(
  envs: Dict(String, Option(String)),
  next: fn(Dict(String, Option(String))) -> Nil,
) -> Nil {
  dict.map_values(envs, fn(key, _) {
    case envoy.get(key) {
      Ok(value) -> Some(value)
      _ -> None
    }
  })
  |> next
}

fn set_envs(envs: Dict(String, Option(String)), next: fn() -> Nil) -> Nil {
  dict.each(envs, fn(key, value) {
    case value {
      Some(value) -> envoy.set(key, value)
      None -> envoy.unset(key)
    }
  })
  next()
}

fn do_then_restore_envs(
  old_envs: Dict(String, Option(String)),
  first: fn() -> Nil,
) -> Nil {
  let result = first()
  dict.each(old_envs, fn(key, old_value) {
    case old_value {
      Some(old_value) -> envoy.set(key, old_value)
      None -> envoy.unset(key)
    }
  })
  result
}
