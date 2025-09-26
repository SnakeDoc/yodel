# Yodel

### 🎶 Yo-de-lay-ee-configs! <!-- markdownlint-disable-line MD001 MD026 -->

Yodel is a type-safe configuration loader for Gleam that supports JSON, YAML,
and TOML configs with automatic format detection, environment variable
resolution, and an intuitive dot-notation API for accessing your config values. 🚀

[![Package Version](https://img.shields.io/hexpm/v/yodel)](https://hex.pm/packages/yodel)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/yodel/)

```sh
gleam add yodel
```

```gleam
import yodel

pub fn main() {
  let assert Ok(ctx) = yodel.load("config.yaml")
  let value = yodel.get_string(ctx, "some.key")
}
```

Further documentation can be found at <https://hexdocs.pm/yodel>.

## Development

```sh
gleam test  # Run the tests
```
