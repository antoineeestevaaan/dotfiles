mkdir -p ~/downloads

curl -fLo ~/downloads/gh_2.74.2_linux_armv6.tar.gz https://github.com/cli/cli/releases/download/v2.74.2/gh_2.74.2_linux_armv6.tar.gz

tar xvf ~/downloads/gh_2.74.2_linux_armv6.tar.gz --directory /tmp

cp /tmp/gh_2.74.2_linux_armv6/bin/gh ~/opt/bin/gh

sudo mkdir -p /usr/local/share/man/man1
sudo cp --verbose /tmp/gh_2.74.2_linux_armv6/share/man/man1/* /usr/local/share/man/man1
