# Águia Pescadora Application Load Balancer (_"AP-ALB"_) - v0.2-beta
**[Águia Pescadora](https://aguia-pescadora.etica.ai/)
Application Load Balancer (Ansible Role)**.

> TL;DR: you can use this and other works from Emerson Rocha or Etica.AI as
reference (from underline tools to full use of Infrastructure As Code). But
since we can't make promisses of full backward compatibility and we're testing
in very specific scenarios **we're not only OK that you can copy the Ansible Role
and make you custom version, but strongly recommended strategy**. The brand
"Águia Pescadora" / "AP" / "ap-" are not used on internal code, so this code
base is very useful to reuse parts betwen projects and even rebrand for
humanitarian or commercial projects from who help we on Etica.AI.

<!--Emerson Rocha dedicated this work to Public Domain -->

# The Solution Stack of AP-ALB

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

TL;DR: See [example/playbook-basic.yml](example/playbook-basic.yml) and
[example/playbook-complex.yml](example/playbook-complex.yml) for some examples
of usage.


### Advanced usage

- See variables [defaults/main.yml](defaults/main.yml)
- See [debugging-quickstart.md](debugging-quickstart.md).

# TODO

- Improve documentation
- Add at least one <https://asciinema.org/> demonstration
- Rewrite/reorganize some tasks files, in special the
  [tasks/default-files.yml](tasks/default-files.yml) that is doing too much for
  different services
- Document strategy to use AP-ALB to secure Elastic Search without X-Pack
  - Some links about
    - https://discuss.elastic.co/t/basic-authentication-of-es-without-x-pack/94840
    - https://discuss.elastic.co/t/basic-auth-on-kibana-using-nginx/158871

# License
[![Public Domain](https://i.creativecommons.org/p/zero/1.0/88x31.png)](UNLICENSE)

To the extent possible under law, [Etica.AI](https://etica.ai/) has waived all
copyright and related or neighboring rights to this work to
[Public Domain](UNLICENSE).
