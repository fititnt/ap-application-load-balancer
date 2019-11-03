# Águia Pescadora Application Load Balancer (_"AP-ALB"_) - v0.4-beta
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

**There is no vendor lock in**, not even as option on AP-ALB. But before you
start the computer that will run and manage the target servers need already be
able to connect them via SSH as sudo user. Even our choice on **HAproxy** and
**OpenResty/NGinx** very likely to be the ones some big cloud providers use.

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

# The Solution Stack of AP-ALB

> _One line emoji explanation_:
>
> ☺️ 🤖 :end: **HAProxy <sup>(:80, :443)</sup>** :end: **OpenResty <sup>(:8080, :4443 🔒)</sup>** :end: **App**

- **Infrastructure as Code**:
  - [Ansible](https://github.com/ansible/ansible) _(See: [Ansibe documentation](https://docs.ansible.com/))_
- **Operational System**:
  - [Ubuntu Server LTS](https://ubuntu.com/)
- **Firewall**
  - _Not implemented/Not Documented_.
    - **Please use your own firewall rules**.
    - Tip: you can use [EticaAI/aguia-pescadora-ansible-playbooks/tarefa/firewall](https://github.com/EticaAI/aguia-pescadora-ansible-playbooks/tree/master/tarefa/firewall) as reference.
- **Load Balancing**
  - [HAProxy 2.0.x](https://github.com/haproxy/haproxy)
    _(See: [HAProxy starter guide](https://cbonte.github.io/haproxy-dconv/2.0/intro.html),
    [HAProxy Configuration Manual](https://cbonte.github.io/haproxy-dconv/2.0/configuration.html),
    [HAProxy Management Guide](https://cbonte.github.io/haproxy-dconv/2.0/management.html))_
  - [OpenResty](https://openresty.org) _(See: [NGINX Wiki!](https://www.nginx.com/resources/wiki/))_
- **Automatic HTTPS**
  - [GUI/lua-resty-auto-ssl](https://github.com/GUI/lua-resty-auto-ssl)
  - [Let’s Encrypt](https://letsencrypt.org/docs/)

## How to use

> TL;DR: See [example/playbook-basic.yml](example/playbook-basic.yml) and
[example/playbook-complex.yml](example/playbook-complex.yml) for some examples
of usage.

### Important directories
> @TODO: rewrite paths from "application_load_balancer" to just "alb" (fititnt, 2019-11-02 21:24 BRT)

- ALB
  - ALB Files
    - `/opt/alb/`
  - ALB default directory for logs (TL;DR: "the default place for the error.log/access.log from OpenResty/NGinx")
    - `/var/log/alb/`
- OpenResty
  - `/usr/local/openresty/`
  - Tip: OpenResty, even if is a fork of NGinx, **will not** use /etc/nginx/ (but `/usr/local/openresty/nginx/`)

### ALB Strategies
For simplification each _group of rules_ is called "app" because most of the
time this is the case. The parameter `app_alb_strategy` defines wich [OpenResty
configuration template](templates/alb-strategy]) will be used as base to
generate each file on
`/usr/local/openresty/nginx/conf/sites-enabled/{{ app_uid }}.conf`.

> Protip: if you already have experience editing NGinx configurations, the way
AP-ALB automate the work for you will be very familiar.

#### files-local
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

#### proxy
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

#### raw
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

### Advanced usage

- See variables [defaults/main.yml](defaults/main.yml)
- See folder [templates/alb-strategy](templates/alb-strategy) for ALB strategies
  used on each application
- See [debugging-quickstart.md](debugging-quickstart.md).

# To Do

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


# License
[![Public Domain](https://i.creativecommons.org/p/zero/1.0/88x31.png)](UNLICENSE)

To the extent possible under law, [Etica.AI](https://etica.ai/) has waived all
copyright and related or neighboring rights to this work to
[Public Domain](UNLICENSE).
