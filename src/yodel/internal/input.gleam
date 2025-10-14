import gleam/list
import gleam/result
import gleam/string
import simplifile
import yodel/errors.{
  type ConfigError, FileError, FileNotFound, FilePermissionDenied, FileReadError,
  NotAFile,
}

pub type Input {
  File(path: String)
  Directory(path: String)
  Content(content: String)
}

pub fn get_content(input: String) -> Result(String, ConfigError) {
  case input |> detect_input {
    File(path) -> read_file(path)
    Content(content) -> Ok(content)
    Directory(dir) -> Error(FileError(NotAFile(dir)))
  }
}

pub fn detect_input(input: String) -> Input {
  let input = string.trim(input)
  case simplifile.is_file(input), simplifile.is_directory(input) {
    Ok(True), _ -> File(input)
    _, Ok(True) -> Directory(input)
    _, _ -> Content(input)
  }
}

pub fn get_extension_from_path(path: String) -> String {
  case
    path |> string.trim |> string.lowercase |> string.split(".") |> list.last
  {
    Ok(ext) -> string.lowercase(ext)
    _ -> ""
  }
}

pub fn read_file(from path: String) -> Result(String, ConfigError) {
  simplifile.read(path)
  |> result.map_error(fn(err) { map_simplifile_error(err) })
}

pub fn list_files(in directory: String) -> Result(List(String), ConfigError) {
  use files <- ls(directory)

  files
  |> list.map(fn(file) { directory <> "/" <> file })
  |> list.filter(fn(file_path) { simplifile.is_file(file_path) == Ok(True) })
  |> Ok
}

fn ls(
  path: String,
  handler: fn(List(String)) -> Result(List(String), ConfigError),
) -> Result(List(String), ConfigError) {
  simplifile.read_directory(path)
  |> result.map_error(fn(err) { map_simplifile_error(err) })
  |> result.try(handler)
}

fn map_simplifile_error(error: simplifile.FileError) -> ConfigError {
  FileError(case error {
    simplifile.Eacces -> FilePermissionDenied(simplifile.describe_error(error))
    simplifile.Enoent -> FileNotFound(simplifile.describe_error(error))
    _ -> FileReadError(simplifile.describe_error(error))
  })
}
