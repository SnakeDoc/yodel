//// Value type used in configuration error messages.
////
//// **Note:** This type is re-exported from the main `yodel` module.
//// Import it via `import yodel` rather than importing this module directly.

/// Represents a value in the configuration.
///
/// This type appears in error messages when type mismatches occur,
/// allowing you to see what value was actually found.
pub type Value {
  StringValue(String)
  IntValue(Int)
  FloatValue(Float)
  BoolValue(Bool)
  NullValue
}
