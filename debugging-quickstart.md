# Debugging AP-ALB

## Generic

```bash
# Open Ports
netstat -ntulp

# Statuses
systemctl status haproxy
systemctl status openresty
systemctl status ufw

# Configuration files
vim /etc/haproxy/haproxy.cfg
vim /usr/local/openresty/nginx/conf/nginx.conf
vim /usr/local/openresty/nginx/conf/sites-enabled/MYAPPHERE.conf

# Log files
tail -f /var/log/application_load_balancer/access.log
tail -f /var/log/application_load_balancer/error.log
```

## HAProxy

```bash
# Check HAProxy configuration
/usr/sbin/haproxy -c -V -f /etc/haproxy/haproxy.cfg
```

## OpenResty

...