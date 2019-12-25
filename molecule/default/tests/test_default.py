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
    assert haproxy.is_running


def test_openresty_is_installed_and_running(host):
    openresty = host.package("openresty")

    assert openresty.is_installed
    assert openresty.is_running
