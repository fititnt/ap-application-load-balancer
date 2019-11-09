# NLB Internals
> Tip: consider reading first the [ALB Internals](alb-internals.md).

Before going further, consider that the features related to _"network load
balancer"_ (the _"more Layer 4 features"_) from AP-ALB are _an extra_, not a
main objective, when otimizing automation with Ansible on this project. It does
not means that the HAproxy is not important: it is! To list some details:

- HAProxy is by default is installed with ALB and is in front of every ALB App.
  - The averange user maybe not even need to know what HAProxy is doing. **The
    idea is "it just works fine" out of the box**.
  - **BUT** if later on production some feature get too complicated to push
    OpenResty to the limits... the **HAProxy already is there!**
- HAProxy reuse some variables of AP-ALB
- Yes, OpenResty logs already will register the user Real IP
- (...)

## Ports
> Note: these defaults can be changed.

- HAproxy `0.0.0.0:80` -> OpenResty: `127.0.0.1:8080`
  - HAProxy listem to HTTP :80 port then will redirect to OpenResty :8080
  - Even without custom firewall rule the extra OpenResty port will not be open
    to the world.
- HAproxy `0.0.0.0:443` -> OpenResty: `127.0.0.1:4443`
  - HAProxy listem to HTTPS :443 port then will redirect to OpenResty :4443
  - Even without custom firewall rule the extra OpenResty port will not be open
    to the world.
  - The HTTPS/TLS termination is done by OpenResty.
    - This is an option that could be improved later and make HAProxy also do
      the HTTPS.

HAproxy can be used for other types of load balancing, like to intermediate
MariaDB/MySQL, MongoDB, Apache, etc in a very efficient way.

## Directory structures

As version **v0.6.0-alpha**, `/opt/nlb/` is symbolic link to `/opt/alb/`. This
may change on future.

- **NLB configuration files**:
  - `/opt/nlb/` -> `/opt/alb/`
    - **`/opt/alb/alb.conf`** -> `/usr/local/openresty/nginx/conf/nginx.conf`
    - **`/opt/alb/nlb.cfg`** -> `/etc/haproxy/haproxy.cfg`
    - `/opt/alb/alb-data/` -> `/var/alb/`
    - `/opt/alb/alb-logs/` -> `/var/log/alb/`
    - `/opt/alb/apps/` _(Store OpenResty/NGinx rule for each app as **`/opt/alb/apps/{{ app_id }}.conf`**)_
    - `/opt/alb/info/` _(Planed, not fully implemented)_
    - `/opt/alb/apps-data/` -> `/var/app/`
    - `/opt/alb/apps-logs/` -> `/var/log/app/`
    - `/opt/alb/haproxy/` -> `/etc/haproxy/`
    - `/opt/alb/nginx/` -> `/usr/local/openresty/nginx/`
    - `/opt/alb/letsencrypt/` -> `/etc/resty-auto-ssl/letsencrypt/`

_@TODO improve documentation (fititnt, 2019-11-08 23:10 BRT)_