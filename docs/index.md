# AP Application Load Balancer - v0.8.5-alpha
[![GitHub: fititnt/ap-application-load-balancer](img/badges/github.svg)](https://github.com/fititnt/ap-application-load-balancer) [![Website: ap-application-load-balancer.etica.ai](img/badges/website.svg)](https://ap-application-load-balancer.etica.ai/)

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

[![Banner Águia Pescadora - © Andy Morffew www.andymorffew.com](img/aguia-pescadora-banner.jpg)](https://aguia-pescadora.etica.ai/)

---

<!-- TOC depthFrom:2 depthTo:5 -->

- [Project overview](#project-overview)
    - [AP-ALB Goals and Non-Goals](#ap-alb-goals-and-non-goals)
- [Administrator documentation](#administrator-documentation)
    - [AP-ALB Components](#ap-alb-components)
    - [Sysapplication Rules](#sysapplication-rules)
- [End-user documentation](#end-user-documentation)
    - [Application Rules](#application-rules)
- [License](#license)

<!-- /TOC -->

---

## Project overview

### AP-ALB Goals and Non-Goals
Check [goals/index.md](goals/index.md).

## Administrator documentation

### AP-ALB Components

Check [component/index.md](component/index.md).

### Sysapplication Rules

Sysapps have the same features of Application rules
([rules/index.md](rules/index.md)). The main reason is _"to namespace"_
Application Rules that are intended for internal use only.

## End-user documentation

### Application Rules
- Full topic: [rules/index.md](rules/index.md).

The AP-ALB Ansible Role use YAML definitions as internal way to apply changes on
your ALB nodes and (because of the underlining components HAProxy & OpenResty)
the AP-ALB will require root access. This implementation could work fine on
smaller implementations (when you have some trust on your developers will use this
to access data from other applications) or medium to large hosting companies
where you have someone from help desk to do some quick review.

**The AP-ALB does not have one GUI or API**. You may be interested in abstract
some of this complexity with [Ansible AWX](https://github.com/ansible/awx) /
[Ansible Tower](https://www.ansible.com/products/tower) or creating a custom
GUI / custom API to pre-process what AP-ALB (or any other custom implementation
that use our standard) will apply changes on your nodes.

## License
[![Public Domain](img/dominio-publico.png)](UNLICENSE)

To the extent possible under law, [Etica.AI](https://etica.ai/) has waived all
copyright and related or neighboring rights to this work to
[Public Domain](UNLICENSE).
