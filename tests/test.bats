setup() {
  set -eu -o pipefail
  # TODO: These should be done in github-action-addon-test:
  # https://github.com/ddev/github-action-add-on-test/issues/18
  load '/home/linuxbrew/.linuxbrew/lib/bats-support/load.bash'
  load '/home/linuxbrew/.linuxbrew/lib/bats-assert/load.bash'
  load '/home/linuxbrew/.linuxbrew/lib/bats-file/load.bash'

  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export TESTDIR=~/tmp/test-addon-template
  mkdir -p $TESTDIR
  export PROJNAME=test-php-patch-build
  export DDEV_NON_INTERACTIVE=true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  ddev config --project-name=${PROJNAME}
  ddev start -y >/dev/null
  STATIC_PHP_VERSION="8.2.8"
  cat <<EOF >index.php
<?php
phpinfo();
EOF
}

health_checks() {
  run ddev php --version
  assert_success
  assert_output --partial "PHP ${STATIC_PHP_VERSION}"
  run curl --fail -s https://${PROJNAME}.ddev.site/
  assert_success
  assert_output --partial "PHP Version ${STATIC_PHP_VERSION}"
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
  echo "# ddev get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  echo ${STATIC_PHP_VERSION} | ddev get ${DIR}
  ddev restart
  health_checks
}

# TODO: Re-enable when there is a release
#@test "install from release" {
#  set -eu -o pipefail
#  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
#  echo "# ddev get ddev/ddev-php-patch-build with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
#  ddev get ddev/ddev-php-patch-build
#  ddev restart >/dev/null
#  health_checks
#}

