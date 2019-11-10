# firewall-internals

## Ad-Hoc (without AP-ALB role)
At [tasks/ap-firewall/](tasks/ap-firewall/) is possible to use one Ad-Hoc
Ansible scripts that do simple setup of UFW on one a single or a cluster of
VPSs. This folder is one extra copy of the original work was from the same
author of AP-ALB also released under Public Domain. Check:
<https://github.com/EticaAI/aguia-pescadora-ansible-playbooks/tree/master/tarefa/firewall>.

### Visual example with asciinema

[![asciicast](https://asciinema.org/a/258426.svg)](https://asciinema.org/a/258426)

---

> _@TODO: document the optimal setup of firewall using AP-ALB (fititnt, 2019-11-08 22:13 BRT)_

## With AP-ALB role

```yaml
# draft
- name: "ap-application-load-balancer playbook example (complex)"
  hosts: my_complex_hosts
  remote_user: root
  vars:
    alb_name: "MyALBName/2.0"
    alb_forcedebug: yes

    alb_haproxy_stats_enabled: yes

    alb_superuser_auth:
     - username: Admin1
       password: "plain-password"
     - username: Admin2
       password: "plain-password2"
    alb_superuser_ip: 123.123.123.123

    alb_superusers:
      - 123.126.157.169

    alb_dmz:
      - ip: 123.23.23.115
        name: cdn3
      - ip: 123.123.123.123
        name: lalala
        delete: yes
```