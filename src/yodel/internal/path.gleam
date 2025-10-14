import gleam/int
import gleam/list

pub opaque type PathSegment {
  Key(String)
  Index(Int)
}

pub type Path =
  List(PathSegment)

pub fn new() -> Path {
  list.new()
}

pub fn add_segment(path: Path, segment: String) -> Path {
  [Key(segment), ..path]
}

pub fn add_index(path: Path, index: Int) -> Path {
  [Index(index), ..path]
}

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
