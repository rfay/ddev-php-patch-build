[![tests](https://github.com/rfay/ddev-php-patch-build/actions/workflows/tests.yml/badge.svg)](https://github.com/ddev/ddev-php-patch-build/actions/workflows/tests.yml) ![project is maintained](https://img.shields.io/maintenance/yes/2024.svg)

# ddev-php-patch-build <!-- omit in toc -->

* [What is ddev-php-patch-build?](#what-is-ddev-php-patch-build)
* [Installation](#installation)
* [Components of the add-on](#components-of-the-add-on)

## What is ddev-php-patch-build?

DDEV users periodically ask if they can use a specific PHP patch version with their projects, either to test/compare for a particular bug or to match a production version exactly.

This add-on tries to address that need, although there are a number of caveats:

1. The build done using this process does not match the build done using the official DDEV php packages (which actually come from deb.sury.org)
2. The resultant PHP binaries built here do not have the exact same extensions as the official DDEV PHP binaries.
3. Building the binaries happens in the build phase of `ddev start`, and it takes a long time on the first `ddev start` or whenever you change versions. My tests on Gitpod, with a great internet connection, took about 8-9 minutes. It can be really annoying, and a better way to build would be an improvement.
4. Your mileage may vary.

* The [static-php-ci](https://github.com/crazywhalecc/static-php-cli) repository provides a relatively easy way to build static PHP binaries (the CLI and `php-fpm`) which can be used to replace the ones installed in `ddev-webserver`.
* The provided Dockerfile.php-patch-build does the building.
* The provided `config.php-patch-build` provides post-start hooks that install the built binaries.

## Installation

1. `ddev get rfay/ddev-php-patch-build`


## Components of the add-on

* `config.php-yaml`
* `Dockerfile.php-patch-build`
* A test suite in [test.bats](tests/test.bats) that makes sure the service continues to work as expected.
* [Github actions setup](.github/workflows/tests.yml) so that the tests run automatically when you push to the repository.


**Contributed and maintained by [@rfay](https://github.com/rfay)**
