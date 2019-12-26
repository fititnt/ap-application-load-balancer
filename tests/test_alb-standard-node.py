# FILE: /opt/alb/bin/tests/test_alb-standard-node.py

def test_passwd_file(host):
    passwd = host.file("/etc/passwd")
    assert passwd.contains("root")
    assert passwd.user == "root"
    assert passwd.group == "root"
    assert passwd.mode == 0o644


def test_openresty_is_installed(host):
    nginx = host.package("openresty")
    assert nginx.is_installed
    # assert nginx.version.startswith("1.2")


def test_openresty_running_and_enabled(host):
    nginx = host.service("openresty")
    assert nginx.is_running
    assert nginx.is_enabled


def test_haproxy_is_installed(host):
    nginx = host.package("haproxy")
    assert nginx.is_installed
    # assert nginx.version.startswith("1.2")


def test_haproxy_running_and_enabled(host):
    nginx = host.service("haproxy")
    assert nginx.is_running
    assert nginx.is_enabled