# Goals
<!-- TOC depthFrom:2 depthTo:5 -->

- [AP-ALB Goals](#ap-alb-goals)
    - [Automatic updates of components after deployed](#automatic-updates-of-components-after-deployed)
    - [Resilient to sysadmin errors on production servers](#resilient-to-sysadmin-errors-on-production-servers)
        - [What about one-click rollback feature?](#what-about-one-click-rollback-feature)
    - [Decoupled subcomponents when makes sense](#decoupled-subcomponents-when-makes-sense)
- [AP-ALB Non-Goals](#ap-alb-non-goals)
    - [Do not enforce specific Virtual Private Network implementation](#do-not-enforce-specific-virtual-private-network-implementation)
    - [Custom end user graphical interface or no need of sudo to deploy proxy rules](#custom-end-user-graphical-interface-or-no-need-of-sudo-to-deploy-proxy-rules)
        - [Potential alternatives](#potential-alternatives)

<!-- /TOC -->

## AP-ALB Goals

### Automatic updates of components after deployed

The AP-ALB Infrastructure as Code written in Ansible can be labeled as `beta` or
`Release Candidate` but **the end result is aimed to be running non-stop in
production at least with security updates without human intervention**.

**Who guarantees updates:**
- **HAProxy 2.0**:
  - _Note: version **haproxy=2.0.\*** is locked_
  - <https://haproxy.debian.net/#?distribution=Ubuntu&release=bionic&version=2.0>
- **OpenResty**:
  - We use OpenResty® provides official pre-built packages
  - <https://openresty.org/en/linux-packages.html>
- **Automatic HTTPS**
  - GUI/lua-resty-auto-ssl
    - We use OpenResty package mananger
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

### Resilient to sysadmin errors on production servers

ALP do it's best to not stop services even when the administrator deploy invalid
configurations on production.

A human can be so self-confident (or not knowing the difference) and after
updating configurations on production instead of _reload a service_ go ahead and
_restart a service_. Sometimes is not only about packat loss (user or external
services receiving errors for a second) but with configuration errors will stop
an online service.

#### What about one-click rollback feature?

Note that we do not support [`one-click rollback` Ansistrano-like style](https://github.com/ansistrano/deploy)
... **yet**.

HAProxy & OpenResty is likely to resist errors, and have backup
files for every old configuration on the target servers, but if you use custom
configurations beyond what ALB is designed, you still will need to log on the
server and rename older files or re-run a playbook with ALB to allow fix it.

### Decoupled subcomponents when makes sense
See [ALB components](#alb-components).

## AP-ALB Non-Goals
> **non-goal** (plural non-goals)
> A potential goal or requirement which is explicitly excluded from the scope of a project.
> [wiktionary for non-goal](https://en.wiktionary.org/wiki/non-goal)

### Do not enforce specific Virtual Private Network implementation
One of the main goals of AP-ALB is be able to run on very cheap providers.
Another goal is work smooth with hosts across different providers. Both cases
when running AP-ALB in clustered mode could be done only with firewall, but tend
to be less complex just implement some underlining VPN across the nodes.

There are several ways to implement VPN, but as for AP-ALB, **our objective is
just make it work fine with private IPs and give at least one playbook example
with any VPN solution**. So its a Non-goal enforce (or even strong suggest) any
specific underlining VPN solution.

If your implemencation makes sense using VPNs, choose one underline
implementation that is aligned with your skillset and concerns with type of
survilance of the specific project you are working on to deploy AP-ALB.

### Custom end user graphical interface or no need of sudo to deploy proxy rules
One of the big features of Load Balancers of big cloud providers is that they
have some way (like a web interface) for a user create their rules. Is possible
to make this for ALB, our target audience very likely is doing an ALB for
themselves and would have root access anyway on some cheap VPSs.

#### Potential alternatives

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
