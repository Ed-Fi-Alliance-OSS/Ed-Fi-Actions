# bidi-scanner

Scans a repo for hidden unicode bidirectional characters as described in
CVE-2021-42694 and detailed at <https://trojansource.codes/>

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

An example of how to call the repository scanner with a config file is provided
below:

``` yaml
bidi-scanner:
    uses: ed-fi-alliance-oss/ed-fi-actions/.github/workflows/repository-scanner.yml
    with:
      config-file-path: ./.github/workflows/bidi-scanner/config.json
```

This will look in the calling repo's .github/workflows/bidi-scanner folder for a
config.json and pass that config file to the bidi scanner. We have provided a
sample configuration file in this folder.
