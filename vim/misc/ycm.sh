#!/bin/bash
cd $ZDOTDIR/../vim/plugged/YouCompleteMe/
jumbo install gcc48
PATH=$JUMBO_ROOT/bin:$PATH env C_INCLUDE_PATH=${JUMBO_ROOT}/opt/kernel-headers-2.6.32/include:${JUMBO_ROOT}/include:/usr/include MOCK_CPLUS_INCLUDE_PATH=${JUMBO_ROOT}/opt/gcc48/include/c++/4.8.3:${JUMBO_ROOT}/opt/gcc48/include/c++/4.8.3/x86_64-unknown-linux-gnu:${JUMBO_ROOT}/opt/gcc48/include/c++/4.8.3/backward:${JUMBO_ROOT}/opt/gcc48/include/c++/4.8.3/x86_64-unknown-linux-gnu/4.8.3/include:${JUMBO_ROOT}/opt/gcc48/include/c++/4.8.3/x86_64-unknown-linux-gnu/4.8.3/include-fixed:${JUMBO_ROOT}/opt/kernel-headers-2.6.32/include:${JUMBO_ROOT}/include:/usr/include LINK=gcc PATH=${JUMBO_ROOT}/opt/gcc48/bin:$PATH python install.py
