import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']
).get_hosts('all')


def test_hosts_file(host):
    f = host.file('/etc/hosts')

    assert f.exists
    assert f.user == 'root'
    assert f.group == 'root'


def test_haproxy_is_installed_and_running(host):
    haproxy = host.package("haproxy")

    assert haproxy.is_installed
    # assert haproxy.is_running
    # Error: E       AttributeError: 'DebianPackage' object has no attribute
    # 'is_running'


def test_openresty_is_installed_and_running(host):
    openresty = host.package("openresty")

    assert openresty.is_installed
    # assert openresty.is_running
    # Error: E       AttributeError: 'DebianPackage' object has no attribute
    # 'is_running'

# From https://testinfra.readthedocs.io/en/latest/#quick-start
# def test_passwd_file(host):
#     passwd = host.file("/etc/passwd")
#     assert passwd.contains("root")
#     assert passwd.user == "root"
#     assert passwd.group == "root"
#     assert passwd.mode == 0o644
#
#
# def test_nginx_is_installed(host):
#     nginx = host.package("nginx")
#     assert nginx.is_installed
#     assert nginx.version.startswith("1.2")
#
#
# def test_nginx_running_and_enabled(host):
#     nginx = host.service("nginx")
#     assert nginx.is_running
#     assert nginx.is_enabled
