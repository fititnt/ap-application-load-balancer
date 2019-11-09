# NLB Internals
> Tip: consider reading first the [ALB Internals](alb-internals.md).

Before going further, consider that the features related to _"network load
balancer"_ (the _"more Layer 4 features"_) from AP-ALB are _an extra_, not a
main objective, when otimizing automation with Ansible on this project. It does
not means that the HAproxy is not important: it is! To list some details:

- HAProxy is by default is installed with ALB and is in front of every ALB App.
  - The averange user maybe not even need to know what HAProxy is doing
  - **BUT** if later on production some feature get too complicated to push
    OpenResty to the limits... the **HAProxy already is there!**.
- HAProxy reuse some variables of AP-ALB
- (...)

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