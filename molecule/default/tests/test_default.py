import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']
).get_hosts('all')


def test_hosts_file(host):
    f = host.file('/etc/hosts')

    assert f.exists
    assert f.user == 'root'
    assert f.group == 'root' or f.group == 'wheel'


def test_haproxy_is_installed(host):
    assert host.package("haproxy").is_installed


def test_haproxy_is_enabled(host):
    assert host.service("haproxy").is_enabled


def test_haproxy_is_running(host):
    assert host.service("haproxy").is_running


def test_openresty_is_installed(host):
    assert host.package("openresty").is_installed


def test_openresty_is_enabled(host):
    assert host.service("openresty").is_enabled


def test_openresty_is_running(host):
    assert host.service("openresty").is_running


#def test_ufw_is_installed(host):
#    assert host.package("ufw").is_installed
#
#
#def test_ufw_is_enabled(host):
#    assert host.service("ufw").is_enabled
#
#
#def test_ufw_is_running(host):
#    assert host.service("ufw").is_running
