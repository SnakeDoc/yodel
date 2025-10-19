import yodel/errors.{
  type ConfigError, EmptyConfig, InvalidConfig, ValidationError,
}
import yodel/internal/properties.{type Properties}

/// Validate that the properties are not empty or malformed.
pub fn validate_properties(props: Properties) -> Result(Properties, ConfigError) {
  case properties.size(props) {
    0 -> EmptyConfig |> ValidationError |> Error
    1 -> {
      case properties.get(props, "") {
        Ok(_) ->
          InvalidConfig("Invalid config: value without key")
          |> ValidationError
          |> Error
        Error(_) -> props |> Ok
      }
    }
    _ -> props |> Ok
  }
}
