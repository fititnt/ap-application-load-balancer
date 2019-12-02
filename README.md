# Águia Pescadora Application Load Balancer (_"AP-ALB"_) - v0.8.0-alpha
AP-ALP is not a single software, but **[Infrastructure As Code](https://en.wikipedia.org/wiki/Infrastructure_as_code)
via [Ansible Role](https://docs.ansible.com/) to automate creation and maintance of
with features common on expensive _Application Load Balancer_ of some cloud
providers** (e.g. [Alibaba](https://www.alibabacloud.com/product/server-load-balancer),
[AWS](https://aws.amazon.com/elasticloadbalancing/),
[Azure](https://azure.microsoft.com/en-us/services/load-balancer/),
[GCloud](https://cloud.google.com/load-balancing/),
[IBM](https://www.ibm.com/cloud/load-balancer), etc). It can be used both to
create your own ALB on cheaper hardware on these same cloud providers or
have your own ALB on any other provider of VPSs or bare metal servers.

[![asciicast](https://asciinema.org/a/281411.svg)](https://asciinema.org/a/281411)
> Source code for this demo at <https://github.com/fititnt/ap-alb-demo/releases/tag/v0.6.4-beta>

<!--

All stack is open source software, yet our main choices **HAproxy** and
**OpenResty/NGinx** are very likely to be the ones some big cloud providers use.

**There is no vendor lock in**, not even as option on AP-ALB we do not enforce
any specific cloud provider: but you should already have 1+ VPSs or bare metals
able to execute Ansible playbooks (Ubuntu Server 18.04+ are more tested).
The AP-ALB [license is Public Domain](#License) and is ok if you or your company
use this role to create your own custom versions.

-->

<!--

> TL;DR: you can use this and other works from Emerson Rocha or Etica.AI as
reference (from underline tools to full use of Infrastructure As Code). But
since we can't make promisses of full backward compatibility and we're testing
in very specific scenarios **we're not only OK that you can copy the Ansible Role
and make you custom version, but strongly recommended strategy**. The brand
"Águia Pescadora" / "AP" / "ap-" are not used on internal code, so this code
base is very useful to reuse parts betwen projects and even rebrand for
humanitarian or commercial projects from who help we on Etica.AI.

-->

<!--Emerson Rocha dedicated this work to Public Domain -->

---

<!-- TOC depthFrom:2 -->

- [The Solution Stack of AP-ALB](#the-solution-stack-of-ap-alb)
    - [ALB Goals](#alb-goals)
        - [Automatic updates of components after deployed](#automatic-updates-of-components-after-deployed)
        - [Resilient to sysadmin errors on production servers](#resilient-to-sysadmin-errors-on-production-servers)
            - [What about one-click rollback feature?](#what-about-one-click-rollback-feature)
        - [Decoupled subcomponents when makes sense](#decoupled-subcomponents-when-makes-sense)
    - [ALB Non-Goals](#alb-non-goals)
        - [Custom end user graphical interface or no need of sudo to deploy proxy rules](#custom-end-user-graphical-interface-or-no-need-of-sudo-to-deploy-proxy-rules)
            - [Potential alternatives](#potential-alternatives)
- [Quickstart Guide](#quickstart-guide)
    - [The minimum you already should know to use AP-ALB](#the-minimum-you-already-should-know-to-use-ap-alb)
    - [Complete examples using AP-ALB](#complete-examples-using-ap-alb)
    - [Quickstart on how to hotfix/debug production servers](#quickstart-on-how-to-hotfixdebug-production-servers)
- [ALB components](#alb-components)
    - [Shared options](#shared-options)
        - [ACME](#acme)
        - [Autentication Credentials](#autentication-credentials)
        - [Bastion Hosts](#bastion-hosts)
        - [DMZ (DeMilitarized Zone)](#dmz-demilitarized-zone)
        - [Jump Server](#jump-server)
    - [Apps](#apps)
        - [ALB Strategies](#alb-strategies)
            - [hello-world](#hello-world)
            - [files-local](#files-local)
            - [proxy](#proxy)
            - [raw](#raw)
    - [Common](#common)
    - [HAProxy](#haproxy)
        - [HAProxy stats page](#haproxy-stats-page)
        - [HAProxy TLS Termination](#haproxy-tls-termination)
    - [Logrotate](#logrotate)
    - [OpenResty](#openresty)
        - [Run OpenResty without HAProxy](#run-openresty-without-haproxy)
        - [lua-resty-auto-ssl](#lua-resty-auto-ssl)
    - [SanityCheck](#sanitycheck)
    - [Sysapps](#sysapps)
    - [UFW](#ufw)
        - [Applying only firewall rules on a specific server (i.e. do not install HAProxy, OpenResty...)](#applying-only-firewall-rules-on-a-specific-server-ie-do-not-install-haproxy-openresty)
        - [External documentation about UFW and Ansible](#external-documentation-about-ufw-and-ansible)
- [Advanced usage](#advanced-usage)
    - [Lua](#lua)
    - [ALB Internals](#alb-internals)
    - [Risk mitigation](#risk-mitigation)
        - [Still use passwords for intra-cluster communications (We're looking at you, Redis, MongoDB...)](#still-use-passwords-for-intra-cluster-communications-were-looking-at-you-redis-mongodb)
        - [Should you use private networkig from my cloud provider? Should you implement IPSec/OpenVPN?](#should-you-use-private-networkig-from-my-cloud-provider-should-you-implement-ipsecopenvpn)
        - [Prefer guides that assume security requirements for geo-distributed applications](#prefer-guides-that-assume-security-requirements-for-geo-distributed-applications)
- [FAQ](#faq)
- [License](#license)

<!-- /TOC -->

---

## The Solution Stack of AP-ALB

> _One line emoji explanation_:
>
> ☺️ 🤖 :end: **UFW <sup>(:1-65535)</sup>** :end: **HAProxy <sup>(:80, :443)</sup>** :end: **OpenResty <sup>(:8080, :4443 🔒)</sup>** :end: **App**

- **Infrastructure as Code**:
  - [Ansible 2.8+](https://github.com/ansible/ansible) _(See: [Ansibe documentation](https://docs.ansible.com/))_
- **Operational System**:
  - [Ubuntu Server LTS 18.04+](https://ubuntu.com/)
- **Firewall**
  - [UFW](https://help.ubuntu.com/community/UFW)
- **Load Balancing**
  - [HAProxy 2.0.x](https://github.com/haproxy/haproxy)
    _(See: [HAProxy starter guide](https://cbonte.github.io/haproxy-dconv/2.0/intro.html),
    [HAProxy Configuration Manual](https://cbonte.github.io/haproxy-dconv/2.0/configuration.html),
    [HAProxy Management Guide](https://cbonte.github.io/haproxy-dconv/2.0/management.html))_
  - [OpenResty](https://openresty.org) _(See: [NGINX Wiki!](https://www.nginx.com/resources/wiki/))_
- **Automatic HTTPS**
  - [GUI/lua-resty-auto-ssl](https://github.com/GUI/lua-resty-auto-ssl)
  - [Let’s Encrypt](https://letsencrypt.org/docs/)
- **The Apps/Rules configuration**
  - [YAML Syntax](https://yaml.org/)
    - [OpenResty](https://yaml.org/) / [NGinx](http://nginx.org/en/docs/) syntax <sup>(To make your own YAML template apps)</sup>
      - TL;DR: `/opt/alb/apps/{{ app_uid }}.conf` is where each App/Rule is stored
    - [HAProxy](https://yaml.org/) <sup>(Only for very advanced cases)</sup>

> See [Advanced usage](#advanced-usage).

### ALB Goals

#### Automatic updates of components after deployed

The AP-ALB Infrastructure as Code written in Ansible can be labeled as `beta` or
`Release Candidate` but **the end result is aimed to be running non-stop in
production at least with security updates without human intervention**.

**Who guarantees updates:**
- **HAProxy 2.0**:
  - _Note: version **haproxy=2.0.\*** is locked_
  - <https://haproxy.debian.net/#?distribution=Ubuntu&release=bionic&version=2.0>
- **OpenrResty**: 
  - We use OpenResty® provides official pre-built packages
  - <https://openresty.org/en/linux-packages.html>
- **Automatic HTTPS**
  - GUI/lua-resty-auto-ssl
    - We use OpenrResty package mananger
    - `luarocks install lua-resty-auto-ssl`
  - At moment we do not provide out of the box HTTPS using only HAProxy
    - Trust me. We do not found ways to automate Automatic HTTPS with HAProxy.
      to not require some level of human interation from time to time.
- **UFW**
  - Default from the system

If you manage make the initial setup with ALB works and just to be sure reboot
at least once, _is likely that if you forgot your server running it could be
working fine untill [Ubuntu Server EOLs](https://ubuntu.com/about/release-cycle)
(e.g. if Using Ubuntu 18.04 LTS could be 2023 or 2028)_.

#### Resilient to sysadmin errors on production servers

ALP do it's best to not stop services even when the administrator deploy invalid
configurations on production.

A human can be so self-confident (or not knowing the difference) and after
updating configurations on production instead of _reload a service_ go ahead and
_restart a service_. Sometimes is not only about packat loss (user or external
services receiving errors for a second) but with configuration errors will stop
an online service.

##### What about one-click rollback feature?

Note that we do not support [`one-click rollback` Ansistrano-like style](https://github.com/ansistrano/deploy)
... **yet**.

HAProxy & OpenResty is likely to resist errors, and have backup
files for every old configuration on the target servers, but if you use custom
configurations beyond what ALB is designed, you still will need to log on the
server and rename older files or re-run a playbook with ALB to allow fix it.

#### Decoupled subcomponents when makes sense
See [ALB components](#alb-components).

### ALB Non-Goals
> **non-goal** (plural non-goals)
> A potential goal or requirement which is explicitly excluded from the scope of a project.
> [wiktionary for non-goal](https://en.wiktionary.org/wiki/non-goal)

#### Custom end user graphical interface or no need of sudo to deploy proxy rules
One of the big features of Load Balancers of big cloud providers is that they
have some way (like a web interface) for a user create their rules. Is possible
to make this for ALB, our target audience very likely is doing an ALB for
themselves and would have root access anyway on some cheap VPSs.

##### Potential alternatives

- **ALB + AWX Project (Ansible tower open source)**
  - AWX Project allows granular access when deploying changes with Ansible.
  - <https://github.com/ansible/awx>
  - <https://docs.ansible.com/ansible-tower/index.html>
- **ALB + Tsuru** (or any other PaaS)
  - Tsuru, years before Kubernetes was a thing, already allowed deploy apps
    similar to what Heroku does. You could only use the Auto HTTPS from ALB,
    use App rules for thinkgs that you really want control, and everyting else
    proxy to Tsuru.
  - <https://tsuru.io/>

## Quickstart Guide

### The minimum you already should know to use AP-ALB

> Note: this guide assumes that you at least
>
> 1. **Have Ansible installed on some computer**
>     1. [https://docs.ansible.com: Installation Guide](https://docs.ansible.com/ansible/latest/installation_guide/index.html)
>     2. Tip: if is your first time with Ansible, this computer is likely to be
>        own computer and NOT the server where you want to install ALB
> 2. **Have at least one VPS or Bare metal VPS that can be controlled by your
>    installation Ansible**
> 3. **Have basic knowledge on how to use Ansible Playbooks**
>     1. [https://docs.ansible.com: Working With Playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks.html)
>     2. Hint: `ap-application-load-balancer` can be imported as a Ansible Role, but
>       it is not released on Ansible Galaxy (it means you can copy some version of
>       AP-ALB and place on sub-folder `roles/ap-application-load-balancer`)

### Complete examples using AP-ALB
- [example/playbook-basic.yml](example/playbook-basic.yml)
- [example/playbook-complex.yml](example/playbook-complex.yml)
- <https://github.com/fititnt/ap-alb-demo>

### Quickstart on how to hotfix/debug production servers
See [debugging-quickstart.md](debugging-quickstart.md).

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
    - Notable example is [UFW](#ufw) and common case would be a database server.
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

## Optionated (but NOT required) group of tasks.
alb_manange_common: no  # hostname, timezone (UTC) [See tasks/common/common.yml]

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
alb_acme_production: true
alb_acme_rule_whitelist: []
alb_acme_rule_whitelist_file: '' # not implemented... yet
alb_acme_rule_blacklist: []      # not implemented... yet
alb_acme_rule_blacklist_file: '' # not implemented... yet
alb_acme_rule_last: true

# This value is infered from alb_acme_production. But you can customize yourself
alb_acme_url: "{{ 'https://acme-v02.api.letsencrypt.org/directory' if alb_acme_production else 'https://acme-staging-v02.api.letsencrypt.org/directory' }}"
```


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

##### hello-world

The `hello-world` replaced [files-local](#files-local) strategy as default if
you do not specify a `app_alb_strategy`. It can be specially useful to obtain
SSL Certificates or already have some placeholder.

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
Use a raw string to create an OpenResty configuration file.

```yaml
    alb_apps:

      - app_uid: "myrawconfiguration"
        app_alb_strategy: "raw"
        app_raw_conf: |
          #
          # Th content of app_raw_conf variable will be saved on the file
          # /usr/local/openresty/nginx/conf/sites-enabled/myrawconfiguration.conf
          #

```

See [templates/alb-strategy/raw.conf.j2](templates/alb-strategy/raw.conf.j2).

### Common

- **To permanently enable management by ALB**
  - `alb_manange_common: yes`
- **To permanently disable management by ALB <sup>(default)</sup>**
  - `alb_manange_common: no`
- **Check Mode ("Dry Run"): only test changes without applying**
  - `--tags alb-common --check`
  - Example: `ansible-playbook -i hosts main.yml --tags alb-common  --check`

This optionated package is enabled by default and is not a requeriment.

Check [tasks/common/common.yml](tasks/common/common.yml).

### HAProxy

- **To permanently enable management by ALB <sup>(default)</sup>**
  - `alb_manange_haproxy: yes`
- **To permanently disable management by ALB**
  - `alb_manange_haproxy: no`
- **Check Mode ("Dry Run"): only test changes without applying**
  - `--tags alb-openresty --check`
  - Example: `ansible-playbook -i hosts main.yml --tags alb-haproxy --check`
- **To temporarily only execute ALB/HAProxy tasks**
  - `--tags alb-ufw`
  - Example: `ansible-playbook -i hosts main.yml --tags alb-haproxy`
- **To temporarily only skips ALB/HAProxy tasks**
  - `--skip-tags alb-openresty`
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

### Sysapps
> This feature still a draft (fititnt, 2019-12-02 14:25 BRT)

`Sysapps` implement near the same options than [Apps](#apps), but their focus
is namespace apps that are not intended for end user usage. The adantages
of this is apply default access control for all sysapps and also when running
very large deployment you could choose run only the Apps or the Sysapps rules.

```yaml
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

## Advanced usage

### Lua

Lua is fantastic language! Is actually easier to lean Lua and implement some
advanced rules than push Apache/Nginx configurations too much.

- Learn Lua in 15 Minutes (text): http://tylerneylon.com/a/learn-lua/
- Learn Lua in an Hour (video): https://www.youtube.com/watch?v=S4eNl1rA1Ns
- Lua 5.1 short
reference: <http://lua-users.org/files/wiki_insecure/users/thomasl/luarefv51.pdf>
- Lua Online compiler: <https://repl.it/languages/lua>

Tip: you very likely will use Lua 5.1, because is the supported version of
LuaJIT (it means is faster and with more support).

### ALB Internals

See [ALB Internals](alb-internals.md) <sup>(working draft)</sup>.

### Risk mitigation
> _"Layered security, also known as layered defense, describes the practice of
combining multiple mitigating security controls to protect resources and data."
— [Layered security on Wikipedia](https://en.wikipedia.org/wiki/Layered_security)_

<!--
This section applies in special if you is using ALB/UFW component (or any custom
solution based only on [IPTables firewall](http://ipset.netfilter.org/)) as a
layer of defence **inside** your servers not meant to be exposed to the public
internet instead of private networking.
-->

AP-ALB, as one Infrastructure as Code way to implement a single or a clustered
servers to work as Application Load Balancers, is designed to work with
_aceptable risks_ without rely on some features that are not available on
**very cheap VPSs without enterprise features** (like private networking,
extra disks, snapshots) and **still relatively sysadmin (user) friendly** for
what it is really doing. By extension, this also means it will work with mixed
setups (e.g. some VPSs could be on expensive AWS, while others on other cloud
providers, like Azure, or cheaper but very good ones, like Contabo).

<!--
This [Risk mitigation](#risk-mitigation) topic contain some informations that
either could improve your setup if is getting more complex or 
-->

#### Still use passwords for intra-cluster communications (We're looking at you, Redis, MongoDB...)
**TL;DR: if a software support autentication with AP-ALB you SHOULD implement
this layer of defence even if and 80% of guides on internet teach how to use
without.** This is not a strong requeriment if you is using AP-ALB inside
the same region of cloud provider with support for private networking or you
implement IPSec/OpenVPN, but even on this cases still better already have your
services ready to expand and avoid human error with future misconfigurations.

Some softwares in special (like Redis and MongoDB) tend to have friendly guides
that will work securely (securely as _"from outside attacks, not from errors
inside your network"_) without need of authentication. There are so many things
that can go wrong that the overhead of performance the need of authentication
and extra steps on your scripts are not plausible excuses.

Even if the AP-ALB does not manange your service on another VPS, you may
eventually want to use HAProxy to load balance a service that is not on
localhost, but on that VPS. And the easyers ways to do this _are likely to
go [charlie-foxtrot](https://en.wiktionary.org/wiki/clusterfuck)_.

#### Should you use private networkig from my cloud provider? Should you implement IPSec/OpenVPN?
**TL;DR: not required, but is a good idea if you can.**

If some of your hosts are on a cloud provider that you already have option to
have extra firewalls or private networking inside the VPSs on that region, yes
that's a good idea. You already paid, use it.

About implement IPSec/OpenVPN or equivalent to do Software-Defined Networking,
it's up to you, but since it can be not trivial to implement, we try to not
depent on this implementation. As `ALB v0.8.0-alpha` we do not have Components
to automate creation of private network, but you could still use the
[Shared options](#shared-options) or do the initial setup without Ansible
automation.

#### Prefer guides that assume security requirements for geo-distributed applications
**TL;DR: This last topic on Risk mitigation is for where you can find relevant information.**

**Do not assume same level of security of private networking and same
datacenter**: the averange guide on internet (in special the ones from cloud
providers) will assume both cases and sometimes they are so resilient on this
feature that will suggest no autentication at all for intra-cluster
communication even when the underlines softwares allow and strongly encourage
it's use.

One generic protip here is, when in doubt with guides, check the same guides
but with _"geo-distributed applications/replication"_ or _"multicloud"_. Even
if you do not implement IPSec or OpenVPN, the averagen guide on how to configure
the applications will very likely to still rely on autentication for the apps
that need to talk with each other.

<!--

> Tip: OpenResty allow usage of LuaJIT. You can test lua language online at
<https://www.lua.org/cgi-bin/demo>

-->

## FAQ

- _Which version of AP-ALB should you use?_
  - **Choose at [ap-application-load-balancer/releases](https://github.com/fititnt/ap-application-load-balancer/releases)**.
    You can use the master branch, but we recommend review new updates.
    ALB is meant to be used non-stop on production servers, so you can stick
    with some version or maintain your own private changes.
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

## License
[![Public Domain](https://i.creativecommons.org/p/zero/1.0/88x31.png)](UNLICENSE)

To the extent possible under law, [Etica.AI](https://etica.ai/) has waived all
copyright and related or neighboring rights to this work to
[Public Domain](UNLICENSE).
