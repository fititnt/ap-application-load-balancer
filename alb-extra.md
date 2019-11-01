# ALB Extras
> **Important: the funcionality listed are not core functions of AP-ALB.**
> It's recommented that you consider using more specific ansible roles
> create your own and use AP-ALB core functions.

### ALB-Extra-PHP

Note: at least the first time you run your playbook is very likely that you
have the `application_load_balancer_forceignore_extra_php: true` to allow
ALB to install PHP on the local machine. Note that, for compatibility reasons,
the strategy `php-local` is likely to still work, but install/remove of PHP
packages, management of system users, etc will be ignored.

#### Examples of use
This alb-strategy is similar to `proxy`
([templates/alb-strategy/proxy.conf.j2](templates/alb-strategy/proxy.conf.j2))
but 

```yaml
    application_load_balancer_apps:

      - app_uid: "minio"
        app_domain: "minio.example.org"
        app_alb_strategy: "proxy"
        app_forcehttps: yes
        app_alb_proxy: ":::9091"
```
See [templates/alb-strategy/proxy.conf.j2](templates/alb-strategy/proxy.conf.j2).