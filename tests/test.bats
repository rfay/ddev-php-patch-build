#   bats ./tests/test.bats
# To exclude release tests:
#   bats ./tests/test.bats --filter-tags '!release'
# For debugging:
#   bats ./tests/test.bats --show-output-of-passing-tests --verbose-run --print-output-on-failure

setup() {
  set -eu -o pipefail
  TEST_BREW_PREFIX="$(brew --prefix)"
  load "${TEST_BREW_PREFIX}/lib/bats-support/load.bash"
  load "${TEST_BREW_PREFIX}/lib/bats-assert/load.bash"


  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export TESTDIR=~/tmp/ddev-php-patch-build-test
  mkdir -p $TESTDIR
  export PROJNAME=test-php-patch-build
  export DDEV_NON_INTERACTIVE=true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  ddev config --project-name=${PROJNAME} --fail-on-hook-fail --php-version=8.4
  ddev start -y
  ddev describe
  export CUSTOM_PHP_MINOR_VERSION="8.2.23"
  cat <<EOF >index.php
<?php
echo phpversion();
EOF
}

health_checks() {
  run ddev php --version
  assert_success
  assert_output --partial "PHP ${CUSTOM_PHP_MINOR_VERSION}"
  run curl --fail -s https://${PROJNAME}.ddev.site/
  assert_success
  assert_output --partial "${CUSTOM_PHP_MINOR_VERSION}"
}

teardown() {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install from directory" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev dotenv set .ddev/.env.php-patch-build --static-php-version="${CUSTOM_PHP_MINOR_VERSION}"
  ddev add-on get ${DIR}
  ddev restart -y >/dev/null
  health_checks
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  echo "# ddev add-on get ddev/ddev-php-patch-build with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev dotenv set .ddev/.env.php-patch-build --static-php-version="${CUSTOM_PHP_MINOR_VERSION}"
  ddev add-on get ${DIR}
  ddev restart -y >/dev/null
  health_checks
}
