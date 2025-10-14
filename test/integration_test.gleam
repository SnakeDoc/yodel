import gleam/dict
import gleam/float
import gleam/list
import gleam/option.{Some}
import startest.{describe, it}
import startest/expect
import test_helpers.{with_env}
import yodel.{type Format}
import yodel/errors.{ResolverError, UnresolvedPlaceholder}

type TestCase {
  TestCase(
    format_name: String,
    format: Format,
    extension: String,
    string_input: String,
    int_input: String,
    float_input: String,
    bool_input: String,
    basic_input: String,
    array_input: String,
    basic_placeholder_with_default: String,
    basic_placeholder_without_default: String,
    nested_placeholder_with_default: String,
    nested_placeholder_without_default: String,
    multiple_placeholders_without_default: String,
    multiple_placeholders_with_default: String,
    missing_placeholder: String,
  )
}

pub fn integration_tests() {
  let test_cases = [
    TestCase(
      format_name: "toml",
      format: yodel.format_toml,
      extension: "toml",
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
      basic_placeholder_with_default: "foo = \"${BAR:fooey}\"",
      basic_placeholder_without_default: "foo = \"${BAR}\"",
      nested_placeholder_with_default: "foo = \"${BAR:${BAZ:fooey}}\"",
      nested_placeholder_without_default: "foo = \"${BAR:${BAZ}}\"",
      multiple_placeholders_without_default: "foo = \"${BAR}-${BAZ}\"",
      multiple_placeholders_with_default: "foo = \"${BAR:fooey}-${BAZ:dooey}\"",
      missing_placeholder: "foo = \"${MISSING}\"",
    ),
    TestCase(
      format_name: "yaml",
      format: yodel.format_yaml,
      extension: "yaml",
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
      basic_placeholder_with_default: "foo: ${BAR:fooey}",
      basic_placeholder_without_default: "foo: ${BAR}",
      nested_placeholder_with_default: "foo: ${BAR:${BAZ:fooey}}",
      nested_placeholder_without_default: "foo: ${BAR:${BAZ}}",
      multiple_placeholders_without_default: "foo: ${BAR}-${BAZ}",
      multiple_placeholders_with_default: "foo: ${BAR:fooey}-${BAZ:dooey}",
      missing_placeholder: "foo: ${MISSING}",
    ),
    TestCase(
      format_name: "json",
      format: yodel.format_json,
      extension: "json",
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
      basic_placeholder_with_default: "\"foo\": \"${BAR:fooey}\"",
      basic_placeholder_without_default: "\"foo\": \"${BAR}\"",
      nested_placeholder_with_default: "\"foo\": \"${BAR:${BAZ:fooey}}\"",
      nested_placeholder_without_default: "\"foo\": \"${BAR:${BAZ}}\"",
      multiple_placeholders_without_default: "\"foo\": \"${BAR}-${BAZ}\"",
      multiple_placeholders_with_default: "\"foo\": \"${BAR:fooey}-${BAZ:dooey}\"",
      missing_placeholder: "\"foo\": \"${MISSING}\"",
    ),
    TestCase(
      format_name: "auto (toml)",
      format: yodel.format_auto,
      extension: "toml",
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
      basic_placeholder_with_default: "foo = \"${BAR:fooey}\"",
      basic_placeholder_without_default: "foo = \"${BAR}\"",
      nested_placeholder_with_default: "foo = \"${BAR:${BAZ:fooey}}\"",
      nested_placeholder_without_default: "foo = \"${BAR:${BAZ}}\"",
      multiple_placeholders_without_default: "foo = \"${BAR}-${BAZ}\"",
      multiple_placeholders_with_default: "foo = \"${BAR:fooey}-${BAZ:dooey}\"",
      missing_placeholder: "foo = \"${MISSING}\"",
    ),
    TestCase(
      format_name: "auto (yaml)",
      format: yodel.format_auto,
      extension: "yaml",
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
      basic_placeholder_with_default: "foo: ${BAR:fooey}",
      basic_placeholder_without_default: "foo: ${BAR}",
      nested_placeholder_with_default: "foo: ${BAR:${BAZ:fooey}}",
      nested_placeholder_without_default: "foo: ${BAR:${BAZ}}",
      multiple_placeholders_without_default: "foo: ${BAR}-${BAZ}",
      multiple_placeholders_with_default: "foo: ${BAR:fooey}-${BAZ:dooey}",
      missing_placeholder: "foo: ${MISSING}",
    ),
    TestCase(
      format_name: "auto (json)",
      format: yodel.format_auto,
      extension: "json",
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
      basic_placeholder_with_default: "\"foo\": \"${BAR:fooey}\"",
      basic_placeholder_without_default: "\"foo\": \"${BAR}\"",
      nested_placeholder_with_default: "\"foo\": \"${BAR:${BAZ:fooey}}\"",
      nested_placeholder_without_default: "\"foo\": \"${BAR:${BAZ}}\"",
      multiple_placeholders_without_default: "\"foo\": \"${BAR}-${BAZ}\"",
      multiple_placeholders_with_default: "\"foo\": \"${BAR:fooey}-${BAZ:dooey}\"",
      missing_placeholder: "\"foo\": \"${MISSING}\"",
    ),
  ]

  describe(
    "integration",
    list.map(test_cases, fn(test_case) {
      let TestCase(
        format_name,
        format,
        extension,
        string_input,
        int_input,
        float_input,
        bool_input,
        basic_input,
        array_input,
        basic_placeholder_with_default,
        basic_placeholder_without_default,
        nested_placeholder_with_default,
        nested_placeholder_without_default,
        multiple_placeholders_without_default,
        multiple_placeholders_with_default,
        missing_placeholder,
      ) = test_case

      describe(format_name, [
        describe("files", [
          it("loads simple file", fn() {
            yodel.default_options()
            |> yodel.with_format(format)
            |> yodel.load_with_options("./test/fixtures/simple." <> extension)
            |> expect.to_be_ok
            Nil
          }),
          it("loads complex file", fn() {
            yodel.default_options()
            |> yodel.with_format(format)
            |> yodel.load_with_options("./test/fixtures/complex." <> extension)
            |> expect.to_be_ok
            Nil
          }),
          it("does not load fake file", fn() {
            yodel.default_options()
            |> yodel.with_format(format)
            |> yodel.load_with_options("fake." <> extension)
            |> expect.to_be_error
            Nil
          }),
          it("loads file with no extension", fn() {
            yodel.default_options()
            |> yodel.with_format(format)
            |> yodel.load_with_options("./test/fixtures/no-ext-" <> extension)
            |> expect.to_be_ok
            Nil
          }),
        ]),
        describe("values", [
          it("loads basic value", fn() {
            yodel.default_options()
            |> yodel.with_format(format)
            |> yodel.load_with_options(basic_input)
            |> expect.to_be_ok
            |> yodel.get_string("foo.bar")
            |> expect.to_be_ok
            |> expect.to_equal("fooey")
          }),
          it("loads array", fn() {
            yodel.default_options()
            |> yodel.with_format(format)
            |> yodel.load_with_options(array_input)
            |> expect.to_be_ok
            |> yodel.get_string("foo[1].baz")
            |> expect.to_be_ok
            |> expect.to_equal("fooed")
          }),
          it("returns a string", fn() {
            yodel.default_options()
            |> yodel.with_format(format)
            |> yodel.load_with_options(string_input)
            |> expect.to_be_ok
            |> yodel.get_string("foo.bar")
            |> expect.to_be_ok
            |> expect.to_equal("fooey")
          }),
          it("returns an int", fn() {
            yodel.default_options()
            |> yodel.with_format(format)
            |> yodel.load_with_options(int_input)
            |> expect.to_be_ok
            |> yodel.get_int("foo.bar")
            |> expect.to_be_ok
            |> expect.to_equal(42)
          }),
          it("returns a float", fn() {
            yodel.default_options()
            |> yodel.with_format(format)
            |> yodel.load_with_options(float_input)
            |> expect.to_be_ok
            |> yodel.get_float("foo.bar")
            |> expect.to_be_ok
            |> float.to_precision(3)
            |> expect.to_equal(99.999)
          }),
          it("returns a bool", fn() {
            yodel.default_options()
            |> yodel.with_format(format)
            |> yodel.load_with_options(bool_input)
            |> expect.to_be_ok
            |> yodel.get_bool("foo.bar")
            |> expect.to_be_ok
            |> expect.to_equal(True)
          }),
        ]),
        describe("resolution", [
          describe("basic resolution", [
            it("resolves simple placeholder default", fn() {
              yodel.default_options()
              |> yodel.with_format(format)
              |> yodel.load_with_options(basic_placeholder_with_default)
              |> expect.to_be_ok
              |> yodel.get_string("foo")
              |> expect.to_be_ok
              |> expect.to_equal("fooey")
            }),
            it("resolves simple placeholder", fn() {
              let env = dict.from_list([#("BAR", Some("fooey"))])
              use <- with_env(env)
              yodel.default_options()
              |> yodel.with_format(format)
              |> yodel.load_with_options(basic_placeholder_without_default)
              |> expect.to_be_ok
              |> yodel.get_string("foo")
              |> expect.to_be_ok
              |> expect.to_equal("fooey")
            }),
            it("ignores default value when placeholder resolves", fn() {
              let env = dict.from_list([#("BAR", Some("foobar"))])
              use <- with_env(env)
              yodel.default_options()
              |> yodel.with_format(format)
              |> yodel.load_with_options(basic_placeholder_with_default)
              |> expect.to_be_ok
              |> yodel.get_string("foo")
              |> expect.to_be_ok
              |> expect.to_equal("foobar")
            }),
          ]),
          describe("nested placeholders", [
            it("resolves nested placeholders", fn() {
              let env = dict.from_list([#("BAZ", Some("fooey"))])
              use <- with_env(env)
              yodel.default_options()
              |> yodel.with_format(format)
              |> yodel.load_with_options(nested_placeholder_without_default)
              |> expect.to_be_ok
              |> yodel.get_string("foo")
              |> expect.to_be_ok
              |> expect.to_equal("fooey")
            }),
            it("resolves nested placeholder defaults", fn() {
              yodel.default_options()
              |> yodel.with_format(format)
              |> yodel.load_with_options(nested_placeholder_with_default)
              |> expect.to_be_ok
              |> yodel.get_string("foo")
              |> expect.to_be_ok
              |> expect.to_equal("fooey")
            }),
          ]),
          describe("multiple placeholders", [
            it("resolves multiple placeholders", fn() {
              let env =
                dict.from_list([
                  #("BAR", Some("fooey")),
                  #("BAZ", Some("dooey")),
                ])
              use <- with_env(env)
              yodel.default_options()
              |> yodel.with_format(format)
              |> yodel.load_with_options(multiple_placeholders_without_default)
              |> expect.to_be_ok
              |> yodel.get_string("foo")
              |> expect.to_be_ok
              |> expect.to_equal("fooey-dooey")
            }),
            it("resolved multiple placeholder defaults", fn() {
              yodel.default_options()
              |> yodel.with_format(format)
              |> yodel.load_with_options(multiple_placeholders_with_default)
              |> expect.to_be_ok
              |> yodel.get_string("foo")
              |> expect.to_be_ok
              |> expect.to_equal("fooey-dooey")
            }),
          ]),
          describe("resolution mode", [
            it("fails in strict mode with missing env var", fn() {
              yodel.default_options()
              |> yodel.with_format(format)
              |> yodel.with_resolve_mode(yodel.resolve_strict)
              |> yodel.load_with_options(missing_placeholder)
              |> expect.to_be_error
              |> expect.to_equal(
                ResolverError(UnresolvedPlaceholder("MISSING", "${MISSING}")),
              )
            }),
            it("preserves placeholder in lenient mode", fn() {
              yodel.default_options()
              |> yodel.with_format(format)
              |> yodel.with_resolve_mode(yodel.resolve_lenient)
              |> yodel.load_with_options(missing_placeholder)
              |> expect.to_be_ok
              |> yodel.get_string("foo")
              |> expect.to_be_ok
              |> expect.to_equal("${MISSING}")
            }),
          ]),
        ]),
      ])
    }),
  )
}
