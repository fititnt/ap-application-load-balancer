# FILE: /opt/alb/bin/tests/test_alb-standard-node.py

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


def test_ufw_is_installed(host):
    assert host.package("ufw").is_installed


def test_ufw_is_enabled(host):
    assert host.service("ufw").is_enabled


def test_ufw_is_running(host):
    assert host.service("ufw").is_running