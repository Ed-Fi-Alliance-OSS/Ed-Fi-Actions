# bidi-scanner

Scans a repo for hidden unicode bidirectional characters as described in
CVE-2021-42694 and detailed at [Trojan Source](https://trojansource.codes/).

Bidirectional character detection is provided by a subset of the code from
[lirantal/anti-trojan-source](https://github.com/lirantal/anti-trojan-source/).

## Example usage

Minimal 'uses' expression to use this action:

``` yaml
- uses: ed-fi-alliance-oss/ed-fi-actions/.github/workflows/repository-scanner.yml
```

Note: adding the above to an existing workflow will call both the allowed action
and bidi scanner on the existing repo

```yml
name: Run Unicode Bidirectional Character Scan

on:
  push:
    branches:
      - '**'

jobs:
   scan-repo:
    uses: ed-fi-alliance-oss/ed-fi-actions/.github/workflows/repository-scanner.yml
```

Above is a complete action that once included in the /.github/workflows will
checkout and scan the current repo for allowed actions and bidirectional
characters

By default the bidi scanner tool includes a comprehensive set of files it
ignores (executable, image, audio and other binary files where scanning for
control characters wouldn't make sense) but there may be some cases where you
will want to add to this ignore list.

It is also possible to choose whether or not to recurse in subdirectories, and
to set a specific directory instead of using the current working directory as
the starting point.

All of these options are shown below:

``` yaml
bidi-scanner:
    uses: ed-fi-alliance-oss/ed-fi-actions/.github/workflows/repository-scanner.yml
    with:
      config-file-path: ./.github/workflows/bidi-scanner/config.json
      directory: ./github/workflows
      recursive: false
```

This will look in the calling repo's .github/workflows/bidi-scanner folder for a
config.json and pass that config file to the bidi scanner. A config file should
adhere this format, showing three worked examples:

```json
{
  "exclude": [
    ".git/**",
    ".github/scripts/*.sh",
    "**/*.ai",
    "excluded.js"
  ]
}
```

This excludes:

* Everything in `.git`
* All `.sh` files in `.github/scripts/`
* All `.ai` files anywhere
* The file `excluded.js` in the root
