# ALB Internals
> Tip: at [NLB Internals](alb-internals.md) there is additional features that
may be useful (TL;DR: _the HAproxy part_), but we try to provide good defaults
so maybe you could ignore HAProxy if it just works for you.

## FAQ

- _How much overhead of RAM and CPU a server with AP-ALB have compared with
  alternative NameOfAlternative?_
  - **The overhead of HAProxy and OpenResty is low. Trust me.**
- _AP-ALB is mean to be installed just only _on frontend servers_ that are exposed to
  public IPs and then access internal servers?_
  - **This use is just one of the cases**  (and the most intuitive compared to
    cloud ALBs)
  - **BUT you can also have, as example, both**
    - **all-in-one (BothApplication/Network Load Balancer and some
       PHP/Python/Java/Etc servers) on a single machine or**
    - **put AP-ALB servers behind AP-ALB servers.**
- _If AP-ALB could be installed "on everyting" it means even on database servers?_
  - **If you are both your application server and database server are on same
    host, yes**
  - **But if you have to choose betwen put a network load balancer (the HAProxy)
      or on the database(s) server(s) or on the application server(s) (the
      ones running PHP/Python/NodeJS/Java/Etc) put on you application servers.**

## Directory structures

### Internal usage of ALB

If debugging ALB (and not just one App) these directories and folders are the
ones you are likely to be interested.

Think the folder `/opt/alb/` as one [syntactic sugar](https://en.wikipedia.org/wiki/Syntactic_sugar).
for all other folders and files that are important.

- **ALB configuration files**:
  - `/opt/alb/`
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
- **ALB logs files**:
  - `/var/log/alb/access.log`
  - `/var/log/alb/error.log`
  - `/var/log/alb/letsencrypt.log`
  - `/var/log/alb/apps/` -> `/var/log/app/`
- **Data created on Runtime by ALB** _(Planed, not fully implemented)_
  - `/var/alb/`

### Shared usage for third party tools

Some variables when present on a play of a playbook using ALB will create or
update contents of specific files on each server. **Consider this list as
suggestion, not as one strong enforcement, and that most of these options will
not automatically be considered if not enabled for other tools**, in special the
ones that could be useful for Firewalls. 

Some considerations:
- `alb_vars_saveondisk: no` will enforce not store the suggested variables on
  these documented paths.
  - **Use this option if you are concerned with vunerable applications that
    could leak sensive data**.
- Since you is already using Ansible if want to reuse these data on other tools
  consider that can be simple use the ALBs variables as information.
  - It can be easier do this can change other applications to watch for changes
    on these files.

#### `alb_ips_remoteadmins`
- File: `/opt/alb/remoteadmins`

#### `alb_ips_dmz`
- File: `/opt/alb/dmz`

#### `alb_ips_whitelist`
- File: `/var/alb/ips_whitelist.txt`

#### `alb_ips_blacklist`
- File: `/var/alb/ips_blacklist.txt`

#### `alb_domains_whitelist`
- File: `/var/alb/domains_whitelist.txt`

#### `alb_domains_blacklist`
- File: `/var/alb/domains_blacklist.txt`

### Usage of Apps

If your ALB setup already is working, these are the files and folders that
are specific for each App.

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

- Add at least one <https://asciinema.org/> demonstration with some example of ALB working in practice
- Add (or at least document) how to share HTTPS certificates accross cluster
of load balancers
  - Hint: check <https://github.com/GUI/lua-resty-auto-ssl> and use Redis as
    storage instead of local filesystem.

<!--

- Rewrite/reorganize some tasks files, in special the
  [tasks/default-files.yml](tasks/default-files.yml) that is doing too much for
  different services
- Document strategy to use AP-ALB to secure Elastic Search without X-Pack
  - Some links about
    - https://discuss.elastic.co/t/basic-authentication-of-es-without-x-pack/94840
    - https://discuss.elastic.co/t/basic-auth-on-kibana-using-nginx/158871

-->