import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']
).get_hosts('all')


def test_required_haproxy_is_installed(host):
    assert (not host.file("/opt/alb/info/haproxy").exists) \
        or host.package("haproxy").is_installed


def test_required_haproxy_is_enabled(host):
    assert not host.file("/opt/alb/info/isconteiner").exists or \
        (host.file("/opt/alb/info/haproxy").exists
            and host.service("haproxy").is_enabled)


def test_required_haproxy_is_running(host):
    assert (not host.file("/opt/alb/info/haproxy").exists) \
        or host.service("haproxy").is_running


def test_required_openresty_is_installed(host):
    assert (not host.file("/opt/alb/info/openresty").exists) \
        or host.package("openresty").is_installed


def test_required_openresty_is_enabled(host):
    assert not host.file("/opt/alb/info/isconteiner").exists or \
        (host.file("/opt/alb/info/openresty").exists
            and host.service("openresty").is_enabled)


def test_required_openresty_is_running(host):
    assert (not host.file("/opt/alb/info/openresty").exists) \
        or host.service("openresty").is_running


def test_required_ufw_is_installed(host):
    assert (not host.file("/opt/alb/info/ufw").exists) \
        or host.package("ufw").is_installed


def test_required_ufw_is_enabled(host):
    assert not host.file("/opt/alb/info/isconteiner").exists or \
        (host.file("/opt/alb/info/ufw").exists
            and host.service("ufw").is_enabled)


def test_required_ufw_is_running(host):
    assert (not host.file("/opt/alb/info/ufw").exists) \
        or host.service("ufw").is_running
