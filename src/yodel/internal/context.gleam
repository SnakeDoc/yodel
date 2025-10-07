import gleam/float
import gleam/int
import gleam/result
import gleam/string
import yodel/errors.{
  type PropertiesError, ExpectedBool, ExpectedFloat, ExpectedInt, ExpectedString,
  TypeError,
}
import yodel/internal/properties.{type Properties}
import yodel/value.{BoolValue, FloatValue, IntValue, StringValue}

pub opaque type Context {
  Context(properties: Properties)
}

pub fn new(from properties: Properties) -> Context {
  Context(properties:)
}

pub fn get_string(ctx: Context, path: String) -> Result(String, PropertiesError) {
  case properties.get(ctx.properties, path) {
    Ok(StringValue(value)) -> Ok(value)
    Ok(value) -> Error(TypeError(path:, error: ExpectedString(got: value)))
    Error(e) -> Error(e)
  }
}

pub fn parse_string(
  ctx: Context,
  path: String,
) -> Result(String, PropertiesError) {
  case get_string(ctx, path) {
    Ok(value) -> Ok(value)
    Error(TypeError(..)) -> {
      case properties.get(ctx.properties, path) {
        Ok(value) -> Ok(string.inspect(value))
        Error(e) -> Error(e)
      }
    }
    Error(e) -> Error(e)
  }
}

pub fn get_string_or(ctx: Context, path: String, default: String) -> String {
  case get_string(ctx, path) {
    Ok(value) -> value
    Error(_) -> default
  }
}

pub fn get_int(ctx: Context, path: String) -> Result(Int, PropertiesError) {
  case properties.get(ctx.properties, path) {
    Ok(IntValue(value)) -> Ok(value)
    Ok(value) -> Error(TypeError(path:, error: ExpectedInt(got: value)))
    Error(e) -> Error(e)
  }
}

pub fn parse_int(ctx: Context, path: String) -> Result(Int, PropertiesError) {
  case get_int(ctx, path) {
    Ok(value) -> Ok(value)
    Error(TypeError(..)) -> {
      case parse_string(ctx, path) {
        Ok(value) ->
          int.parse(value)
          |> result.map_error(fn(_) {
            TypeError(path:, error: ExpectedInt(got: StringValue(value)))
          })
        Error(e) -> Error(e)
      }
    }
    Error(e) -> Error(e)
  }
}

pub fn get_int_or(ctx: Context, path: String, default: Int) -> Int {
  case get_int(ctx, path) {
    Ok(value) -> value
    Error(_) -> default
  }
}

pub fn get_float(ctx: Context, path: String) -> Result(Float, PropertiesError) {
  case properties.get(ctx.properties, path) {
    Ok(FloatValue(value)) -> Ok(value)
    Ok(value) -> Error(TypeError(path:, error: ExpectedFloat(got: value)))
    Error(e) -> Error(e)
  }
}

pub fn parse_float(ctx: Context, path: String) -> Result(Float, PropertiesError) {
  case get_float(ctx, path) {
    Ok(value) -> Ok(value)
    Error(TypeError(..)) -> {
      case parse_string(ctx, path) {
        Ok(value) ->
          float.parse(value)
          |> result.map_error(fn(_) {
            TypeError(path:, error: ExpectedFloat(got: StringValue(value)))
          })
        Error(e) -> Error(e)
      }
    }
    Error(e) -> Error(e)
  }
}

pub fn get_float_or(ctx: Context, path: String, default: Float) -> Float {
  case get_float(ctx, path) {
    Ok(value) -> value
    Error(_) -> default
  }
}

pub fn get_bool(ctx: Context, path: String) -> Result(Bool, PropertiesError) {
  case properties.get(ctx.properties, path) {
    Ok(BoolValue(value)) -> Ok(value)
    Ok(value) -> Error(TypeError(path:, error: ExpectedBool(got: value)))
    Error(e) -> Error(e)
  }
}

pub fn parse_bool(ctx: Context, path: String) -> Result(Bool, PropertiesError) {
  case get_string(ctx, path) {
    Ok(value) ->
      case value |> string.lowercase |> string.trim {
        "true" -> Ok(True)
        "false" -> Ok(False)
        _ ->
          Error(TypeError(path:, error: ExpectedBool(got: StringValue(value))))
      }
    Error(e) -> Error(e)
  }
}

pub fn get_bool_or(ctx: Context, path: String, default: Bool) -> Bool {
  case get_bool(ctx, path) {
    Ok(value) -> value
    Error(_) -> default
  }
}
