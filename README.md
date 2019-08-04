# Águia Pescadora Application Load Balancer (AP-ALB)
**[Not Production Ready] [Águia Pescadora](https://aguia-pescadora.etica.ai/)
Application Load Balancer (Ansible Role)**.

> TL;DR: you can use this and other works from Emerson Rocha or Etica.AI as
reference (from underline tools to full use of Infrastructure As Code). But
since we can't make promisses of full backward compatibility and we're testing
in very specific scenarios we're not only OK that you can copy the Ansible Role
and make you custom version, but strongly recommended strategy. The brand
"Águia Pescadora" / "AP" / "ap-" are not used on internal code, so this code
base is very useful to reuse parts betwen projects and even rebrand for
humanitarian or commercial projects from who help we on Etica.AI.

<!--Emerson Rocha dedicated this work to Public Domain -->

# The Solution Stack

## Core

- [Ansible](https://github.com/ansible/ansible)
- [Ubuntu Server LTS](https://ubuntu.com/)
- [OpenResty](https://openresty.org) (NGinx Fork)
- [GUI/lua-resty-auto-ssl](https://github.com/GUI/lua-resty-auto-ssl)

## Extras

> TODO: add non-core extras that (via configuration) can be enabled (fititnt, 2019-08-03 23:06 BRT)

## Debug

```bash
tail -f /var/log/application_load_balancer/access.log
tail -f /var/log/application_load_balancer/error.log
# Minio keys
cat /usr/local/share/minio/minio.sys/config/config.json
cat /minio-test/.minio.sys/config/config.json
```

Requirements
------------

- Ubuntu
  - Ubuntu 18.04 (Recommended)

Role Variables
--------------

[defaults/main.yml](defaults/main.yml)

# TODO
- Document strategy to use AP-ALB to secure Elastic Search without X-Pack
  - Some links about
    - https://discuss.elastic.co/t/basic-authentication-of-es-without-x-pack/94840
    - https://discuss.elastic.co/t/basic-auth-on-kibana-using-nginx/158871

# License
[![Public Domain](https://i.creativecommons.org/p/zero/1.0/88x31.png)](UNLICENSE)

To the extent possible under law, [Etica.AI](https://etica.ai/) has waived all
copyright and related or neighboring rights to this work to
[Public Domain](UNLICENSE).
