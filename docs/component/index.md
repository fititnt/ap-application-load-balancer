# AP Application Load Balancer Components
[![GitHub: fititnt/ap-application-load-balancer](../img/badges/github.svg)](https://github.com/fititnt/ap-application-load-balancer) [![Website: ap-application-load-balancer.etica.ai](../img/badges/website.svg)](https://ap-application-load-balancer.etica.ai/)


<!-- TOC -->

- [AP Application Load Balancer Components](#ap-application-load-balancer-components)
    - [ALB components](#alb-components)
        - [Shared options](#shared-options)
            - [ACME](#acme)
            - [Applications/Sysapplications variables](#applicationssysapplications-variables)
            - [Autentication Credentials](#autentication-credentials)
            - [Bastion Hosts](#bastion-hosts)
            - [DMZ (DeMilitarized Zone)](#dmz-demilitarized-zone)
            - [Jump Server](#jump-server)
        - [Apps](#apps)
            - [ALB Strategies](#alb-strategies)
                - [files-local](#files-local)
                - [hello-world](#hello-world)
                - [minimal](#minimal)
                - [proxy](#proxy)
                - [raw](#raw)
        - [Bootstrap](#bootstrap)
            - [Bootstrap Python installation](#bootstrap-python-installation)
        - [HAProxy](#haproxy)
            - [HAProxy stats page](#haproxy-stats-page)
            - [HAProxy TLS Termination](#haproxy-tls-termination)
        - [Logrotate](#logrotate)
        - [OpenResty](#openresty)
            - [Run OpenResty without HAProxy](#run-openresty-without-haproxy)
            - [lua-resty-auto-ssl](#lua-resty-auto-ssl)
        - [SanityCheck](#sanitycheck)
        - [Status](#status)
        - [Sysapps](#sysapps)
            - [ALB optionated sysapps](#alb-optionated-sysapps)
        - [UFW](#ufw)
            - [Applying only firewall rules on a specific server (i.e. do not install HAProxy, OpenResty...)](#applying-only-firewall-rules-on-a-specific-server-ie-do-not-install-haproxy-openresty)
            - [External documentation about UFW and Ansible](#external-documentation-about-ufw-and-ansible)

<!-- /TOC -->

## ALB components

- **To permanently enable management by ALB for ALL components (default)**
  - `alb_manange_all: yes`
- **To permanently disable management by ALB for ALL components**
  - `alb_manange_all: no`

---

**TL;DR on ALB Components**

- The most important components to run the [ALB Apps](#apps) are
[OpenResty](#openresty) <sup>(strong requeriment; installed by default)</sup> and
[HAProxy](#haproxy) <sup>(recommended suggestion, but optional; installed by default)</sup>.
  - Note that some ALB Components actually **are** designed to run fine even
    without [ALB Apps](#apps) / [OpenResty](#openresty) / [HAProxy](#haproxy).
    - Notable example is [UFW](#ufw) and bootstrap case would be a database server.
- The next important ALB Component is [UFW](#ufw)
<sup>(situational recommended suggestion; NOT enabled by default to mitigate
CharlieFoxtrots)</sup>. Consider enable when:
  - Your cloud provider (at least for the package you are paying) does not have
    better solution
    - Or if have, you do not want cloud vendor lock-in
  - You do not have better solutions using Ansible and are OK with the [UFW](#ufw)
    defaults.

For full details, check [defaults/main.yml](defaults/main.yml). The main part
for a overview is:

```yaml
### AP-ALB Components overview _________________________________________________
# The defaults of v0.7.4+ will use: Apps, HAProxy, Logrotate, OpenResty
# You can enable/disable components. Or explicity enforce on your configuration
alb_manange_all: yes
alb_manange_haproxy: yes
alb_manange_openresty: yes
alb_manange_ufw: no

## Sanity Check run at very beginning
alb_manange_sanitycheck: yes

## Note: the next options is better leave it alone
alb_manange_apps: "{{ alb_manange_openresty }}"
alb_manange_logrotate: "{{ alb_manange_openresty or alb_manange_apps }}"

```

---

### Shared options

- :information_source: [defaults/main.yml](defaults/main.yml)
  - _"AP-ALB Components: shared options"_ section
- :information_source: [vars/main.yml](vars/main.yml)
  - Some components may use variables that are not on defaults, like
    `alb_trusted_hosts: "{{ alb_dmz + alb_bastion_hosts }}"`.
    This may be the second place to review for security issues on your context.

**Shared options** are how we call variable conventions that could be used as
default option to improve more specific ALB Components or your own custom
implementation.

#### ACME

These options are re-used by components that manange Automatic Certificate
Management Environment (ACME). See [ACME on Wikipedia](https://en.wikipedia.org/wiki/Automated_Certificate_Management_Environment)
and [RFC 8555](https://tools.ietf.org/html/rfc8555).

```yaml
### AP-ALB ACME ________________________________________________________________
# BY USING Let's Encrypt, even if automated for you, you AGREE with
# Let’s Encrypt Subscriber Agreement at https://letsencrypt.org/repository/

alb_acme_production: true

alb_acme_rule_ips_allowed: false # ACME (Let's Encript at least) will HTTPS for IPs, so don't even try

# Exact match
alb_acme_rule_whitelist: []
alb_acme_rule_whitelist_file: '' # not implemented... yet
alb_acme_rule_blacklist: []
alb_acme_rule_blacklist_file: '' # not implemented... yet

# Suffix match (e.g. for subdomains) and prefix match (e.g. if any full domain, if start with these values)
alb_acme_rule_whitelist_suffix: []
alb_acme_rule_whitelist_prefix: []
alb_acme_rule_blacklist_suffix: []
alb_acme_rule_blacklist_prefix: []

# alb_acme_rule_lua inject custom lua inside GUI/lua-resty-auto-ssl allow_domain function.
alb_acme_rule_lua: |
  -- FILE: /usr/local/openresty/nginx/conf/nginx.conf
  -- NGINX CONTEXT: http/init_by_lua_block/auto_ssl:set("allow_domain", function(domain)
  -- See https://github.com/GUI/lua-resty-auto-ssl
  -- Note 1: Inside lua blocks (like this one) "--" is used for start comments
  --       and not "#"
  -- Note 2: your custom code should 'return true' or 'return false'

# alb_acme_rule_last define your "default" behavior for what was not explicitly
# whitelisted/blacklisted
alb_acme_rule_last: true

# This value is infered from alb_acme_production. But you can customize yourself
alb_acme_url: "{{ 'https://acme-v02.api.letsencrypt.org/directory' if alb_acme_production else 'https://acme-staging-v02.api.letsencrypt.org/directory' }}"

```
#### Applications/Sysapplications variables

Content moved to [../rules/index.md](../rules/index.md).

#### Autentication Credentials

- :information_source: `password` fields are expected to have plaintext when
  executed via Ansible
  - **but you can use Ansible Valt to decrypt these passwords at run time**
    - <https://docs.ansible.com/ansible/latest/user_guide/vault.html>
    - and then commit on your git repository
- :warning: `alb_auth_*` is meant to be used for **host level / system level**
  related autentication credentials.
  - :+1: good usage: HAProxy status page, Basic Auth for your internal systems
  - :-1: bad usage: ~default for end user autentication for their private pages~ (think `app_auth_*`)

```yaml
alb_auth_users:
  - username: Admin1
    password: "plain-password"
  - username: Admin2
    password: "plain-password2"
  - username: "old-user-that-should-be-removed"
    password: "anotheranotherpass"
    state: absent
  - username: SuperUser2
    password: !vault |
      $ANSIBLE_VAULT;1.1;AES256
      62313365396662343061393464336163383764373764613633653634306231386433626436623361
      6134333665353966363534333632666535333761666131620a663537646436643839616531643561
      63396265333966386166373632626539326166353965363262633030333630313338646335303630
      3438626666666137650a353638643435666633633964366338633066623234616432373231333331
      6564
```

#### Bastion Hosts
- About Bastion Hosts: <https://en.wikipedia.org/wiki/Bastion_host>
- :information_source: Both [Bastion Hosts](#bastion-hosts) and [Jump Server](#jump-server)
  (but NOT [DMZ (DeMilitarized Zone)](#dmz-demilitarized-zone)), since some
  implementations could not even ask passwords) are good candidates for you add
  some host from outside, like a trusted server from the same client or other
  you own plus your own dinamic IP adress of your local machine.

```yaml
alb_bastion_hosts:
  - ip: 192.0.2.255
    name: "My Bastion Host"
```

#### DMZ (DeMilitarized Zone)
- About DMZ: <https://en.wikipedia.org/wiki/DMZ_(computing)>
- :warning: **`alb_dmz` is expected to only have trusted IPs or IPs ranges** (think almost equivalent to localhost access)
  - ALB/UFW if enabled by default will allow all traffic FROM/TO these IPs.
  - ALB/HAproxy Stats page if enabled by default will consider this as trusted

```yaml
alb_dmz:
 - ip: 203.0.113.1
   name: my_apps_server
 - ip: 203.0.113.2
   name: my_db_server
 - ip: 203.0.113.3
   name: any_other_server_inside_the_network
```

#### Jump Server
- About Jump Server: <https://en.wikipedia.org/wiki/Jump_server>
- :information_source: Both [Bastion Hosts](#bastion-hosts) and [Jump Server](#jump-server)
(but NOT [DMZ (DeMilitarized Zone)](#dmz-demilitarized-zone), since some
implementations could not even ask passwords) are good candidates for you add
some host from outside, like a trusted server from the same client or other
you own plus your own dinamic IP adress of your local machine.

```yaml
alb_jump_boxes:
  - ip: 192.0.2.10
    name: "my jumpbox server"
```

### Apps

> Tip: `apps` requires [OpenResty](#openresty).

- **To permanently enable management by ALB <sup>(default)</sup>**
  - `alb_manange_apps: yes`
    - `alb_manange_openresty: yes` <sup>(Charlie Foxtrot when not enabled)</sup>
- **To permanently disable management by ALB**
  - `alb_manange_apps: no`
- **Check Mode ("Dry Run"): only test changes without applying**
  - `--tags alb-apps --check`
  - Example: `ansible-playbook -i hosts main.yml --tags alb-apps --check`
- **To temporarily only execute ALB/Apps tasks**
  - `--tags alb-apps`
  - Example: `ansible-playbook -i hosts main.yml --tags alb-apps`
- **To temporarily only skips ALB/Apps tasks**
  - `--skip-tags alb-apps`
  - Example: `ansible-playbook -i hosts main.yml --skip-tags alb-apps`

For simplification each _group of rules_ is called "app" because most of the
time this is the case. The parameter `app_alb_strategy` defines wich [OpenResty
configuration template](templates/alb-strategy) will be used as base to
generate each file on `/opt/alb/apps/{{ app_uid }}.conf`.

> Protip: if you already have experience editing NGinx configurations, the way
AP-ALB automate the work for you will be very familiar.

#### ALB Strategies

**For full list of ALB Strategies, look at [templates/alb-strategy](templates/alb-strategy)**

##### files-local
Strategy to serve static files from the same server where the ALB is located.

```yaml
    alb_apps:

      - app_uid: "static-files"
        app_domain: "assets.example.org"
        app_root: "/var/www/html"
        app_forcehttps: yes
        app_alb_strategy: "files-local"
```
See [templates/alb-strategy/files-local.conf.j2](templates/alb-strategy/files-local.conf.j2).

##### hello-world

Hello world is a simple strategy to test one App/Sysapp. It can be specially
useful to obtain SSL Certificates or already have some placeholder.

If `app_debug: true` or `alb_forcedebug: yes` it can be used to give more
information.

```yaml
    alb_apps:

      - app_uid: "hello-world"
        app_domain: "debug.example.org"
        app_domain_extras:
          - hello-world.example.com
          - hello-world.*
        app_debug: true
        app_alb_strategy: "hello-world"
```

See [templates/alb-strategy/hello-world.conf.j2](templates/alb-strategy/hello-world.conf.j2).

##### minimal

The `app_alb_strategy: minimal` is not as raw as the [raw](#raw), but is the
last step before what is given by [files-local](#files-local) or
[proxy](#proxy). Some applications could require so much fine tunning that is
just simpler to give access to you implement [app_alb_raw](#app_alb_raw) and/or
[app_alb_raw_file](#app_alb_raw_file), **BUT** all other configurations, like
paths to load balancer, logs, Automatic HTTPS, etc be handled for you.

```yaml
    alb_apps:
      - app_uid: "hello-world-minimal"
        app_domain: "hello-world-minimal.{{ ansible_default_ipv4.address }}.nip.io"
        app_alb_strategy: "minimal"
        app_alb_raw_file: "templates/example_app_alb_raw_file.conf.j2"
        app_alb_raw: >
          charset_types application/json;
          default_type application/json;

          location = /status {
              stub_status;
              allow all;
          }
          location = /ping {
              access_log off;
              return 200 "pong\n";
          }
          location = / {
              content_by_lua_block {
                 local cjson = require "cjson"
                 ngx.status = ngx.HTTP_OK
                 ngx.say(cjson.encode({
                     msg = "Hello, hello-world-minimal! (from app_alb_raw)",
                     status = 200
                 }))
              }
          }
```

See [templates/alb-strategy/hello-world.conf.j2](templates/alb-strategy/minimal.conf.j2).

##### proxy
Use ALB as reverse proxy.

```yaml
    alb_apps:

      - app_uid: "minio"
        app_domain: "minio.example.org"
        app_alb_strategy: "proxy"
        app_forcehttps: yes
        app_alb_proxy: ":::9091"
```
See [templates/alb-strategy/proxy.conf.j2](templates/alb-strategy/proxy.conf.j2).

##### raw
`raw` strategy is similar to [minimal](#minimal), but you have full control
using [app_alb_raw](#app_alb_raw) and/or [app_alb_raw_file](#app_alb_raw_file).

This strategy can be specially useful on upgrades of AP-ALB where new
configurations could break some old functionality and you have no time to make
the new upgrades for some specific app.

### Bootstrap
- **To permanently enable management by ALB<sup>(default)</sup>**
  - `alb_manange_bootstrap: yes`
- **To permanently disable management by ALB**
  - `alb_manange_bootstrap: no`
- **Check Mode ("Dry Run"): only test changes without applying**
  - `--tags alb-bootstrap --check`
    - Example: `ansible-playbook -i hosts main.yml --tags alb-bootstrap --check`

<!--

This ALB group of tasks have 3 responsabilities:

1. If a node does not even have python installed, if you run with
  `gather_facts: no`, it will do a dirty raw checking and, if need, will install
  python for you. Then it will abort the play and ask you to allow
  `gather_facts` because of other modules will require.
2. (independent of `alb_manange_*` ) Based on your operational system
  boostrap mode will install some generic packages that you very likely would
  want
    - This step may make some checks, like if you by acident tried to run
      against one server that already is running some application on port :80
      or :443 and it was not created by AP-ALB. **Then it will abort the
      process**.
      - Think, for example, if running this agains one WHM server, ISPConfig,
        some Kubernetes cluster, etc. It will abort and require you add
        undocumented variables to force the boostraping continue
      - Think that one functionalities of AP-ALB is export or import
        applications from other hosting services
    - _TODO: add details later (fititnt, 2019-12-07 00:05 BRT)_
3. (based on `alb_manange_*: yes` and `alb_manange_*_repository: yes`) it
  based on what ALB components will be managed on other group of tasks, and
  if you operational system does not seems to have ideal repository to get
  the HAProxy/OpenResty, etc, it will add new repositories to your system.
4. (based on `alb_manange_*: yes`) if the ALB Components are enabled require
  the full directory structure (think folders for OpenResty/Apps/SysApps
  configurations and access logs) this step will create all directory structure
  of AP-ALB.
  - Note: this step may also do actions on server boostraped by older versions
    of AP-ALB.
5. Then, if it will mark you server as bootstraped. By default it will not try
  to do any of these tasks again at least until AP-ALB Role was upgraded.

-->

#### Bootstrap Python installation
- **Tested Operational Systems**:
  - CentOS 7, CentOS 8
  - Debian: 10
  - FreeBSD 12
  - Ubuntu: 18.04

Ansible requires Python (better if is Python3) and for very new hosts, you may
get this error message: _"the module failed to execute correctly you probably
need to set the interpreter"_.

This means that you need to manually install python on your target hosts.
**BUT** you can use AP-ALB to use try [raw – Executes a low-down and dirty
command](https://docs.ansible.com/ansible/latest/modules/raw_module.html)
and do it for you.

Check [example/bootstrap-even-python.yml](example/bootstrap-even-python.yml)
for more details. It's not necessary (and not recommended) leave
`alb_boostrap_python: "force"` saved on playbooks, since this part in special
of the ALB/Bootstrap have very limited safety checks if you missuse. You can
temporaly use via CLI extra commands, like this:

```bash
ansible-playbook my-playbook-with-gather_facts-false.yml -i example.org, -e='alb_boostrap_python=force'
```

Note, if even this fails, do it manually.

### HAProxy

- **To permanently enable management by ALB <sup>(default)</sup>**
  - `alb_manange_haproxy: yes`
- **To permanently disable management by ALB**
  - `alb_manange_haproxy: no`
- **Check Mode ("Dry Run"): only test changes without applying**
  - `--tags alb-haproxy --check`
  - Example: `ansible-playbook -i hosts main.yml --tags alb-haproxy --check`
- **To temporarily only execute ALB/HAProxy tasks**
  - `--tags alb-ufw`
  - Example: `ansible-playbook -i hosts main.yml --tags alb-haproxy`
- **To temporarily only skips ALB/HAProxy tasks**
  - `--skip-tags alb-haproxy`
  - Example: `ansible-playbook -i hosts main.yml --skip-tags alb-haproxy`

Please check [NLB Internals](nlb-internals.md) <sup>(working draft)</sup>.

#### HAProxy stats page

- **To permanently enable management by ALB**
  - `alb_haproxy_stats_enabled: yes`
    - `alb_manange_haproxy: yes` <sup>(HAProxy Stats depends of HAProxy)</sup>
- **To permanently disable management by ALB <sup>(default)</sup>**
  - `alb_haproxy_stats_enabled: no`


Please also check Check [defaults/main.yml](defaults/main.yml) section
`# AP-ALB Component: HAProxy | HAProxy Stats`.

Here a full example that will make you access HAProxy Status page from a host
example.com at <http://example.com:8404/haproxy?stats> from very specific IPs
and requiring user and passwords from `alb_auth_users`.

```yaml
alb_manange_haproxy: yes

alb_haproxy_stats_enabled: yes
alb_haproxy_stats_ip: 0.0.0.0 # 0.0.0.0 means exposed for everyone. Use firewall!
alb_haproxy_stats_port: 8404
alb_haproxy_stats_uri: "/haproxy?stats"
alb_haproxy_stats_realm: "{{ alb_name }}: {{ inventory_hostname }}"

# If informed, HAProxy Stats page will allow access from alb_trusted_hosts_ips:
# (localhost + alb_dmz + alb_bastion_hosts) [Does not include alb_jump_boxes]
alb_dmz:
  - ip: 167.86.127.220
    name: apps_server_apalbdemo
  - ip: 167.86.127.225
    name: db_server_apalbdemo
alb_bastion_hosts:
  - ip: 177.126.157.169
    name: aguia-pescadora-delta.etica.ai

# If informed, HAProxy Stats page will require require user and password from alb_auth_users
alb_auth_users:
  - username: Admin1
    password: "plain-password"
  - username: Admin2
    password: "plain-password2"
  - username: SuperUser2
    password: !vault |
      $ANSIBLE_VAULT;1.1;AES256
      62313365396662343061393464336163383764373764613633653634306231386433626436623361
      6134333665353966363534333632666535333761666131620a663537646436643839616531643561
      63396265333966386166373632626539326166353965363262633030333630313338646335303630
      3438626666666137650a353638643435666633633964366338633066623234616432373231333331
      6564


# As ALB 0.7.4, without further customizations, if both alb_trusted_hosts_ips
# and alb_auth_users are provided, even from these IPs you is required to
# provide a password
```

> Security information: Even if you do not have [UFW](#ufw) enabled and forgot
to setup your own firewall (or use one from your cloud privider) the default
behavior of ALB stats page is still require the result of `alb_trusted_hosts_ips`
(this result is defined on [vars/main.yml](vars/main.yml)).

#### HAProxy TLS Termination

At least for the ALB v0.6.1-alpha we do not provice automated way to implement
automatic HTTPS using only HAProxy. We implement using
[lua-resty-auto-ssl](#lua-resty-auto-ssl).

Still possible to do it but you will need to implement additional logic.

### Logrotate
Logrotate is enabled by default on [defaults/main.yml](defaults/main.yml) when
`alb_manange_openresty: yes` or `alb_manange_apps: yes`.

You can selectively disable with `alb_manange_logrotate: no`, but would be
recommended implement your own log strategy.

Check [tasks/logrotate/logrotate.yml](tasks/logrotate/logrotate.yml).

### OpenResty

- **To permanently enable management by ALB**
  - `alb_manange_openresty: yes`
- **To permanently disable management by ALB**
  - `alb_manange_openresty: no`
- **Check Mode ("Dry Run"): only test changes without applying**
  - `--tags alb-openresty --check`
  - Example: `ansible-playbook -i hosts main.yml --tags alb-openresty --check`
- **To temporarily only execute ALB/OpenResty tasks**
  - `--tags alb-ufw`
  - Example: `ansible-playbook -i hosts main.yml --tags alb-openresty`
- **To temporarily only skips ALB/OpenResty tasks**
  - `--skip-tags alb-openresty`
  - Example: `ansible-playbook -i hosts main.yml --skip-tags alb-openresty`

Please check [ALB Internals](alb-internals.md).

#### Run OpenResty without HAProxy

> Strong suggestion: the memory footprint of using HAproxy in front of OpenResty
> is not a good reason to not leave enabled.

OpenResty, out of the box, have default values assuming [HAProxy](#haproxy)
is installed on the same host in front. If want to change this behavior,
consider change **at least** these variables from the defaults on
[defaults/main.yml](defaults/main.yml):

```yaml
alb_manange_haproxy: no
alb_openresty_ip: 0.0.0.0
alb_openresty_httpport: 80
alb_openresty_httpsport: 443
```

#### lua-resty-auto-ssl

[GUI/lua-resty-auto-ssl](https://github.com/GUI/lua-resty-auto-ssl) used with
[OpenResty](#openresty) to allow Automatic
HTTPS on-the-fly.

See [Shared Option: ACME](#acme) to see rules that affect this implementation.

### SanityCheck
- **To permanently enable management by ALB (default)**
  - `alb_manange_sanitycheck: yes`
- **To permanently disable management by ALB**
  - `alb_manange_sanitycheck: no`

This ALB component (enabled by default) will run at very start of a play and
try to do some very basic sanity checks that have a tendency to cause a
node or a [entire cluster to enter on a non-operational state](https://en.wiktionary.org/wiki/clusterfuck)
via human mistakes on ALB configurations.

### Status
> This **mode is safe run**, and can be used even in **Check Mode ("Dry Run")**
> with `--check` parameter. It's also expected (and you will be informed) that
> some checks will soft fail (like trying to check `alb_apps.facts`) on a node
> that does not have apps.

```bash
# Note: by default the standard status checks are always run at the end of a
#       successful. This may slow down your run, but we're consider a good
#       default.

#       BUT you may have a system so broken that not even the status checks
#       will start or you want call it directly

# This skips other steps and go diretly to minimal status checks
ansible-playbook playbook.yml -i hosts.yml --check --tags="alb-status"

# TODO: implement a mode even more verbose:
ansible-playbook playbook.yml -i hosts.yml --check --tags="alb-status-full"
```


### Sysapps
`Sysapps` implement near the same options than [Apps](#apps), but their focus
is namespace apps that are not intended for end user usage. The adantages
of this is apply default access control for all sysapps and also when running
very large deployment you could choose run only the Apps or the Sysapps rules.

```yaml

    # alb_sysapps_default not implemented yet
    alb_sysapps_default:
      app_forcehttps: no
      app_basicauth_file: "/opt/alb/sysapps/.htaccess"

    # If defined, will create /opt/alb/sysapps/.htaccess just once
    alb_sysapps_htpassword : "{{ alb_auth_users }}"

    alb_sysapps:
      - app_uid: "consul"
        app_domain: "consul.{{ ansible_default_ipv4.address }}.nip.io"
        app_domain_extras:
          - consul.*
        app_alb_strategy: "proxy"
        app_forcehttps: no
        app_alb_proxy: "http://127.0.0.1:8500"

      - app_uid: "haproxy"
        app_domain: "haproxy.{{ ansible_default_ipv4.address }}.nip.io"
        app_domain_extras:
          - haproxy.*
        app_alb_strategy: "proxy"
        app_alb_proxy: "http://127.0.0.1:{{ alb_haproxy_stats_port }}"
```

**New on v0.8.6-alpha**: internally ALB will merge `alb_sysapps_alb` +
`alb_sysapps_always` + `alb_sysapps` and `alb_app_always` + `alb_apps`. Ansible
default behavior when the same variable is defined default and then some hosts
also specify the variable is override. To make it easier for who want some
apps/sysapps be on all nodes on a datacenter (and to avoid you use advanced
features like `hash_behaviour` or implement plugins like
[leapfrogonline/ansible-merge-vars](https://github.com/leapfrogonline/ansible-merge-vars))
we suggest use as convention  `alb_sysapps_always` and `alb_app_always`.

#### ALB optionated sysapps

The variable `alb_sysapps_alb` if defined, will inject some sysapps before
`alb_sysapps_always` and `alb_sysapps`.

### UFW
> _To avoid acidental use, this feature is not enabled by default (and will
> **never** be on any future release). `alb_manange_ufw: yes` is explicitly
> required._

> _Protip: Check Mode ("Dry Run") with `--tags alb-ufw --check`. This will
 test changes **without** applying._

- **To permanently enable management by ALB**
  - `alb_manange_ufw: yes`
- **To permanently disable management by ALB** <sup>(Default)</sup>
  - `alb_manange_ufw: no`
- **Check Mode ("Dry Run"): only test changes without applying**
  - `--tags alb-ufw --check`
  - Example: `ansible-playbook -i hosts main.yml --tags alb-ufw  --check`
- **To temporarily only execute ALB/UFW tasks**
  - `--tags alb-ufw`
  - Example: `ansible-playbook -i hosts main.yml --tags alb-ufw`
- **To temporarily only skips ALB/UFW tasks**
  - `--skip-tags alb-ufw`
  - Example: `ansible-playbook -i hosts main.yml --skip-tags alb-ufw`

```yaml

# Allow ALB/UFW manage (required)
alb_manange_ufw: yes

# @see https://en.wikipedia.org/wiki/DMZ_(computing)
# ALB/UFW will use alb_dmz to make all traffic FROM/TO to this machine free
alb_dmz:
  - ip: 167.86.127.220
    name: apps_server_apalbdemo
  - ip: 167.86.127.225
    name: db_server_apalbdemo

# @see https://en.wikipedia.org/wiki/Bastion_host
# ALB/UFW will use alb_bastion_hosts to make all traffic FROM/TO to this machine free
# This behavior could change on future to make it more configurable
alb_bastion_hosts:
  - ip: 177.126.157.169
    name: aguia-pescadora-delta.etica.ai

# @see https://en.wikipedia.org/wiki/Jump_server
# ALB/UFW will use alb_jump_boxes to make all traffic FROM/TO to this machine free
# This behavior could change on future to make it more configurable
alb_jump_boxes:
  - ip: 192.0.2.10
    name: TEST-NET-1 (example IP)

```

#### Applying only firewall rules on a specific server (i.e. do not install HAProxy, OpenResty...)
Is possible to reuse the YAML syntax of AP-ALB to only configure firewall of a
server, without installing HAProxy, OpenResty, creating `/opt/alb/apps/` folders
etc.

This could be useful for database servers.

```yaml
# Works on ALB v0.6.1-alpha. Future versions may require other options disabled
alb_manange_haproxy: no
alb_manange_openresty: no
alb_manange_ufw: yes

# Use alb_ufw_rules, alb_dmz, alb_bastion_hosts, alb_jump_boxes etc
```

#### External documentation about UFW and Ansible

- Ansible documentation: <https://docs.ansible.com/ansible/latest/modules/ufw_module.html>
- UFW Introduction: <https://help.ubuntu.com/community/UFW>
- UFW Manual: <http://manpages.ubuntu.com/manpages/cosmic/en/man8/ufw.8.html>
