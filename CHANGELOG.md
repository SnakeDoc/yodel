<!-- markdownlint-disable MD024 -->

# Changelog

## v2.0.1

### Documentation

- Regenerated documentation using Gleam v1.13.0, which improves type display in generated HTML documentation

## v2.0.0

### New Features

- **Profile-based configuration** - Manage environment-specific configs with automatic merging
  - Load configuration directories with base + profile overrides
  - Activate profiles via `YODEL_PROFILES` environment variable or programmatically with `yodel.with_profiles()`
  - Example: `export YODEL_PROFILES=prod,debug` to layer multiple configs
- **Directory loading** - `load("./config")` now automatically discovers and merges profile configs
- **New configuration options**:
  - `with_profiles(profiles)` - Set active configuration profiles
  - `with_config_base_name(name)` - Customize base config filename (default: "config")
  - `with_profile_env_var(name)` - Customize profile environment variable name (default: "YODEL_PROFILES")

### Breaking Changes

- **Internal modules moved and restricted** - Modules previously at `yodel/parser`, `yodel/resolver`, etc.
  are now under `yodel/internal/` or marked `@internal`
  - These were never intended to be part of the public API
  - **If your code imported these directly, it will no longer compile**
  - The public API (via `import yodel`) remains fully backward compatible
  - **Action required**: Replace internal imports with the public `yodel` module API
  - If you have a use case requiring internal module access, please open an issue on GitHub

### Documentation

- Comprehensive documentation for profile-based configuration
- Enhanced README with common patterns and use cases

### Migration Guide

#### If you only used `import yodel`

**No changes needed!** The public API is fully backward compatible.

#### If you imported internal modules

Replace internal imports with the public API:

```gleam
// ❌ No longer works:
import yodel/parser
import yodel/resolver
import yodel/properties

// ✅ Use instead:
import yodel

let assert Ok(config) = yodel.load("config.yaml")
let assert Ok(value) = yodel.get_string(config, "key")
```

If you were using internal modules for functionality not available in the public API,
please [open an issue](https://github.com/SnakeDoc/yodel/issues) describing your use case.

#### Using the new profile features

```gleam
// Before (still works):
let assert Ok(config) = yodel.load("config.yaml")

// After (new capability):
let assert Ok(config) = yodel.load("./config")  // Loads base + active profiles
```

## v1.0.2

### Fixed

- Replace deprecated Gleam standard library calls

### Maintenance

- Update dependencies
- Improve Github Actions Workflows
- Prettier + Markdownlint npm configuration for repo hygiene
- RenovateBot config tweaks

## v1.0.1

### Maintenance

- Fix internal imports to resolve Gleam build tool warnings

## v1.0.0

Initial stable release
