import gleam/list
import yodel/internal/input.{type Input}
import yodel/options.{type Format, type Options, Auto}

/// A format detector that can identify a configuration format from input.
pub type FormatDetector {
  FormatDetector(name: String, detect: DetectFunction)
}

pub type DetectFunction =
  fn(Input) -> Format

/// Determine the configuration format to use.
///
/// Resolution order:
/// 1. User-specified format (if provided in options)
/// 2. Format detected from input (file extension)
/// 3. Format detected from content (parsing patterns)
/// 4. Auto (unable to determine format)
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

/// Attempts to detect format using the provided detector functions.
///
/// Stops at the first successful detection, otherwise returns Auto.
fn detect_format(input: Input, formats: List(FormatDetector)) -> Format {
  list.fold(formats, options.Auto, fn(acc, format) {
    case acc {
      options.Auto -> format.detect(input)
      _ -> acc
    }
  })
}
