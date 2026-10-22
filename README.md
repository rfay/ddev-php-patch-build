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
3. It does not provide Xdebug, so `ddev xdebug` doesn't work. `xhprof` isn't built by default, and `ddev xhprof` hasn't been tested with it. See [extension support](https://static-php.dev/en/guide/extension-notes.html).
4. The resultant PHP binaries built here do not have the exact same extensions as the official DDEV PHP binaries, see [Extensions](#extensions).
5. Building the binaries happens in the build phase of `ddev start`, and it takes a long time on the first `ddev start` or whenever you change versions. The build uses static-php-cli's pre-built libraries where they exist; with the default extensions it took about 9 minutes on an Apple Silicon Mac. Each extension you add makes it longer.
6. If you want to see the build process as it proceeds, you can use `ddev utility rebuild` or `DDEV_VERBOSE=true ddev start`.
7. When you use this add-on, your DDEV `php_version` setting doesn't choose the PHP binary, but DDEV's `php.ini` and `php-fpm` configuration still come from it. Set `php_version` to the same minor version you build, for example `ddev config --php-version=8.5` for 8.5.12. See [PHP configuration](#php-configuration).
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

## PHP configuration

The static PHP binaries use DDEV's `php.ini` for the CLI and for `php-fpm`, so DDEV's settings such as `memory_limit`, upload limits and Mailpit's `sendmail_path` apply as usual.

Custom settings in `.ddev/php/*.ini` work as with the regular DDEV PHP. Don't put `extension=` lines in them: static PHP can't load shared extensions. Add the extension to `STATIC_PHP_EXTENSIONS` instead.

Run `ddev php --ini` to see which files are loaded.

## Extensions

The default build includes the extensions most projects need, listed under `STATIC_PHP_EXTENSIONS` below.

These extensions in the regular DDEV PHP aren't built by default, but you can add them to `STATIC_PHP_EXTENSIONS`. Each one adds to the build time:

`bz2`, `ffi`, `gettext`, `igbinary`, `imagick`, `ldap`, `memcached`, `msgpack`, `readline`, `redis`, `shmop`, `soap`, `sockets`, `sysvmsg`, `sysvsem`, `sysvshm`, `xhprof`, `xsl`, `yaml`

Setting `STATIC_PHP_EXTENSIONS` replaces the default list, so start from the default and add to it. For example, to add `redis` and `igbinary`:

```bash
ddev dotenv set .ddev/.env.php-patch-build --static-php-extensions="apcu,bcmath,calendar,ctype,curl,dom,exif,fileinfo,filter,ftp,gd,iconv,intl,mbstring,mysqli,openssl,pcntl,pdo,pdo_mysql,pdo_pgsql,pdo_sqlite,phar,posix,session,simplexml,sodium,sqlite3,tokenizer,xml,xmlreader,xmlwriter,zip,redis,igbinary"
ddev restart
```

Run `ddev php -m` to check which extensions are built in. See static-php-cli's [extension list](https://static-php.dev/en/guide/extensions.html) for everything it can build.

These are not available:

* `uploadprogress`: not supported by static-php-cli. Applications such as Drupal still work, but don't show upload progress bars.
* `xdebug`: see the caveats above.
* `xmlrpc`: not supported by static-php-cli.

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
export DDEV_GITHUB_TOKEN=your_github_token
```

DDEV passes `DDEV_GITHUB_TOKEN`, `GH_TOKEN`, or `GITHUB_TOKEN` to the build as a secret, so the token isn't stored in the image. This requires DDEV newer than v1.25.4; older versions build without a token.

| Variable                | Flag                      | Default                                                                                                                                                                                                                                                                  |
|-------------------------|---------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `STATIC_PHP_EXTENSIONS` | `--static-php-extensions` | `apcu,bcmath,calendar,ctype,curl,dom,exif,fileinfo,filter,ftp,gd,iconv,intl,mbstring,mysqli,openssl,pcntl,pdo,pdo_mysql,pdo_pgsql,pdo_sqlite,phar,posix,session,simplexml,sodium,sqlite3,tokenizer,xml,xmlreader,xmlwriter,zip` (`opcache` is added for PHP 8 and later) |
| `STATIC_PHP_VERSION`    | `--static-php-version`    | required, (not set)                                                                                                                                                                                                                                                      |

## Credits

**Contributed and maintained by [@rfay](https://github.com/rfay)**
