# Firewall Internals

> _To avoid acidental use, this feature is not enabled by default.
> `alb_manange_ufw: yes` is explicitly required._

> _Under certain circumstances, even if `alb_manange_ufw: yes` is enabled, 
port `alb_ssh_port: 22` will be kept open or the ALB will stop before starting
changing the UFW. You can override this on `alb_ufw_rules_always` or following
the instructions on the error message._

<!-- TOC depthFrom:2 -->

- [Summary](#summary)
- [External documentation](#external-documentation)
- [With AP-ALB role](#with-ap-alb-role)
    - [Example 1](#example-1)
- [Ad-Hoc (without AP-ALB role)](#ad-hoc-without-ap-alb-role)
    - [Visual example with asciinema](#visual-example-with-asciinema)

<!-- /TOC -->

## Summary
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

## External documentation

- Ansible documentation: <https://docs.ansible.com/ansible/latest/modules/ufw_module.html>
- UFW Introduction: <https://help.ubuntu.com/community/UFW>
- UFW Manual: <http://manpages.ubuntu.com/manpages/cosmic/en/man8/ufw.8.html>

## With AP-ALB role

### Example 1

```yaml
# draft
- name: "ap-application-load-balancer playbook example (complex)"
  hosts: my_complex_hosts
  remote_user: root
  vars:

    alb_bastion_hosts:
      - 123.126.157.123

    alb_jump_boxes:
      - 123.126.157.124

    alb_dmz:
      - ip: 123.23.23.115
        name: cdn3
      - ip: 123.123.123.123
        name: lalala
        delete: yes
```

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

