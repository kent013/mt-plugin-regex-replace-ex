# RegexReplaceEx Plugin for Movable Type

A Prettier-compatible regex replacement filter for Movable Type that provides two flexible syntax options.

## Overview

This plugin provides the `regex_replace_ex` filter as an alternative to the built-in `regex_replace` filter. It's designed to be compatible with Prettier's HTML parser, which has issues with comma-separated attribute values in MT tags.

## Installation

1. Copy the entire `RegexReplaceEx` directory to your MT installation's `plugins` directory
2. Restart MT to load the plugin
3. The `regex_replace_ex` filter will be available in your templates

## Usage

The plugin supports two syntax patterns:

### Pattern 1: Single Attribute Format

Use the `/pattern/replacement/flags` format in a single attribute:

```html
<mt:Var name="text" regex_replace_ex="/pattern/replacement/flags" />
```

Examples:

```html
<!-- Remove duplicate slashes -->
<mt:Var name="url" regex_replace_ex="/\/+/\//g" />

<!-- Remove trailing 'api/' -->
<mt:Var name="endpoint" regex_replace_ex="/api\/$//" />

<!-- Case-insensitive replacement -->
<mt:Var name="text" regex_replace_ex="/hello/Hi/gi" />
```

### Pattern 2: Separate Attributes Format

Use separate `pattern` and `replacement` attributes:

```html
<mt:Var name="text" regex_replace_ex pattern="/pattern/flags" replacement="replacement" />
```

Examples:

```html
<!-- Remove duplicate slashes -->
<mt:Var name="url" regex_replace_ex pattern="/\/+/g" replacement="/" />

<!-- Fix protocol slashes -->
<mt:Var name="url" regex_replace_ex pattern="/(https?:)\/+/" replacement="$1//" />

<!-- Remove trailing 'api/' -->
<mt:Var name="endpoint" regex_replace_ex pattern="/api\/$/g" replacement="" />
```

## Your Specific Use Case

Instead of the problematic original syntax:

```html
<mt:Var name="endpoint" regex_replace="/\/+/g","/" regex_replace="/(https?:)\/+/","$1//" regex_replace="/api\/$/","" />
```

You can use either:

**Option 1: Single Attribute Format**

```html
<mt:SetVarBlock name="endpoint">
  <mt:Var
    name="endpoint"
    regex_replace_ex="/\/+/\//g"
    regex_replace_ex="/(https?:)\/+/$1\///"
    regex_replace_ex="/api\/$//g" />
</mt:SetVarBlock>
```

**Option 2: Separate Attributes Format (Recommended)**

```html
<mt:SetVarBlock name="endpoint">
  <mt:Var
    name="endpoint"
    regex_replace_ex
    pattern="/\/+/g"
    replacement="/"
    regex_replace_ex
    pattern="/(https?:)\/+/"
    replacement="$1//"
    regex_replace_ex
    pattern="/api\/$/g"
    replacement="" />
</mt:SetVarBlock>
```

## Features

- **Prettier Compatible**: Both syntax options avoid comma-separated values in attributes
- **Full Regex Support**: Supports all standard regex flags (g, i, m)
- **Backreferences**: Supports backreferences ($1, $2, etc.) in replacements
- **Multiple Replacements**: Can chain multiple regex_replace_ex filters
- **Simple String Replacement**: If no regex delimiters are provided in pattern attribute, performs simple string replacement

## Regex Flags

- `g` - Global replacement (replace all occurrences)
- `i` - Case-insensitive matching
- `m` - Multi-line mode

## Migration from regex_replace

To migrate from the built-in `regex_replace` to `regex_replace_ex`:

1. Change `regex_replace` to `regex_replace_ex`
2. Choose your preferred syntax:
   - For single attribute: Convert `"pattern","replacement"` to `/pattern/replacement/flags`
   - For separate attributes: Split into `pattern="/pattern/flags" replacement="replacement"`

## Examples

```html
<!-- URL normalization -->
<mt:SetVar name="url" value="https://example.com//path//to///resource//" />
<mt:Var name="url" regex_replace_ex pattern="/\/+/g" replacement="/" />
<!-- Result: https://example.com/path/to/resource/ -->

<!-- Case conversion -->
<mt:SetVar name="text" value="Hello WORLD" />
<mt:Var name="text" regex_replace_ex="/world/universe/gi" />
<!-- Result: Hello universe -->

<!-- Backreference example -->
<mt:SetVar name="name" value="John Smith" />
<mt:Var name="name" regex_replace_ex pattern="/(\w+)\s+(\w+)/" replacement="$2, $1" />
<!-- Result: Smith, John -->
```

## Troubleshooting

- Ensure your regex patterns are properly escaped for HTML attributes
- Remember to include flags in the pattern when using separate attributes format
- Empty replacement values are supported (use `replacement=""` or just omit in single attribute format)

## License

This plugin is released under the same license as Movable Type.
