#!/bin/bash
install_prereqs() {
  HOMEBREW_NO_AUTO_UPDATE=1
  HOMEBREW_NO_INSTALL_CLEANUP=1
  check_rc $(brew list openssl@3 &> /dev/null || brew install openssl@3)
  brew list libcsv &> /dev/null && brew uninstall libcsv
  # Use the uuid from framework
  brew list ossp-uuid &> /dev/null && brew uninstall ossp-uuid

  brew list cmake &>/dev/null || brew install cmake
  brew list mpich &>/dev/null || brew install mpich
  brew list automake &> /dev/null || brew install automake
  brew list pkg-config &> /dev/null || brew install pkg-config

# brew has started installing lcov 2.0 and some GenomicsDB sources are erroring out while running lcov
# For example -
# geninfo: ERROR: "/Users/runner/work/GenomicsDB/GenomicsDB/src/main/cpp/include/query_operations/variant_operations.h":50: function _ZN23RemappedDataWrapperBaseC2Ev end line 37 less than start line
# The errors can be suppressed, but installing the older version 1.16 explicitly for now
  wget https://github.com/Homebrew/homebrew-core/raw/e92d2ae54954ebf485b484d8522104700b144fee/Formula/lcov.rb
  brew list lcov &> /dev/null && brew uninstall lcov
  brew install -s lcov.rb

  brew list zstd &> /dev/null || brew install zstd
}

install_prereqs