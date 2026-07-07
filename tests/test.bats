#!/usr/bin/env bats

# Bats is a testing framework for Bash
# Documentation https://bats-core.readthedocs.io/en/stable/
# Bats libraries documentation https://github.com/ztombol/bats-docs

# For local tests, install bats-core, bats-assert, bats-file, bats-support
# And run this in the add-on root directory:
#   bats ./tests/test.bats
# To exclude release tests:
#   bats ./tests/test.bats --filter-tags '!release'
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

  export CUSTOM_PHP_MINOR_VERSION="8.3.19"
  printf "<?php\necho phpversion();\n" >index.php
  assert_file_exist index.php
}

health_checks() {
  run ddev php --version
  assert_success
  assert_output --partial "PHP ${CUSTOM_PHP_MINOR_VERSION}"

  run curl -sf https://${PROJNAME}.ddev.site/
  assert_success
  assert_output --partial "${CUSTOM_PHP_MINOR_VERSION}"

  run ddev describe
  assert_success
  assert_output --partial "Static PHP: ${CUSTOM_PHP_MINOR_VERSION}"

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

  run ddev dotenv set .ddev/.env.php-patch-build --static-php-version="${CUSTOM_PHP_MINOR_VERSION}"
  assert_file_exist .ddev/.env.php-patch-build

  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail

  run ddev dotenv set .ddev/.env.php-patch-build --static-php-version="${CUSTOM_PHP_MINOR_VERSION}"
  assert_file_exist .ddev/.env.php-patch-build

  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}
