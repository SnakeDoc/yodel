import gleam/dict
import gleam/option.{None, Some}
import gleam/string
import startest.{describe, it}
import startest/expect
import test_helpers.{with_env}
import yodel

pub fn profiles_tests() {
  describe("profiles", [
    describe("directory loading", [
      describe("base config only", [
        it("loads base config from directory", fn() {
          yodel.load("./test/fixtures/profiles")
          |> expect.to_be_ok
          |> yodel.get_string("app.name")
          |> expect.to_be_ok
          |> expect.to_equal("myapp")
        }),
        it("loads all base config values", fn() {
          let ctx =
            yodel.load("./test/fixtures/profiles")
            |> expect.to_be_ok

          ctx
          |> yodel.get_string("app.version")
          |> expect.to_be_ok
          |> expect.to_equal("1.0.0")

          ctx
          |> yodel.get_string("database.host")
          |> expect.to_be_ok
          |> expect.to_equal("localhost")

          ctx
          |> yodel.get_int("database.port")
          |> expect.to_be_ok
          |> expect.to_equal(5432)
        }),
      ]),
      describe("base + single profile", [
        it("merges dev profile over base", fn() {
          let env = dict.from_list([#("YODEL_PROFILES", Some("dev"))])
          use <- with_env(env)

          let ctx =
            yodel.load("./test/fixtures/profiles")
            |> expect.to_be_ok

          // Base value unchanged
          ctx
          |> yodel.get_string("app.name")
          |> expect.to_be_ok
          |> expect.to_equal("myapp")

          // Profile overrides base
          ctx
          |> yodel.get_string("database.host")
          |> expect.to_be_ok
          |> expect.to_equal("dev.db.local")

          ctx
          |> yodel.get_int("database.port")
          |> expect.to_be_ok
          |> expect.to_equal(5433)

          // Profile adds new value
          ctx
          |> yodel.get_string("logging.level")
          |> expect.to_be_ok
          |> expect.to_equal("debug")
        }),
        it("merges prod profile over base", fn() {
          let env = dict.from_list([#("YODEL_PROFILES", Some("prod"))])
          use <- with_env(env)

          let ctx =
            yodel.load("./test/fixtures/profiles")
            |> expect.to_be_ok

          ctx
          |> yodel.get_string("database.host")
          |> expect.to_be_ok
          |> expect.to_equal("prod.db.example.com")

          ctx
          |> yodel.get_bool("security.strict")
          |> expect.to_be_ok
          |> expect.to_equal(True)
        }),
      ]),
      describe("base + multiple profiles", [
        it("applies profiles in order (last wins)", fn() {
          let env = dict.from_list([#("YODEL_PROFILES", Some("dev,staging"))])
          use <- with_env(env)

          let ctx =
            yodel.load("./test/fixtures/profiles")
            |> expect.to_be_ok

          // staging overrides dev's database.host
          ctx
          |> yodel.get_string("database.host")
          |> expect.to_be_ok
          |> expect.to_equal("staging.db.local")

          // staging overrides dev's logging.level
          ctx
          |> yodel.get_string("logging.level")
          |> expect.to_be_ok
          |> expect.to_equal("info")

          // dev's port persists (staging doesn't override)
          ctx
          |> yodel.get_int("database.port")
          |> expect.to_be_ok
          |> expect.to_equal(5433)
        }),
      ]),
      describe("mixed formats", [
        it("handles different formats in same directory", fn() {
          let env = dict.from_list([#("YODEL_PROFILES", Some("test"))])
          use <- with_env(env)

          let ctx =
            yodel.load("./test/fixtures/profiles")
            |> expect.to_be_ok

          // Should load base YAML and test TOML profile
          ctx
          |> yodel.get_string("database.host")
          |> expect.to_be_ok
          |> expect.to_equal("test.db.local")
        }),
      ]),
    ]),
    describe("profile activation", [
      describe("programmatic", [
        it("activates single profile programmatically", fn() {
          yodel.default_options()
          |> yodel.with_profiles(["dev"])
          |> yodel.load_with_options("./test/fixtures/profiles")
          |> expect.to_be_ok
          |> yodel.get_string("database.host")
          |> expect.to_be_ok
          |> expect.to_equal("dev.db.local")
        }),
        it("activates multiple profiles programmatically", fn() {
          yodel.default_options()
          |> yodel.with_profiles(["dev", "staging"])
          |> yodel.load_with_options("./test/fixtures/profiles")
          |> expect.to_be_ok
          |> yodel.get_string("database.host")
          |> expect.to_be_ok
          |> expect.to_equal("staging.db.local")
        }),
      ]),
      describe("environment variable", [
        it("activates profile via YODEL_PROFILES", fn() {
          let env = dict.from_list([#("YODEL_PROFILES", Some("prod"))])
          use <- with_env(env)

          yodel.load("./test/fixtures/profiles")
          |> expect.to_be_ok
          |> yodel.get_bool("security.strict")
          |> expect.to_be_ok
          |> expect.to_equal(True)
        }),
        it("parses comma-separated profiles", fn() {
          let env = dict.from_list([#("YODEL_PROFILES", Some("dev,staging"))])
          use <- with_env(env)

          yodel.load("./test/fixtures/profiles")
          |> expect.to_be_ok
          |> yodel.get_string("logging.level")
          |> expect.to_be_ok
          |> expect.to_equal("info")
        }),
        it("handles whitespace in profile list", fn() {
          let env =
            dict.from_list([#("YODEL_PROFILES", Some(" dev , staging "))])
          use <- with_env(env)

          yodel.load("./test/fixtures/profiles")
          |> expect.to_be_ok
          |> yodel.get_string("database.host")
          |> expect.to_be_ok
          |> expect.to_equal("staging.db.local")
        }),
      ]),
      describe("precedence", [
        it("env var overrides programmatic profiles", fn() {
          let env = dict.from_list([#("YODEL_PROFILES", Some("prod"))])
          use <- with_env(env)

          yodel.default_options()
          |> yodel.with_profiles(["dev"])
          |> yodel.load_with_options("./test/fixtures/profiles")
          |> expect.to_be_ok
          |> yodel.get_bool("security.strict")
          |> expect.to_be_ok
          |> expect.to_equal(True)
        }),
        it("empty env var disables programmatic profiles", fn() {
          let env = dict.from_list([#("YODEL_PROFILES", Some(""))])
          use <- with_env(env)

          yodel.default_options()
          |> yodel.with_profiles(["dev"])
          |> yodel.load_with_options("./test/fixtures/profiles")
          |> expect.to_be_ok
          |> yodel.get_string("database.host")
          |> expect.to_be_ok
          |> expect.to_equal("localhost")
        }),
        it("no env var uses programmatic profiles", fn() {
          let env = dict.from_list([#("YODEL_PROFILES", None)])
          use <- with_env(env)

          yodel.default_options()
          |> yodel.with_profiles(["dev"])
          |> yodel.load_with_options("./test/fixtures/profiles")
          |> expect.to_be_ok
          |> yodel.get_string("database.host")
          |> expect.to_be_ok
          |> expect.to_equal("dev.db.local")
        }),
      ]),
    ]),
    describe("merge behavior", [
      it("profile values override base values", fn() {
        let env = dict.from_list([#("YODEL_PROFILES", Some("dev"))])
        use <- with_env(env)

        let ctx =
          yodel.load("./test/fixtures/profiles")
          |> expect.to_be_ok

        ctx
        |> yodel.get_bool("feature_flags.new_ui")
        |> expect.to_be_ok
        |> expect.to_equal(True)
      }),
      it("base values persist when not overridden", fn() {
        let env = dict.from_list([#("YODEL_PROFILES", Some("dev"))])
        use <- with_env(env)

        let ctx =
          yodel.load("./test/fixtures/profiles")
          |> expect.to_be_ok

        ctx
        |> yodel.get_bool("feature_flags.api_v2")
        |> expect.to_be_ok
        |> expect.to_equal(False)
      }),
      it("profile adds new keys", fn() {
        let env = dict.from_list([#("YODEL_PROFILES", Some("dev"))])
        use <- with_env(env)

        yodel.load("./test/fixtures/profiles")
        |> expect.to_be_ok
        |> yodel.get_string("logging.level")
        |> expect.to_be_ok
        |> expect.to_equal("debug")
      }),
      it("later profiles override earlier ones", fn() {
        let env =
          dict.from_list([#("YODEL_PROFILES", Some("dev,staging,prod"))])
        use <- with_env(env)

        yodel.load("./test/fixtures/profiles")
        |> expect.to_be_ok
        |> yodel.get_string("database.host")
        |> expect.to_be_ok
        |> expect.to_equal("prod.db.example.com")
      }),
    ]),
    describe("edge cases", [
      it("handles non-existent directory", fn() {
        yodel.load("./test/fixtures/nonexistent")
        |> expect.to_be_error
        Nil
      }),
      it("handles directory with no matching configs", fn() {
        // Create empty directory test or use existing directory without configs
        yodel.load("./test/fixtures")
        |> expect.to_be_error
        Nil
      }),
      it("handles non-existent profile gracefully", fn() {
        let env = dict.from_list([#("YODEL_PROFILES", Some("nonexistent"))])
        use <- with_env(env)

        // Should load base config only
        yodel.load("./test/fixtures/profiles")
        |> expect.to_be_ok
        |> yodel.get_string("app.name")
        |> expect.to_be_ok
        |> expect.to_equal("myapp")
      }),
      it("resolves placeholders across merged configs", fn() {
        let env =
          dict.from_list([
            #("YODEL_PROFILES", Some("prod")),
            #("DB_USER", Some("custom_dev_user")),
          ])
        use <- with_env(env)

        // Would need fixture with placeholders in profile
        yodel.load("./test/fixtures/profiles")
        |> expect.to_be_ok
        |> yodel.get_string("database.user")
        |> expect.to_be_ok
        |> expect.to_equal("custom_dev_user")
      }),
      it("errors on duplicate base configs", fn() {
        let env = dict.from_list([#("YODEL_PROFILES", Some("dev"))])
        use <- with_env(env)

        yodel.load("./test/fixtures/profiles/duplicate-bases")
        |> expect.to_be_error
        |> string.inspect
        |> expect.string_to_contain("Multiple base config files found")
      }),
      it("errors on duplicate profile configs", fn() {
        let env = dict.from_list([#("YODEL_PROFILES", Some("dev"))])
        use <- with_env(env)

        yodel.load("./test/fixtures/profiles/duplicate-profiles")
        |> expect.to_be_error
        |> string.inspect
        |> expect.string_to_contain(
          "Multiple config files found for profile 'dev'",
        )
      }),
    ]),
  ])
}
