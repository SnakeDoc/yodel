import glaml.{
  type Node, NodeBool, NodeFloat, NodeInt, NodeMap, NodeNil, NodeSeq, NodeStr,
}
import gleam/float
import gleam/int
import gleam/list
import gleam/string
import yodel/errors.{
  type ConfigError, InvalidStructure, InvalidSyntax, Location, ParseError,
  SyntaxError,
}
import yodel/internal/input.{type Input, Content, File}
import yodel/internal/path.{type Path}
import yodel/internal/properties.{type Properties}
import yodel/options.{type Format, Auto, Json, Yaml}

const known_extensions = [
  #("json", ["json", "jsn", "json5", "jsonc"]),
  #("yaml", ["yaml", "yml"]),
]

pub fn detect(input: Input) -> Format {
  case input {
    File(path) -> {
      detect_format_from_path(path)
    }
    Content(content) -> {
      detect_format_from_content(content)
    }
  }
}

fn detect_format_from_path(path: String) -> Format {
  let ext = input.get_extension_from_path(path)
  case
    list.find(known_extensions, fn(entry) {
      let #(_, exts) = entry
      list.contains(exts, ext)
    })
  {
    Ok(#("json", _)) -> Json
    Ok(#("yaml", _)) -> Yaml
    _ -> {
      Auto
    }
  }
}

fn detect_format_from_content(content: String) -> Format {
  let trimmed = string.trim(content)
  case detect_json(trimmed) {
    True -> options.Json
    False ->
      case detect_yaml(trimmed) {
        True -> options.Yaml
        False -> {
          Auto
        }
      }
  }
}

fn detect_json(content: String) -> Bool {
  { string.starts_with(content, "{") || string.starts_with(content, "[") }
  && { string.ends_with(content, "}") || string.ends_with(content, "]") }
  && string.contains(content, ":")
}

fn detect_yaml(content: String) -> Bool {
  {
    string.starts_with(content, "---")
    || string.contains(content, ":")
    || string.contains(content, "- ")
  }
  && { !string.starts_with(content, "{") && !string.starts_with(content, "[") }
}

pub fn parse(from string: String) -> Result(Properties, ConfigError) {
  case glaml.parse_string(string) {
    Ok(docs) ->
      docs
      |> list.map(glaml.document_root)
      |> list.fold(properties.new(), fn(acc, node) {
        parse_properties(node, path.new())
        |> properties.merge(acc)
      })
      |> Ok
    Error(err) -> Error(map_glaml_error(err))
  }
}

fn parse_properties(node: Node, path: Path) -> Properties {
  case node {
    NodeStr(value) -> properties.string(path, value)
    NodeInt(value) -> properties.int(path, value)
    NodeFloat(value) -> properties.float(path, value)
    NodeBool(value) -> properties.bool(path, value)
    NodeNil -> properties.null(path)

    NodeMap(pairs) -> parse_map(pairs, path)
    NodeSeq(items) -> parse_seq(items, path)
  }
}

fn extract_key(node: Node) -> String {
  case node {
    NodeStr(value) -> value
    NodeInt(value) -> int.to_string(value)
    NodeFloat(value) -> float.to_string(value)
    _ -> string.inspect(node)
  }
}

fn parse_map(pairs: List(#(Node, Node)), path: Path) -> Properties {
  list.fold(pairs, properties.new(), fn(acc, pair) {
    let key = extract_key(pair.0)
    let path = path |> path.add_segment(key)
    let props = parse_properties(pair.1, path)
    properties.merge(acc, props)
  })
}

fn parse_seq(items: List(Node), path: Path) -> Properties {
  list.index_fold(items, properties.new(), fn(acc, item, index) {
    let path = path |> path.add_index(index)
    let props = parse_properties(item, path)
    properties.merge(acc, props)
  })
}

fn map_glaml_error(error: glaml.YamlError) -> ConfigError {
  case error {
    glaml.UnexpectedParsingError ->
      ParseError(InvalidStructure("Unexpected parsing error"))
    glaml.ParsingError(msg, loc) -> {
      ParseError(
        InvalidSyntax(SyntaxError(
          format: "Json/Yaml",
          location: Location(loc.line, loc.column),
          message: msg,
        )),
      )
    }
  }
}
