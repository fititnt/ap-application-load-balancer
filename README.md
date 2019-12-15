# AP Application Load Balancer - v0.8.5-alpha

[![GitHub: fititnt/ap-application-load-balancer](docs/img/badges/github.svg)](https://github.com/fititnt/ap-application-load-balancer) [![Website: ap-application-load-balancer.etica.ai](docs/img/badges/website.svg)](https://ap-application-load-balancer.etica.ai/)

AP-ALB is not a single software, but **[Infrastructure As Code](https://en.wikipedia.org/wiki/Infrastructure_as_code)
via [Ansible Role](https://docs.ansible.com/) to automate creation and maintance of
with features common on expensive _Application Load Balancer_ of some cloud
providers** (e.g. [Alibaba](https://www.alibabacloud.com/product/server-load-balancer),
[AWS](https://aws.amazon.com/elasticloadbalancing/),
[Azure](https://azure.microsoft.com/en-us/services/load-balancer/),
[GCloud](https://cloud.google.com/load-balancing/),
[IBM](https://www.ibm.com/cloud/load-balancer), etc). It can be used both to
create your own ALB on cheaper hardware on these same cloud providers or
have your own ALB on any other provider of VPSs or bare metal servers. And yes,
it handle automatic HTTPS for you on-the-fly **even** for clusters of ALBs, like
enterprise versions of Traefik or Caddyserver.

**AP-ALB is flexible**: you can either use dedicated very small VPSs with the role
of load balancing to another services or replace your Apache/NGinx/HAproxy in
each server with AP-ALB. Consider around just 64MB of RAM per node as baseline.
_(So, if you are deployng in a dedicated 1GB VPS, consider **at least** reuse
the same node puting behind the AP-ALB one Varnish-Cache!)_

**New on v0.8:** in addition to the single-node setup, you can now deploy 3-node
High Available AP-ALB Cluster using [Consul](https://www.consul.io/) instead of
local filesystem. We recommend using the Ansible Role
[brianshumate.consul](https://github.com/brianshumate/ansible-consul) for setup
and manangement of Consul component. Examples can be found at
[fititnt/ansible-linux-ha-cluster](https://github.com/fititnt/ansible-linux-ha-cluster).

[![asciicast](https://asciinema.org/a/288305.svg)](https://asciinema.org/a/288305)
> Source code for this demo at <https://github.com/fititnt/ansible-linux-ha-cluster/releases/tag/demo-001-ap-alb-v0.8.5-alpha>

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
    - [AP-ALB Goals](#ap-alb-goals)
    - [AP-ALB Non-Goals](#ap-alb-non-goals)
- [Quickstart Guide](#quickstart-guide)
    - [The minimum you already should know to use AP-ALB](#the-minimum-you-already-should-know-to-use-ap-alb)
    - [Complete examples using AP-ALB](#complete-examples-using-ap-alb)
    - [Quickstart on how to hotfix/debug production servers](#quickstart-on-how-to-hotfixdebug-production-servers)
- [ALB components](#alb-components)
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
  - [Ansible 2.9+](https://github.com/ansible/ansible) _(See: [Ansibe documentation](https://docs.ansible.com/))_
- **Operational System**:
  - **Debian Family**
    - Debian 10
    - Ubuntu Server LTS 18.04
  - **RedHat Family**
    - CentOS 8, CentOS 7
    - RHEL 8, RHEL 7
  - Compatible, but some functionalities requires extra steps:
    - **Arch Linux**
    - **BSD Family**: _FreeBSD 12_
    - **SUSE Family**: _OpenSUSE 15_
- **Firewall**
  - [UFW](https://help.ubuntu.com/community/UFW)
    - With exception of FreeBSD (OS that not even as option can have UFW
      installed) other OSs listed as supported can work with UFW.
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

### AP-ALB Goals
Content moved to [docs/goals/index.md](docs/goals/index.md).

### AP-ALB Non-Goals

Content moved to [docs/goals/index.md](docs/goals/index.md).

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

Content moved to [docs/component/index.md](docs/component/index.md).

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
