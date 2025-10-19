import gleam/dict
import gleam/option.{Some}
import startest.{describe, it}
import startest/expect
import test_helpers.{with_env}
import yodel
import yodel/errors.{ResolverError, UnresolvedPlaceholder}
import yodel/internal/resolver

pub fn resolver_tests() {
  describe("resolver", [
    describe("basic resolution", [
      it("resolves simple placeholder default", fn() {
        "${BAR:fooey}"
        |> resolver.resolve_placeholders(yodel.default_options())
        |> expect.to_be_ok
        |> expect.to_equal("fooey")
      }),
      it("resolves simple placeholder", fn() {
        let env = dict.from_list([#("BAR", Some("fooey"))])
        use <- with_env(env)
        "${BAR}"
        |> resolver.resolve_placeholders(yodel.default_options())
        |> expect.to_be_ok
        |> expect.to_equal("fooey")
      }),
      it("ignores default value when placeholder resolves", fn() {
        let env = dict.from_list([#("BAR", Some("fooey"))])
        use <- with_env(env)
        "${BAR:fooed}"
        |> resolver.resolve_placeholders(yodel.default_options())
        |> expect.to_be_ok
        |> expect.to_equal("fooey")
      }),
    ]),
    describe("nested placeholders", [
      it("resolves nested placeholders", fn() {
        let env = dict.from_list([#("BAZ", Some("fooey"))])
        use <- with_env(env)
        "${BAR:${BAZ}}"
        |> resolver.resolve_placeholders(yodel.default_options())
        |> expect.to_be_ok
        |> expect.to_equal("fooey")
      }),
      it("resolves nested placeholder defaults", fn() {
        "${BAR:${BAZ:fooey}}"
        |> resolver.resolve_placeholders(yodel.default_options())
        |> expect.to_be_ok
        |> expect.to_equal("fooey")
      }),
    ]),
    describe("multiple placeholders", [
      it("resolves multiple placeholders", fn() {
        let env =
          dict.from_list([#("BAR", Some("fooey")), #("BAZ", Some("dooey"))])
        use <- with_env(env)
        "${BAR}-${BAZ}"
        |> resolver.resolve_placeholders(yodel.default_options())
        |> expect.to_be_ok
        |> expect.to_equal("fooey-dooey")
      }),
      it("resolved multiple placeholder defaults", fn() {
        "${BAR:fooey}-${BAZ:dooey}"
        |> resolver.resolve_placeholders(yodel.default_options())
        |> expect.to_be_ok
        |> expect.to_equal("fooey-dooey")
      }),
    ]),
    describe("resolution mode", [
      it("fails in strict mode with missing env var", fn() {
        let options =
          yodel.default_options()
          |> yodel.with_resolve_mode(yodel.resolve_strict)
        "${MISSING}"
        |> resolver.resolve_placeholders(options)
        |> expect.to_be_error
        |> expect.to_equal(
          ResolverError(UnresolvedPlaceholder("MISSING", "${MISSING}")),
        )
      }),
      it("preserves placeholder in lenient mode", fn() {
        let options =
          yodel.default_options()
          |> yodel.with_resolve_mode(yodel.resolve_lenient)
        "${MISSING}"
        |> resolver.resolve_placeholders(options)
        |> expect.to_be_ok
        |> expect.to_equal("${MISSING}")
      }),
    ]),
    it("resolves placeholder with URL default containing colon", fn() {
      yodel.default_options()
      |> yodel.load_with_options("api: ${API_ENDPOINT:https://api.example.com}")
      |> expect.to_be_ok
      |> yodel.get_string("api")
      |> expect.to_be_ok
      |> expect.to_equal("https://api.example.com")
    }),
  ])
}
