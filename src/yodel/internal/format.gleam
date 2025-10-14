import gleam/list
import yodel/internal/input.{type Input}
import yodel/options.{type Format, type Options, Auto}

pub type FormatDetector {
  FormatDetector(name: String, detect: DetectFunction)
}

pub type DetectFunction =
  fn(Input) -> Format

/// if the user specified a format, use it
/// otherwise, try to detect the format from the input
/// if that fails, try to detect the format from the content
/// and if that fails, return `Auto` because we didn't figure it out
pub fn get_format(
  input: String,
  content: String,
  options: Options,
  formats: List(FormatDetector),
) -> Format {
  case options.get_format(options) {
    Auto ->
      case input |> input.detect_input |> detect_format(formats) {
        Auto -> content |> input.detect_input |> detect_format(formats)
        format -> format
      }
    format -> format
  }
}

fn detect_format(input: Input, formats: List(FormatDetector)) -> Format {
  list.fold(formats, options.Auto, fn(acc, format) {
    case acc {
      options.Auto -> format.detect(input)
      _ -> acc
    }
  })
}
