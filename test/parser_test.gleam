import gleam/float
import gleam/list
import startest.{describe, it}
import startest/expect
import yodel/errors.{type ConfigError}
import yodel/internal/parsers/toml
import yodel/internal/parsers/yaml
import yodel/internal/properties.{type Properties}
import yodel/value.{BoolValue, FloatValue, IntValue, StringValue}

pub type ParseFunction =
  fn(String) -> Result(Properties, ConfigError)

type TestCase {
  TestCase(
    format_name: String,
    parse: ParseFunction,
    string_input: String,
    int_input: String,
    float_input: String,
    bool_input: String,
    basic_input: String,
    array_input: String,
  )
}

pub fn parser_tests() {
  let test_cases = [
    TestCase(
      format_name: "toml",
      parse: toml.parse,
      string_input: "foo.bar = \"fooey\"",
      int_input: "foo.bar = 42",
      float_input: "foo.bar = 99.999",
      bool_input: "foo.bar = true",
      basic_input: "
      [foo]
      bar = \"fooey\"
      ",
      array_input: "
      [[foo]]
      bar = \"fooey\"

      [[foo]]
      baz = \"fooed\"
      ",
    ),
    TestCase(
      format_name: "yaml",
      parse: yaml.parse,
      string_input: "foo.bar: fooey",
      int_input: "foo.bar: 42",
      float_input: "foo.bar: 99.999",
      bool_input: "foo.bar: true",
      basic_input: "
      foo:
        bar: fooey
      ",
      array_input: "
      foo:
        - bar: fooey
        - baz: fooed
      ",
    ),
    TestCase(
      format_name: "json",
      parse: yaml.parse,
      string_input: "\"foo\": {\"bar\": \"fooey\"}",
      int_input: "\"foo\": {\"bar\": 42}",
      float_input: "\"foo\": {\"bar\": 99.999}",
      bool_input: "\"foo\": {\"bar\": true}",
      basic_input: "
      {
        \"foo\": {
          \"bar\": \"fooey\"
        }
      }
      ",
      array_input: "
      {
        \"foo\": [
          {
            \"bar\": \"fooey\"
          },
          {
            \"baz\": \"fooed\"
          }
        ]
      }
      ",
    ),
  ]

  describe(
    "parser",
    list.map(test_cases, fn(test_case) {
      let TestCase(
        format_name,
        parse,
        string_input,
        int_input,
        float_input,
        bool_input,
        basic_input,
        array_input,
      ) = test_case

      describe(format_name, [
        it("loads basic value", fn() {
          parse(basic_input)
          |> expect.to_be_ok
          |> properties.get("foo.bar")
          |> expect.to_be_ok
          |> expect.to_equal(StringValue("fooey"))
        }),
        it("loads array", fn() {
          parse(array_input)
          |> expect.to_be_ok
          |> properties.get("foo[1].baz")
          |> expect.to_be_ok
          |> expect.to_equal(StringValue("fooed"))
        }),
        it("returns a string", fn() {
          parse(string_input)
          |> expect.to_be_ok
          |> properties.get("foo.bar")
          |> expect.to_be_ok
          |> expect.to_equal(StringValue("fooey"))
        }),
        it("returns an int", fn() {
          parse(int_input)
          |> expect.to_be_ok
          |> properties.get("foo.bar")
          |> expect.to_be_ok
          |> expect.to_equal(IntValue(42))
        }),
        it("returns a float", fn() {
          case
            parse(float_input)
            |> expect.to_be_ok
            |> properties.get("foo.bar")
            |> expect.to_be_ok
          {
            FloatValue(f) -> f
            _ -> -1.0
          }
          |> float.to_precision(3)
          |> expect.to_equal(99.999)
        }),
        it("returns a bool", fn() {
          parse(bool_input)
          |> expect.to_be_ok
          |> properties.get("foo.bar")
          |> expect.to_be_ok
          |> expect.to_equal(BoolValue(True))
        }),
      ])
    }),
  )
}
