# ALB Internals
Quick information about how ALB works. Or some notes about what coud still be
improved.

## Directory structures

### Internal usage of ALB

- **ALB configuration files**:
  - `/opt/alb/`
    - `/opt/alb/alb-data/` -> `/var/alb/`
    - `/opt/alb/alb-logs/` -> `/var/log/alb/`
    - `/opt/alb/apps/` (Store OpenResty/NGinx rule for each app as `{{ app_id }}.conf`)
    - `/opt/alb/apps-data/` -> `/var/app/`
    - `/opt/alb/apps-logs/` -> `/var/log/app/`
    - `/opt/alb/haproxy/` -> `/etc/haproxy/`
    - `/opt/alb/nginx/` -> `/usr/local/openresty/nginx/`
    - `/opt/alb/letsencrypt/` -> `/etc/resty-auto-ssl/letsencrypt/certs/` <!--(talvez /etc/resty-auto-ssl/storage/file) -->
- **ALB logs files** (Note: Apps can have custom logs):
  - `/var/log/alb/access.log`
  - `/var/log/alb/error.log`
- **_Reserved (but not implemented) for potential future usage with data created
  on runtime by ALB_**
  - `/var/alb/`

### Usage of Apps

- **App rule**
  - `/opt/alb/apps/{{ app_uid }}.conf`
- **App data** _(if some parameter require custom folder to store data, but
  the specific path is not specified by the app, this pattern will be used)_
  - `/var/app/{{ app_uid }}/`
- **App logs** _(when not using `/var/log/alb/...` and not specified custom path)_
  - `/var/log/app/{{ app_uid }}/access.log`
  - `/var/log/app/{{ app_uid }}/error.log`

Tip: `/var/www/SomeFolder` and `/home/SomeUser/SomeFolder` are common pattens
of folders for your apps. The use of `/var/app/{{ app_uid }}/` is mostly to
avoid conflicts with existend content, and is not a requirement at all.

## System users

- `www-data`
  - This user (created OpenResty) is used sometimes as default user for common
    programs.
- `alb`
  - Planned, but not implemented
- `{{ app_uid }}` or `{{ app_systemuser }}` (Optional, not created by default)
  - Planned, but not implemented

<!--
## Important directories

- ALB
  - ALB Files
    - `/opt/alb/`
  - ALB default directory for logs (TL;DR: "the default place for the error.log/access.log from OpenResty/NGinx")
    - `/var/log/alb/`
- OpenResty
  - `/usr/local/openresty/`
  - Tip: OpenResty, even if is a fork of NGinx, **will not** use /etc/nginx/ (but `/usr/local/openresty/nginx/`)
-->


## To Do

- Add at least one <https://asciinema.org/> demonstration
- Rewrite/reorganize some tasks files, in special the
  [tasks/default-files.yml](tasks/default-files.yml) that is doing too much for
  different services
- Document strategy to use AP-ALB to secure Elastic Search without X-Pack
  - Some links about
    - https://discuss.elastic.co/t/basic-authentication-of-es-without-x-pack/94840
    - https://discuss.elastic.co/t/basic-auth-on-kibana-using-nginx/158871
- Add (or at least document) how to share HTTPS certificates accross cluster
  of load balancers
    - Hint: check <https://github.com/GUI/lua-resty-auto-ssl> and use Redis as
      storage instead of local filesystem.