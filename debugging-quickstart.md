# Debugging Quickstart for AP-ALB

## In case of emergency

> If editing/testing configurations directly on a production server (_actually
> something not uncommon_), use
>
> - `openresty -t`
> - `/usr/sbin/haproxy -c -V -f /etc/haproxy/haproxy.cfg`
>
> respectively for OpenResty and HAProxy **BEFORE** stoping and starting to
> avoid service interruption. **If the services are already down, these commands
> are likely to give a hint where is the error.**
>
> **New changes made on already existing configurations via ansible automation of
> AP-ALB always will create a backup file** (example: on directory
> `/etc/haproxy/` the file `haproxy.cfg` have a backup file like
`haproxy.cfg.15771.2019-10-31@19:47:23~`), so for an emergency hotfix you can
> either
>
> 1. edit the main file and fix the specific line,
> 3. copy and backup over the main file
> 3. (if is an site configuration for an less important app than the complete
> server) delete/rename the `.../sites-enabled/appname.conf` file

## In case of server overload

### HAProxy

> NOTE: to stop AL-ALB to revert manual changes on `/etc/haproxy/haproxy.cfg`,
> set `alb_forceignore_haproxy: true`.

By default AP-ALB will have an HAProxy in front of HTTP and HTTPS port of the
OpenResty. So if you did not disabled explicitly (for some reason like otimizing
AP-ALB running on a server with 128MB or RAM) HAProxy it is running right
now in yours servers.

If things get hardcore even if you did not have experience with HAproxy can be
a good idea to at least check online if HAProxy could be in theory more
efficient and easy to implement a rule than equivalent using OpenResty/NGinx.
Them try it. If you can't replicate all your enviroment (or really don't have
time to waste) edit `/etc/haproxy/haproxy.cfg` directly, validate file syntax
with `/usr/sbin/haproxy -c -V -f /etc/haproxy/haproxy.cfg` and then test if
services still working.

HAproxy (and yes, doing right even OpenResty/NGinx) can be reloaded with new
configurations without even end users losing connetions or dropping packages,
so is more easy the server get in a worst state than before because of human
error. Keep in mind that the AP-ALB focus more around OpenResty/NGinx
configuration only because is easier for who will deal on most cases. But from
some types of DDoS to some more low level network load balancing definely
HAproxy is better option.

<!--
https://www.digitalocean.com/community/tutorials/how-to-upgrade-nginx-in-place-without-dropping-client-connections
-->

<!--
## IN CASE OF EMERGENGY IN PRODUCTION

> IMPORTANT:
-->

## Generic

> TODO: organize useful debug commands a bit better (fititnt, 2019-11-01 00:05 BRT)

```bash
# Open Ports
netstat -ntulp

# Statuses
systemctl status haproxy
systemctl status openresty
systemctl status ufw

journalctl -xe -u haproxy
journalctl -xe -u openresty

## Validate/test configurations
openresty -t
logrotate -d /etc/logrotate.d/alb
logrotate -d /etc/logrotate.d/alb_apps

# Configuration files
vim /etc/haproxy/haproxy.cfg
vim /usr/local/openresty/nginx/conf/nginx.conf
vim /usr/local/openresty/nginx/conf/sites-enabled/MYAPPHERE.conf
vim /etc/logrotate.d/alb
vim /etc/logrotate.d/alb_apps

# Log files
tail -f /var/log/alb/access.log
tail -f /var/log/alb/error.log
tail -f /var/log/haproxy.log

## Multitail
sudo apt-get install multitail

multitail -ci white /var/log/alb/access.log -ci yellow -I /var/log/alb/error.log  -ci blue -I /var/log/alb/letsencrypt.log
multitail -ci green /var/log/app/APPNAMEHERE/access.log -ci red -I /var/log/APPNAMEHERE/error.log
multitail -ci white /var/log/alb/access.log -ci yellow -I /var/log/alb/error.log  -ci blue -I /var/log/alb/letsencrypt.log -ci green /var/log/app/APPNAMEHERE/access.log -ci red -I /var/log/APPNAMEHERE/error.log

```

## HAProxy

```bash
# Check HAProxy configuration
/usr/sbin/haproxy -c -V -f /etc/haproxy/haproxy.cfg
```

## OpenResty

...