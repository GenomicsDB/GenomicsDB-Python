source /opt/rh/devtoolset-11/enable
echo "Building openssl..."
OPENSSL_PREFIX=/usr/local
OPENSSL_VERSION=3.0.11
if [[ ! -d $OPENSSL_PREFIX/include/openssl ]]; then
  pushd /tmp
  wget $WGET_NO_CERTIFICATE https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz &&
    tar -xvzf openssl-$OPENSSL_VERSION.tar.gz &&
    cd openssl-$OPENSSL_VERSION &&
    CFLAGS=-fPIC ./config no-tests -fPIC --prefix=$OPENSSL_PREFIX --openssldir=$OPENSSL_PREFIX &&
    make -j4 && make install && echo "Installing OpenSSL DONE"
  rm -fr /tmp/openssl*
  popd
fi
