# AP-ALB tests

The files on directory `ap-application-load-balancer/tests` by default will be
be sincronized and be avalible on each host ALB node `/opt/alb/bin/tests/`.

Note, the tests will NOT be installed if a node is not installed as `alb-standard`
e.g. is installed as `alb-minimal` since `alb-minimal` do not create `/opt/alb/`
folder structure.

```bash
py.test tests/test_alb-standard-node.py --ssh-identity-file="~/.ssh/id_rsa-rocha" --hosts="root@aguia-pescadora-foxtrot.etica.ai"

## Hint: you can make a symbolic link from the directory where your playbook run
# to where the AP-ALB role is is installed on the machine.
# Suggested name: "ad-hoc-alb-tests"

# Change "cross_platform_test_2" and ansible_inventory=hosts.yml to your case

py.test ad-hoc-alb-tests/test_alb-standard-node.py -p no:pytest-ansible --hosts='ansible://cross_platform_test_2?ansible_inventory=hosts.yml'
```


## How to run

### Extra backends
- <https://testinfra.readthedocs.io/en/latest/backends.html>
