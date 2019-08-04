# Debugging AP-ALB

## Generic

```bash
# Open Ports
netstat -ntulp

# Statuses
systemctl status haproxy
systemctl status openresty
systemctl status ufw
```

## HAProxy

```bash
# Check HAProxy configuration
/usr/sbin/haproxy -c -V -f /etc/haproxy/haproxy.cfg
```

## OpenResty

...