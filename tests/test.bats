#!/usr/bin/env bats

# Bats is a testing framework for Bash
# Documentation https://bats-core.readthedocs.io/en/stable/
# Bats libraries documentation https://github.com/ztombol/bats-docs

# For local tests, install bats-core, bats-assert, bats-file, bats-support
# And run this in the add-on root directory:
#   bats ./tests/test.bats
# To exclude release tests:
#   bats ./tests/test.bats --filter-tags '!release'
# To test another PHP minor version (default 8.5), as the CI matrix does:
#   STATIC_PHP_TEST_MINOR=8.6 bats ./tests/test.bats
# For debugging:
#   bats ./tests/test.bats --show-output-of-passing-tests --verbose-run --print-output-on-failure

setup() {
  set -eu -o pipefail

  # Override this variable for your add-on:
  export GITHUB_REPO=rfay/ddev-php-patch-build

  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support

  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  export PROJNAME="test-$(basename "${GITHUB_REPO}")"
  mkdir -p "${HOME}/tmp"
  export TESTDIR="$(mktemp -d "${HOME}/tmp/${PROJNAME}.XXXXXX")"
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site
  assert_success
  run ddev start -y
  assert_success

  # The PHP minor version to test is set by the CI matrix; build its newest release or pre-release
  export STATIC_PHP_TEST_MINOR="${STATIC_PHP_TEST_MINOR:-8.5}"
  export STATIC_PHP_TEST_VERSION="$(latest_php_version "${STATIC_PHP_TEST_MINOR}")"
  assert [ -n "${STATIC_PHP_TEST_VERSION}" ]
  echo "# Testing PHP ${STATIC_PHP_TEST_VERSION}" >&3
  printf "<?php\necho phpversion();\n" >index.php
  assert_file_exist index.php
  printf "<?php\necho ini_get('memory_limit'), ' ', ini_get('upload_max_filesize'), ' ', ini_get('zend.assertions');\n" >ini.php
  mkdir -p .ddev/php
  printf "upload_max_filesize = 7M\n" >.ddev/php/test.ini
}

# The project's web URL, which includes the router port when it isn't the default
web_url() {
  ddev describe -j | jq -r .raw.primary_url
}

# The newest release of a PHP minor version, or its current pre-release if there's no release yet
latest_php_version() {
  local version
  version="$(curl -fsSL "https://www.php.net/releases/index.php?json&version=$1" | jq -r '.version // empty')"
  if [ -z "${version}" ]; then
    version="$(curl -fsSL "https://www.php.net/pre-release-builds.php?format=json" | jq -r --arg minor "$1." '.[] | objects | .release | objects | select((.version // "") | startswith($minor)) | .version' | head -n 1)"
  fi
  echo "${version}"
}

# Match DDEV's php_version to the static PHP so its php.ini and php-fpm configuration are used
set_php_version() {
  # DDEV v1.25.4 and older don't support php_version 8.6; 8.5 only changes which php.ini is used
  ddev config --php-version="${STATIC_PHP_TEST_MINOR}" >/dev/null 2>&1 || ddev config --php-version=8.5
}

health_checks() {
  run ddev php --version
  assert_success
  assert_output --partial "PHP ${STATIC_PHP_TEST_VERSION}"

  run curl -sf "$(web_url)/"
  assert_success
  assert_output --partial "${STATIC_PHP_TEST_VERSION}"

  run ddev describe
  assert_success
  assert_output --partial "Static PHP: ${STATIC_PHP_TEST_VERSION}"

  run ddev php -m
  assert_success
  assert_output --partial "apcu"
  assert_output --partial "bcmath"
  assert_output --partial "ctype"
  assert_output --partial "curl"
  assert_output --partial "dom"
  assert_output --partial "fileinfo"
  assert_output --partial "filter"
  assert_output --partial "ftp"
  assert_output --partial "gd"
  assert_output --partial "mbstring"
  assert_output --partial "openssl"
  assert_output --partial "pdo_mysql"
  assert_output --partial "pdo_pgsql"
  assert_output --partial "pdo_sqlite"
  assert_output --partial "session"
  assert_output --partial "sqlite3"
  assert_output --partial "tokenizer"
  assert_output --partial "xml"
}

# Checks for changes not yet in a release; move into health_checks after the next release
unreleased_checks() {
  # DDEV's php.ini and .ddev/php are used by the CLI and php-fpm
  run ddev php ini.php
  assert_success
  assert_output "-1 7M 1"

  run curl -sf "$(web_url)/ini.php"
  assert_success
  assert_output "1024M 7M 1"

  run ddev php -m
  assert_success
  refute_output --partial "Warning"
  for ext in apcu bcmath calendar ctype curl dom exif fileinfo filter ftp gd iconv intl mbstring mysqli openssl pcntl pdo_mysql pdo_pgsql pdo_sqlite posix session sodium sqlite3 tokenizer xml xmlreader xmlwriter zip "Zend OPcache"; do
    assert_line --regexp "^${ext}[[:space:]]*$"
  done
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1
  # Persist TESTDIR if running inside GitHub Actions. Useful for uploading test result artifacts
  # See example at https://github.com/ddev/github-action-add-on-test#preserving-artifacts
  if [ -n "${GITHUB_ENV:-}" ]; then
    [ -e "${GITHUB_ENV:-}" ] && echo "TESTDIR=${HOME}/tmp/${PROJNAME}" >> "${GITHUB_ENV}"
  else
    [ "${TESTDIR}" != "" ] && rm -rf "${TESTDIR}"
  fi
}

@test "install from directory" {
  set -eu -o pipefail

  set_php_version
  run ddev dotenv set .ddev/.env.php-patch-build --static-php-version="${STATIC_PHP_TEST_VERSION}"
  assert_file_exist .ddev/.env.php-patch-build

  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
  unreleased_checks
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail

  # One release test is enough; the CI matrix runs it only in the default PHP job
  if [ "${STATIC_PHP_TEST_MINOR}" != "8.5" ]; then
    skip "release test only runs for PHP 8.5"
  fi
  set_php_version
  run ddev dotenv set .ddev/.env.php-patch-build --static-php-version="${STATIC_PHP_TEST_VERSION}"
  assert_file_exist .ddev/.env.php-patch-build

  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}
