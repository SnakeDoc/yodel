import gleam/list
import startest.{describe, it}
import startest/expect
import yodel.{type Format}
import yodel/internal/input.{type Input, Content, File}
import yodel/internal/parsers/toml
import yodel/internal/parsers/yaml

type TestCase {
  TestCase(
    format_name: String,
    format: Format,
    extensions: List(String),
    content: String,
    detect: fn(Input) -> Format,
  )
}

pub fn parser_tests() {
  let test_cases = [
    TestCase(
      format_name: "json",
      format: yodel.json_format,
      extensions: ["json", "jsn", "json5", "jsonc"],
      content: "
      {
        \"foo\": {
          \"bar\": \"fooey\"
        }
      }
      ",
      detect: yaml.detect,
    ),
    TestCase(
      format_name: "yaml",
      format: yodel.yaml_format,
      extensions: ["yaml", "yml"],
      content: "
      foo:
        bar: fooey
      ",
      detect: yaml.detect,
    ),
    TestCase(
      format_name: "toml",
      format: yodel.toml_format,
      extensions: ["toml", "tml"],
      content: "
      [foo]
      bar = \"fooey\"
      ",
      detect: toml.detect,
    ),
  ]

  describe(
    "format",
    list.map(test_cases, fn(test_case) {
      let TestCase(format_name, format, extensions, content, detect) = test_case
      describe(format_name, [
        describe(
          "extension",
          list.map(extensions, fn(extension) {
            it("detects from ." <> extension, fn() {
              detect(File("foo." <> extension)) |> expect.to_equal(format)
            })
          }),
        ),
        describe("content", [
          it("detects from content", fn() {
            detect(Content(content)) |> expect.to_equal(format)
          }),
        ]),
      ])
    }),
  )
}
