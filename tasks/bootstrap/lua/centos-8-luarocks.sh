#!/bin/sh

# Short term, hotfix to have luarocks (not yet avalible on RHEL/CentOS 8, to
# install lua-resty-auto-ssl
cd /root
yum install lua compat-lua-devel tar wget zip make gcc
wget http://luarocks.github.io/luarocks/releases/luarocks-3.2.1.tar.gz
tar -vzxf luarocks-3.2.1.tar.gz
cd /root/luarocks-3.2.1
sh /root/luarocks-3.2.1/configure --with-lua-include=/usr/include/lua-5.1/
make install
# luarocks install lua-resty-auto-ssl
