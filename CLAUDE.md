# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

metanorma-cli is the command-line interface for the Metanorma document processing toolchain. It provides the `metanorma` executable for compiling Metanorma documents across multiple standard flavors (ISO, IEC, IETF, BIPM, ITU, OGC, IEEE, JIS, etc.). It wraps the `metanorma` gem and adds CLI-level features: document compilation, collection rendering, site generation, template management, and STS XML conversion via `mnconvert`.

## Build & Development Commands

```bash
# Install dependencies
bundle install

# Run full test suite
bundle exec rake

# Run a single spec file
bundle exec rspec spec/metanorma/cli/compiler_spec.rb

# Run a single example by line number
bundle exec rspec spec/metanorma/cli/compiler_spec.rb:42

# Lint
bundle exec rubocop

# Run the CLI locally
bundle exec exe/metanorma compile document.adoc -t iso

# IRB console with project loaded
bin/console
```

The project uses direnv + nix flake (see `flake.nix`) for environment setup. If using nix, run `direnv allow` to enter the dev shell.

Tests use RSpec with VCR cassettes (for HTTP stubbing), webmock, and rspec-command. SimpleCov is configured for coverage. Test state persistence is in `.rspec_status`.

## Architecture

### Entry Points

- **`exe/metanorma`** — Main CLI executable. Sets up encoding, handles SOCKS proxy support via `socksify`, then delegates to `Metanorma::Cli.start(ARGV)`.
- **`exe/metanorma-manifest`** — Standalone tool that converts YAML manifests into Metanorma XML/HTML collection indexes.
- **`lib/metanorma-cli.rb`** — Just requires `metanorma/cli`.
- **`lib/metanorma/cli.rb`** — Core module. `Cli.start` intercepts arguments: if no known command is found, it prepends `"compile"` (so bare `metanorma foo.adoc` works). Defines config paths (`~/.metanorma/config.yml` global, `.metanorma/config.yml` local).

### Command System (Thor)

- **`Command`** (`lib/metanorma/cli/command.rb`) — Main Thor command class. Defines all top-level commands: `compile`, `collection`, `convert`, `version`, `new`, `log_messages`, `list-extensions`, `list-doctypes`, `export-config`. Also has three subcommands: `template-repo`, `site`, `config`.
- **`ThorWithConfig`** (`lib/metanorma/cli/thor_with_config.rb`) — Base class for commands. Overrides `options` to merge CLI arguments with values from global and local config files (`~/.metanorma/config.yml` and `.metanorma/config.yml`). The merging is done by `Commands::Config.load_configs`.
- **`flavor.rb`** (module, not the one in `lib/metanorma/`) — Mixed into `Command`. Provides flavor discovery, extension listing, doctype tables, backend version lookups, and the `export-config` command.

### Key Classes

- **`Compiler`** (`compiler.rb`) — Wraps `Metanorma::Compile`. Validates input file existence, normalizes options (splits extract/extensions on commas), and calls the metanorma core compile pipeline.
- **`Collection`** (`collection.rb`) — Renders Metanorma collections from YAML or XML files. Delegates to `Metanorma::Collection.parse` for the actual processing.
- **`SiteGenerator`** (`site_generator.rb`) — Generates an HTML site from a collection of Metanorma documents. Reads a `metanorma.yml` manifest (via `SiteManifest` models), compiles individual `.adoc` files and collection files, builds a Relaton collection index, then converts to HTML using Liquid templates.
- **`Generator`** (`generator.rb`) — Creates new Metanorma documents from templates. Merges base templates (`templates/base/`) with type-specific templates downloaded from Git repos.
- **`GitTemplate`** (`git_template.rb`) — Manages Git-hosted document templates. Clones template repos to `~/.metanorma/templates/git/`.
- **`TemplateRepo`** (`template_repo.rb`) — Manages template repo registrations in the global config file.

### Subcommands

- **`Commands::Config`** (`commands/config.rb`) — `metanorma config get/set/unset`. Manages hierarchical YAML config (global + local). The `load_configs` class method merges global then local config into CLI options.
- **`Commands::Site`** (`commands/site.rb`) — `metanorma site generate`. Resolves manifest paths, stylesheet/template paths, and delegates to `SiteGenerator`.
- **`Commands::TemplateRepo`** (`commands/template_repo.rb`) — `metanorma template-repo add`. Registers template repos.

### Flavor System

- **`Metanorma::Flavor`** (`lib/metanorma/flavor.rb`) — Activates and loads all supported metanorma flavor gems (`metanorma-iso`, `metanorma-iec`, etc.). Activation happens at require time (line 77). Private gems (nist, ribose) fail silently.
- **`Metanorma::SiteManifest`** (`lib/metanorma/site_manifest.rb`) — Lutaml::Model serializable classes for parsing `metanorma.yml` site manifest files.

### Supporting Code

- **`UI`** (`ui.rb`) — Thin Thor-based wrapper for console output (say, info, error, table).
- **`Errors`** (`errors.rb`) — Custom error classes: `FileNotFoundError`, `FatalCompilationError`, `InvalidManifestFileError`, `DuplicateTemplateError`.
- **`stringify_all_keys.rb`** — Core extensions for deep key stringification/symbolization on Hash and Array. Note: `metanorma-utils` provides similar functionality via `Metanorma::Utils::Hash`.

## Configuration

Config files are YAML with a `cli` key at the top level. Values from config are merged into Thor options (global first, then local). Example:

```yaml
cli:
  agree_to_terms: true
  install_fonts: false
```

- Global: `~/.metanorma/config.yml`
- Local: `.metanorma/config.yml`

## Testing Notes

- Spec helper mocks `Mn2pdf.convert` and `MnConvert.convert` to copy files instead of running real conversions.
- `strip_guid` helper normalizes UUIDs in XML output for deterministic comparisons.
- Acceptance specs (`spec/acceptance/`) test the CLI end-to-end via `rspec-command`.
- VCR cassettes are in `spec/vcr_cassettes/` for HTTP request stubs.
