#! /bin/sh
#
# gcc48.sh
#
# set -Eeuo pipefail
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")


export PATH=$HOME/.jumbo/opt/binutils/bin:$PATH
export LD_LIBRARY_PATH=$JUMBO_ROOT/lib

# Detect gcc/g++ include path using preprocessor
export INCLUDE_PATH_ONE_LINER='@M = (@M, $1) if $_ !~ /(?:\/usr\/include|\/usr\/local\/include)/ and /^\s*(\/.+)/; END {print join ":", @M}'
export MOCK_C_INCLUDE_PATH="$(${JUMBO_ROOT}/opt/gcc48/bin/cpp -Wp,-v -x c /dev/null 2>&1 | perl -ne "${INCLUDE_PATH_ONE_LINER}")"
#MOCK_C_INCLUDE_PATH="${MOCK_C_INCLUDE_PATH}:${srcdir}/glibc-headers/usr/include"
export MOCK_C_INCLUDE_PATH="${MOCK_C_INCLUDE_PATH}:${JUMBO_ROOT}/opt/kernel-headers-2.6.32/include:${JUMBO_ROOT}/include:/usr/include"
export MOCK_CPLUS_INCLUDE_PATH="$(${JUMBO_ROOT}/opt/gcc48/bin/cpp -Wp,-v -x c++ /dev/null 2>&1 | perl -ne "${INCLUDE_PATH_ONE_LINER}")"
#MOCK_CPLUS_INCLUDE_PATH="${MOCK_CPLUS_INCLUDE_PATH}:${srcdir}/glibc-headers/usr/include"
export MOCK_CPLUS_INCLUDE_PATH="${MOCK_CPLUS_INCLUDE_PATH}:${JUMBO_ROOT}/opt/kernel-headers-2.6.32/include:${JUMBO_ROOT}/include:/usr/include"

export C_INCLUDE_PATH="${MOCK_C_INCLUDE_PATH}"
export CPLUS_INCLUDE_PATH="${MOCK_CPLUS_INCLUDE_PATH}" #make REQUIRES_RTTI=1
export PATH="${JUMBO_ROOT}/opt/gcc48/bin:${PATH}"

# disable flock
export LINK=g++

env CC=$JUMBO_ROOT/opt/gcc46/bin/gcc C_INCLUDE_PATH="${MOCK_C_INCLUDE_PATH}" CPLUS_INCLUDE_PATH="${MOCK_CPLUS_INCLUDE_PATH}"  PATH="${JUMBO_ROOT}/opt/gcc48/bin:${PATH}" pip3 install pynvim  -i https://pypi.python.org/simple/ --index https://pypi.python.org/pypi --user
pip3 install neovim  -i https://pypi.python.org/simple/ --index https://pypi.python.org/pypi --user
pip install neovim  -i https://pypi.python.org/simple/ --index https://pypi.python.org/pypi --user


