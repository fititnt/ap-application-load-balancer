#!/bin/sh

# Since (as 2019-12-14) RHEL/CentOS 8 does not have luarocks as option on some
# reliable repository, this script will be used to build only luarocks from
# source. Luarocks is need to make the initial installation of
# GUI/lua-resty-auto-ssl

# Short term, hotfix to have luarocks (not yet avalible on RHEL/CentOS 8, to
# install lua-resty-auto-ssl
cd /root
yum install -y lua compat-lua-devel tar wget zip make gcc
wget http://luarocks.github.io/luarocks/releases/luarocks-3.2.1.tar.gz
tar -vzxf luarocks-3.2.1.tar.gz
cd /root/luarocks-3.2.1
sh /root/luarocks-3.2.1/configure --with-lua-include=/usr/include/lua-5.1/
make install
# luarocks install lua-resty-auto-ssl

# Very ugly hack on RHEL/CentOS to allow OpenResty discover where auto-ssl is
# installed without change nginx. Will not be necessary when luarocks do not
# need be compiled
ln -s /usr/local/share/lua/5.3 /usr/local/share/lua/5.1

# TODO: maybe we should force the 'luarocks install lua-resty-auto-ssl'
#       install the library inside the OpenResty folder than make arbiratrary
#       symlinks
#       (fititnt, 2019-12-14 11:07 BRT)
