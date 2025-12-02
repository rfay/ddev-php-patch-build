[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/rfay/ddev-php-patch-build/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/rfay/ddev-php-patch-build/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/rfay/ddev-php-patch-build)](https://github.com/rfay/ddev-php-patch-build/commits)
[![release](https://img.shields.io/github/v/release/rfay/ddev-php-patch-build)](https://github.com/rfay/ddev-php-patch-build/releases/latest)

# Experimental Add-on to use PHP patch versions: ddev-php-patch-build

## Overview

[DDEV](https://ddev.com) users periodically ask if they can use a specific PHP patch version with their projects, either to test/compare for a particular bug or to match a production version exactly.

This **experimental** add-on tries to address that need, although there are a number of caveats:

1. The build done using this process uses the technique from [static-php-cli](https://github.com/crazywhalecc/static-php-cli) and full details are available there. It supports all the versions supported in the upstream repository, currently PHP 7.3-8.5.
2. The build does not match the build done using the official DDEV php packages (which actually come from [deb.sury.org](https://deb.sury.org/).
3. It currently does not provide xdebug, see [extension support](https://static-php.dev/en/guide/extension-notes.html).
4. The resultant PHP binaries built here do not have the exact same extensions as the official DDEV PHP binaries.
5. Building the binaries happens in the build phase of `ddev start`, and it takes a long time on the first `ddev start` or whenever you change versions. My tests on Gitpod, with a great internet connection, took about 8-9 minutes. It can be really annoying, and a better way to build would be an improvement.
6. If you want to see the build process as it proceeds, you can use `ddev utility rebuild` or `DDEV_VERBOSE=true ddev start`.
7. When you use this add-on, your DDEV `php_version` setting is ignored.
8. To see what's going on during the build, use `ddev utility rebuild -s web --cache`
9. Your mileage may vary.

* The [static-php-cli](https://github.com/crazywhalecc/static-php-cli) repository provides a relatively easy way to build static PHP binaries (the CLI and `php-fpm`) which can be used to replace the ones installed in `ddev-webserver`.
* The provided `.ddev/web-build/Dockerfile.php-patch-build` does the building.

## Installation

```bash
# Set your desired PHP version, when prompted, e.g., 8.0.10
ddev add-on get rfay/ddev-php-patch-build
ddev restart
```

After installation, make sure to commit the `.ddev` directory to version control.

## Advanced Customization

You can choose a different PHP version with:

```bash
ddev dotenv set .ddev/.env.php-patch-build --static-php-version=8.0.10
ddev add-on get rfay/ddev-php-patch-build
ddev restart
```

After installation, make sure to commit the `.ddev` directory to version control.

If you hit GitHub rate limits while downloading `static-php-cli` extensions, export your token before running `ddev start` to build the PHP binaries:

```bash
export GITHUB_TOKEN=your_github_token
```

| Variable                | Flag                      | Default                                                                                                                                              |
|-------------------------|---------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| `STATIC_PHP_EXTENSIONS` | `--static-php-extensions` | `apcu,bcmath,ctype,curl,dom,fileinfo,filter,ftp,gd,mbstring,openssl,pdo,pdo_mysql,pdo_pgsql,pdo_sqlite,phar,session,simplexml,sqlite3,tokenizer,xml` |
| `STATIC_PHP_VERSION`    | `--static-php-version`    | required, (not set)                                                                                                                                  |

## Credits

**Contributed and maintained by [@rfay](https://github.com/rfay)**
