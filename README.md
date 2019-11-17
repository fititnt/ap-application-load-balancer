# Águia Pescadora Application Load Balancer (_"AP-ALB"_) - v0.7.0-alpha
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
- [Quickstart Guide](#quickstart-guide)
    - [The minimum you already should know to use AP-ALB](#the-minimum-you-already-should-know-to-use-ap-alb)
    - [Complete examples using AP-ALB](#complete-examples-using-ap-alb)
    - [Quickstart on how to hotfix/debug production servers](#quickstart-on-how-to-hotfixdebug-production-servers)
- [ALB components](#alb-components)
    - [Apps](#apps)
        - [ALB Strategies](#alb-strategies)
            - [hello-world](#hello-world)
            - [files-local](#files-local)
            - [proxy](#proxy)
            - [raw](#raw)
            - [socket-php](#socket-php)
    - [Common](#common)
    - [DevTools](#devtools)
        - [hatop](#hatop)
        - [htop](#htop)
        - [multitail](#multitail)
        - [netstat](#netstat)
    - [HAProxy](#haproxy)
        - [HAProxy stats page](#haproxy-stats-page)
        - [HAProxy TLS Termination](#haproxy-tls-termination)
    - [Logrotate](#logrotate)
    - [OpenResty](#openresty)
        - [Run OpenResty without HAProxy](#run-openresty-without-haproxy)
        - [lua-resty-auto-ssl](#lua-resty-auto-ssl)
    - [UFW](#ufw)
        - [Applying only firewall rules on a specific server (i.e. do not install HAProxy, OpenResty...)](#applying-only-firewall-rules-on-a-specific-server-ie-do-not-install-haproxy-openresty)
        - [External documentation about UFW and Ansible](#external-documentation-about-ufw-and-ansible)
- [Advanced usage](#advanced-usage)
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
... **yet**. HAProxy & OpenResty is likely to resist errors, and have backup
files for every old configuration on the target servers, but if you use custom
configurations beyond what ALB is designed, you still will need to log on the
server and rename older files or re-run a playbook with ALB to allow fix it.

#### Decoupled subcomponents when makes sense
See [ALB components](#alb-components).

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
  - `alb_manange_ufw: yes`
- **To permanently disable management by ALB for ALL components**
  - `alb_manange_ufw: no`

The most important components to run the [ALB Apps](#apps) are
[OpenResty](#openresty) <sup>(strong requeriment; installed by default)</sup> and
[HAProxy](#haproxy) <sup>(recommended suggestion, but optional; installed by default)</sup>.
The next one, if the cloud/baremetal provider already does not provider some firewall or
you lack of better option is the [UFW](#ufw)
<sup>(situational recommended suggestion; NOT installed by default)</sup>.

For more details check [defaults/main.yml](defaults/main.yml):

```yaml
### Enable/Disable ALB subcomponents ___________________________________________
## Note: these defaults will install everyting, except the firewall.
alb_manange_all: yes
alb_manange_haproxy: yes
alb_manange_openresty: yes
alb_manange_ufw: no

## Optionated (but NOT required) group of tasks.
alb_manange_common: yes  # hostname, timezone (UTC) [See tasks/common/common.yml]
alb_manange_devtools: no # net-tools, htop, hatop [tasks/devtools/devtools.yml]

## Note: the next options is better leave it alone
alb_manange_apps: "{{ alb_manange_openresty }}"
alb_manange_logrotate: "{{ alb_manange_haproxy or alb_manange_openresty }}"
```

### Apps

> Tip: `apps` requires [OpenResty](#openresty).

- **To permanently enable management by ALB**
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
information faster.

```yaml
    alb_apps:

      - app_uid: "hello-world"
        app_domain: "debug.example.org"
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

##### socket-php
> This strategy is a draft and/or can be removed or made obsolet by [proxy](#proxy).

See [templates/alb-strategy/socket-php.conf.j2](templates/alb-strategy/socket-php.conf.j2).

### Common

- **To permanently enable management by ALB**
  - `alb_manange_common: yes`
- **To permanently disable management by ALB**
  - `alb_manange_common: no`
- **Check Mode ("Dry Run"): only test changes without applying**
  - `--tags alb-common --check`
  - Example: `ansible-playbook -i hosts main.yml --tags alb-common  --check`

This optionated package is enabled by default, but is not a requeriment.

Check [tasks/common/common.yml](tasks/common/common.yml).

### DevTools

- **To permanently enable management by ALB**
  - `alb_manange_devtools: yes`
- **To permanently disable management by ALB**
  - `alb_manange_devtools: no`
- **Check Mode ("Dry Run"): only test changes without applying**
  - `--tags alb-devtools --check`
  - Example: `ansible-playbook -i hosts main.yml --tags alb-devtools  --check`

This package is not enabled by default, and is not a requeriment. It's is just
one optionated suggestion of software to debug.

Check [tasks/devtools/devtools.yml](tasks/devtools/devtools.yml).

#### hatop
> HAtop is only installed if HAproxy is enabled ( `alb_manange_haproxy: yes`),
  e.g. only enabling devtools (`alb_manange_devtools: yes`) is not sufficient

```bash
hatop -s /run/haproxy/admin.sock
```
See <http://feurix.org/projects/hatop/>

#### htop

```bash
htop
```
See <https://hisham.hm/htop/>.

#### multitail

```bash

# This command will always work on a new installed ALB with OpenResty or Apps enabled
multitail -ci white /var/log/alb/access.log -ci yellow -I /var/log/alb/error.log  -ci blue -I /var/log/alb/letsencrypt.log

# This is how you watch logs only for an `app_uid: APPNAMEHERE`
multitail -ci green /var/log/app/APPNAMEHERE/access.log -ci red -I /var/log/APPNAMEHERE/error.log

# This is how you watch logs only for an `app_uid: APPNAMEHERE` and all other important logs of ALB
multitail -ci white /var/log/alb/access.log -ci yellow -I /var/log/alb/error.log  -ci blue -I /var/log/alb/letsencrypt.log -ci green /var/log/app/APPNAMEHERE/access.log -ci red -I /var/log/APPNAMEHERE/error.log
```

See <https://www.vanheusden.com/multitail/examples.php>.

#### netstat

```bash
# Show open ports
sudo netstat -ntulp
```

### HAProxy

- **To permanently enable management by ALB**
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

> _@TODO add quick guide on HAProxy stats page here (fititnt, 2019-11-11 02:01 BRT_

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

`GUI/lua-resty-auto-ssl` used with [OpenResty](#openresty) to allow Automatic
HTTPS on-the-fly.

See [GUI/lua-resty-auto-ssl](https://github.com/GUI/lua-resty-auto-ssl).

### UFW
> _To avoid acidental use, this feature is not enabled by default (and will
> **never** be on any future release). `alb_manange_ufw: yes` is explicitly
> required._

> _Protip: Check Mode ("Dry Run") with `--tags alb-ufw --check`. This will
 test changes **without** applying._

- **To permanently enable management by ALB**
  - `alb_manange_ufw: yes`
- **To permanently disable management by ALB**
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

See also [Firewall Internals](firewall-internals.md) <sup>(working draft)</sup>.

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

- See variables [defaults/main.yml](defaults/main.yml)
- [ALB Internals](alb-internals.md)
- [NLB Internals](nlb-internals.md) <sup>(working draft)</sup>
- [Firewall Internals](firewall-internals.md) <sup>(working draft)</sup>

> Tip: OpenResty allow usage of LuaJIT. You can test lua language online at
<https://www.lua.org/cgi-bin/demo>

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
