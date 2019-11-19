# Ad Hoc playbooks for AP-ALB
> This folder is a draft. May change later without notice.

The very first struction to you near copy and paste will assume you are at the
root of your project and this role is installed under
`roles/ap-application-load-balancer` and your inventory is at `hosts.yml`:

- `ansible-playbook roles/ap-application-load-balancer/ad-hoc-alb/show-alb-hosts-facts.yml -i hosts.yml`

The second option, will assume you have both the ad-hoc-alb script and hosts
file on same folder:

- `ansible-playbook show-alb-hosts-facts.yml -i hosts.yml`

Sometimes the ad-hoc-alb tasks can be possible without a yml playbook, only
using `ansible` (and not `ansible-playbook`). In this case, you will receive
a third reference, like:

- `ansible all -m setup -a "filter=ansible_local" -i hosts.yml`
