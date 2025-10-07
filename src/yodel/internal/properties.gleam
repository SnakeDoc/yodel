import gleam/dict.{type Dict}
import gleam/result
import yodel/errors.{type PropertiesError, PathNotFound}
import yodel/internal/path
import yodel/value.{
  type Value, BoolValue, FloatValue, IntValue, NullValue, StringValue,
}

pub opaque type Properties {
  Properties(entries: Dict(Path, Value))
}

pub type Path =
  String

pub fn new() -> Properties {
  Properties(entries: dict.new())
}

pub fn get(
  from props: Properties,
  get path: Path,
) -> Result(Value, PropertiesError) {
  dict.get(props.entries, path)
  |> result.map_error(fn(_) { PathNotFound(path) })
}

pub fn insert(
  into props: Properties,
  for path: Path,
  insert value: Value,
) -> Properties {
  Properties(entries: dict.insert(props.entries, path, value))
}

pub fn merge(
  into old_props: Properties,
  from new_props: Properties,
) -> Properties {
  Properties(dict.merge(old_props.entries, new_props.entries))
}

pub fn fold(
  over props: Properties,
  from initial: a,
  with fun: fn(a, Path, Value) -> a,
) -> a {
  dict.fold(props.entries, initial, fun)
}

pub fn size(of props: Properties) -> Int {
  dict.size(props.entries)
}

pub fn delete(from props: Properties, delete path: path.Path) -> Properties {
  Properties(dict.delete(props.entries, path.path_to_string(path)))
}

pub fn string(for path: path.Path, value value: String) -> Properties {
  insert_string(new(), path.path_to_string(path), value)
}

pub fn int(for path: path.Path, value value: Int) -> Properties {
  insert_int(new(), path.path_to_string(path), value)
}

pub fn float(for path: path.Path, value value: Float) -> Properties {
  insert_float(new(), path.path_to_string(path), value)
}

pub fn bool(for path: path.Path, value value: Bool) -> Properties {
  insert_bool(new(), path.path_to_string(path), value)
}

pub fn null(for path: path.Path) -> Properties {
  insert_null(new(), path.path_to_string(path))
}

pub fn insert_string(
  into props: Properties,
  for path: Path,
  insert value: String,
) -> Properties {
  insert(props, path, StringValue(value))
}

pub fn insert_int(
  into props: Properties,
  for path: Path,
  insert value: Int,
) -> Properties {
  insert(props, path, IntValue(value))
}

pub fn insert_float(
  into props: Properties,
  for path: Path,
  insert value: Float,
) -> Properties {
  insert(props, path, FloatValue(value))
}

pub fn insert_bool(
  into props: Properties,
  for path: Path,
  insert value: Bool,
) -> Properties {
  insert(props, path, BoolValue(value))
}

pub fn insert_null(into props: Properties, for path: Path) -> Properties {
  insert(props, path, NullValue)
}
