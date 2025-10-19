# Yodel

### 🎶 Yo-de-lay-ee-configs! <!-- markdownlint-disable-line MD001 MD026 -->

A type-safe configuration loader for Gleam that supports JSON, YAML, and TOML with automatic format detection,
environment variable resolution, and profile-based configuration. 🚀

[![Package Version](https://img.shields.io/hexpm/v/yodel)](https://hex.pm/packages/yodel)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/yodel/)

```sh
gleam add yodel
```

```gleam
import yodel

pub fn main() {
  let assert Ok(config) = yodel.load("config.yaml")
  let assert Ok(db_host) = yodel.get_string(config, "database.host")
  let port = yodel.get_int_or(config, "database.port", 5432)
}
```

## Features

- **Multiple Formats** - Load JSON, YAML, or TOML with automatic format detection
- **Profile-Based Configuration** - Manage dev, staging, and production configs with separate files
- **Environment Variables** - Inject secrets and environment-specific values with `${VAR:default}` placeholders
- **Type-Safe** - Compile-time safety with helpful error messages
- **Dot Notation** - Access nested values with `"database.host"`

## Installation

```sh
gleam add yodel
```

## Quick Start

Yodel automatically detects the format from file extension or content:

```gleam
import yodel

pub fn main() {
  let assert Ok(config) = yodel.load("config.yaml")

  // Type-safe value access
  let assert Ok(host) = yodel.get_string(config, "database.host")
  let assert Ok(port) = yodel.get_int(config, "database.port")

  // Provide defaults for optional values
  let cache_ttl = yodel.get_int_or(config, "cache.ttl", 3600)
}
```

## Profile-Based Configuration

Manage environment-specific configurations with profiles that automatically merge over your base configuration.

**Directory structure:**

```text
config/
├── config.yaml              # Base configuration (all environments)
├── config-dev.yaml          # Development overrides
├── config-staging.yaml      # Staging overrides
└── config-prod.yaml         # Production overrides
```

**config.yaml** (base):

```yaml
app:
  name: myapp
  version: 1.0.0
database:
  host: localhost
  port: 5432
  pool_size: 10
```

**config-prod.yaml** (production overrides):

```yaml
database:
  host: prod.db.example.com
  pool_size: 50
  ssl: true
logging:
  level: warn
```

**Activate profiles via environment variable:**

```sh
export YODEL_PROFILES=prod
```

```gleam
import yodel

pub fn main() {
  // Automatically loads config.yaml + config-prod.yaml
  let assert Ok(config) = yodel.load("./config")

  // Values from config-prod.yaml override config.yaml
  let assert Ok(host) = yodel.get_string(config, "database.host")
  // → "prod.db.example.com"
}
```

> **Note:** Profile configs can use any supported format - mix and match YAML, TOML, and JSON as needed.

**Or set profiles programmatically:**

```gleam
import yodel

pub fn main() {
  let assert Ok(config) =
    yodel.default_options()
    |> yodel.with_profiles(["dev", "local"])
    |> yodel.load_with_options("./config")

  // Loads: config.yaml → config-dev.yaml → config-local.yaml
  // Later profiles override earlier ones
}
```

The `YODEL_PROFILES` environment variable takes precedence over programmatically set profiles,
allowing you to change environments at deployment time without code changes.

## Environment Variable Resolution

Inject environment-specific values and secrets using placeholders:

```json
{
  "database": {
    "host": "${DATABASE_HOST:localhost}",
    "password": "${DB_PASSWORD}"
  },
  "api": {
    "key": "${API_KEY}",
    "endpoint": "${API_ENDPOINT:https://api.example.com}"
  }
}
```

```sh
export DATABASE_HOST=prod.db.example.com
export DB_PASSWORD=super-secret
export API_KEY=abc123
```

```gleam
import yodel

pub fn main() {
  let assert Ok(config) = yodel.load("config.json")

  let assert Ok(host) = yodel.get_string(config, "database.host")
  // → "prod.db.example.com" (from environment variable)

  let assert Ok(password) = yodel.get_string(config, "database.password")
  // → "super-secret" (from environment variable)

  let assert Ok(endpoint) = yodel.get_string(config, "api.endpoint")
  // → "https://api.example.com" (default value used)
}
```

**Placeholder syntax:**

- `${VAR_NAME}` - Simple substitution
- `${VAR_NAME:default_value}` - With default value
- `${VAR1:${VAR2:fallback}}` - Nested placeholders

## Advanced Options

```gleam
import yodel

pub fn main() {
  let assert Ok(config) =
    yodel.default_options()
    |> yodel.as_toml()                    // Force TOML format
    |> yodel.with_resolve_strict()        // Fail on unresolved placeholders
    |> yodel.with_profiles(["prod"])      // Set active profiles
    |> yodel.with_config_base_name("app") // Use app.toml instead of config.toml
    |> yodel.load_with_options("./config")
}
```

## API Overview

Yodel provides a simple, consistent API:

**Loading:** `load()` and `load_with_options()` for basic and advanced usage

**Type-safe getters:** `get_string()`, `get_int()`, `get_float()`, `get_bool()`

**Defaults:** `get_*_or()` variants return a default if key is missing

**Parsing:** `parse_*()` functions convert between types

**Configuration:** Builder-style options with `default_options()`, `as_*()`, `with_*()` functions

For the complete API reference, see <https://hexdocs.pm/yodel>.

## Common Patterns

### Environment-Based Profiles

```text
config/
├── config.yaml           # Shared configuration
├── config-dev.yaml       # Local development
├── config-test.json      # Test environment
├── config-staging.yaml   # Staging environment
└── config-prod.toml      # Production environment
```

Activate the appropriate profile for each environment:

```sh
# Development
export YODEL_PROFILES=dev
gleam run

# Staging
export YODEL_PROFILES=staging
gleam run

# Production
export YODEL_PROFILES=prod
gleam run
```

### Feature-Based Profiles

Profiles aren't just for environments - use them to layer any configuration changes:

```text
config/
├── config.yaml              # Base configuration
├── config-debug.yaml        # Enable debug logging
├── config-metrics.yaml      # Enable metrics collection
└── config-experimental.yaml # Enable experimental features
```

```sh
# Enable debug logging and metrics in production
export YODEL_PROFILES=prod,debug,metrics
gleam run
```

```gleam
// Or activate features programmatically
let assert Ok(config) =
  yodel.default_options()
  |> yodel.with_profiles(["debug", "metrics"])
  |> yodel.load_with_options("./config")
```

### Database Configuration

```toml
# config.toml
[database]
host = "${DB_HOST:localhost}"
port = "${DB_PORT:5432}"
name = "${DB_NAME:myapp}"
user = "${DB_USER:postgres}"
password = "${DB_PASSWORD}"
pool_size = "${DB_POOL_SIZE:10}"
```

```gleam
import yodel

pub fn get_database_config() {
  let assert Ok(config) = yodel.load("config.toml")

  DatabaseConfig(
    host: yodel.get_string_or(config, "database.host", "localhost"),
    port: yodel.get_int_or(config, "database.port", 5432),
    name: yodel.get_string_or(config, "database.name", "myapp"),
    user: yodel.get_string_or(config, "database.user", "postgres"),
    password: yodel.get_string(config, "database.password"),
    pool_size: yodel.get_int_or(config, "database.pool_size", 10),
  )
}
```

## Development

```sh
gleam test  # Run the tests
```

## License

This project is licensed under the Apache License 2.0.
