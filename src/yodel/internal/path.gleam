import gleam/int
import gleam/list

pub opaque type PathSegment {
  Key(String)
  Index(Int)
}

/// Represents a path to a value in the configuration tree.
///
/// Paths are built from segments representing object keys and array indices.
pub type Path =
  List(PathSegment)

/// Create a new empty path.
pub fn new() -> Path {
  list.new()
}

/// Add a key segment to the path.
///
/// Prepends a property key to the path.
/// Used by parsers when building the configuration tree from nested objects.
pub fn add_segment(path: Path, segment: String) -> Path {
  [Key(segment), ..path]
}

/// Add an array index segment to the path.
///
/// Prepends an array index to the path.
/// Used by parsers when building the configuration tree from arrays.
pub fn add_index(path: Path, index: Int) -> Path {
  [Index(index), ..path]
}

/// Convert a path to its string representation.
pub fn path_to_string(segments: Path) -> String {
  segments
  |> list.fold_right("", fn(acc, segment) {
    case segment {
      Key(key) -> {
        case acc {
          "" -> key
          _ -> acc <> "." <> key
        }
      }
      Index(index) -> acc <> "[" <> int.to_string(index) <> "]"
    }
  })
}
