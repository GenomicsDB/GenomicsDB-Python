echo "Installing minimal dependencies..."
yum install -y centos-release-scl && yum install -y devtoolset-11 &&
  yum install -y -q deltarpm &&
  yum update -y -q &&
  yum install -y -q epel-release &&
  yum install -y -q which wget git &&
  yum install -y -q autoconf automake libtool unzip &&
  yum install -y -q cmake3 patch &&
  yum install -y -q perl perl-IPC-Cmd &&
  yum install -y -q libuuid libuuid-devel &&
  yum install -y -q curl libcurl-devel &&
  echo "Installing minimal dependencies DONE"
