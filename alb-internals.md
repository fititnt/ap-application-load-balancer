# Águia Pescadora Application Load Balancer Internals

<!-- TOC depthFrom:1 -->

- [Águia Pescadora Application Load Balancer Internals](#águia-pescadora-application-load-balancer-internals)
- [Overview](#overview)
    - [Review to follow the Filesystem Hierarchy Standard 3.0](#review-to-follow-the-filesystem-hierarchy-standard-30)
    - [ALB Internals](#alb-internals)
        - [Directory structures](#directory-structures)
            - [Internal usage of ALB](#internal-usage-of-alb)
            - [Usage of Apps](#usage-of-apps)
        - [System users](#system-users)
    - [NLB Internals](#nlb-internals)
        - [Ports](#ports)
        - [Directory structures](#directory-structures-1)
- [AP-ALB Component Internals](#ap-alb-component-internals)
    - [Apps](#apps)
    - [Common](#common)
    - [HAProxy](#haproxy)
    - [Logrotate](#logrotate)
    - [OpenResty](#openresty)
    - [UFW](#ufw)
        - [Summary](#summary)
        - [External documentation](#external-documentation)
- [To Do](#to-do)

<!-- /TOC -->

# Overview

## Review to follow the Filesystem Hierarchy Standard 3.0

> _TODO: take time and review the full lastest **Filesystem Hierarchy Standard**
> and, if need, make some small adaptations to AP-ALB structure. See 
> <https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard> and 
> <https://refspecs.linuxfoundation.org/FHS_3.0/fhs-3.0.pdf>
> (fititnt, 2019-12-05 21:41 BRT)_

Things that we could implement from <https://refspecs.linuxfoundation.org/FHS_3.0/fhs-3.0.pdf>
that are not implemented yet on [Directory structures](#directory-structures).

- `/opt/alb/`
  - **3.13. /opt : Add-on application software**
    - _"3.13.1. Purpose"_
    - _"/opt is reserved for the installation of add-on application software packages."_
    - _"A package to be installed in /opt must locate its static files in a separate /opt/< package > or /
    opt/< provider > directory tree, where < package > is a name that describes the software package
    and < provider > is the provider's LANANA registered name."_
      - I did not know that even `/opt` had some way to register a namespace,
        and was just not simply _free to everyone_
      - Humm, so ACTUALLY is possible to register application name at
       http://www.lanana.org/lsbreg/instructions.html if we _really_ interested?
        - Neither `alb` or `nlb` where registered at
          <http://www.lanana.org/lsbreg/providers/providers.txt> :)
          - Humm, actually the bugtrack is quite slow and did not processed
            requests even from namespaces like MongoDB, <https://lsbbugs.linuxfoundation.org/buglist.cgi?query_format=specific&order=relevance+desc&bug_status=__open__&product=&content=%2Fopt%2F+namespace+assignment>
          - But as I see, one reason is because is running by volunteers and
            also they really require the "email be a permanent one" from the
            organization (like contact@etica.ai) and not (rocha@ieee.org),
            see <https://lsbbugs.linuxfoundation.org/show_bug.cgi?id=4263>
       - Here the git repository https://github.com/LinuxStandardBase/lanana
    - 3.13.2
      - _"**No other package files may exist outside the /opt, /var/opt, and
      /etc/opt** hierarchies except for those package files that must reside in
      specific locations within the filesystem tree in order to function
      properly. For example, device lock files must be placed in /var/lock and
      devices must be located in /dev."_
        - **Note to self: if we eventually have host-specific variables and
          whant not use /etc/ansible/facts.d/ the /etc/opt/alb/ could be
          one standard place**
- `/var/opt`
  - **5.12. /var/opt : Variable data for /opt**
    - _"Variable data of the packages in /opt must be installed in /var/opt/< subdir >, where < subdir >
    is the name of the subtree in /opt where the static data from an add-on software package is stored, except
    where superseded by another file in /etc. No structure is imposed on the internal arrangement of /var/
    opt/<subdir>"_
    - _"Rationale Refer to the rationale for /opt"_
- `/var/cache/alb/`?
  - **FHS 3.0 5.5. /var/cache : Application cache data**
    - _"/var/cache is intended for cached data from applications. Such data is locally generated as a result of
    time-consuming I/O or calculation. The application must be able to regenerate or restore the data. Unlike
    /var/spool, the cached files can be deleted without data loss. The data must remain valid between
    invocations of the application and rebooting the system."_
    - _"Files located under /var/cache may be expired in an application specific manner, by the system
    administrator, or both. The application must always be able to recover from manual deletion of these files
    (generally because of a disk space shortage). No other requirements are made on the data format of the
    cache "_

## ALB Internals

> Tip: at [NLB Internals](#nlb-internals) there is additional features that
may be useful (TL;DR: _the HAproxy part_), but we try to provide good defaults
so maybe you could ignore HAProxy if it just works for you.

### Directory structures

#### Internal usage of ALB

If debugging ALB (and not just one App) these directories and folders are the
ones you are likely to be interested.

Think the folder `/opt/alb/` as one [syntactic sugar](https://en.wikipedia.org/wiki/Syntactic_sugar).
for all other folders and files that are important.

- **ALB configuration directories and files**:
  - `/opt/alb/`
    - **`/opt/alb/alb.conf`** -> `/usr/local/openresty/nginx/conf/nginx.conf`
    - **`/opt/alb/nlb.cfg`** -> `/etc/haproxy/haproxy.cfg`
    - `/opt/alb/apps/` _(Store OpenResty/NGinx rule for each app as **`/opt/alb/apps/{{ app_id }}.conf`**)_
    - `/opt/alb/sysapps/` _(Store OpenResty/NGinx rule for each Sysapp as **`/opt/alb/sysapps/{{ app_id }}.conf`**)_
    - <strike>`/opt/alb/alb-data/` -> `/var/alb/`</strike><sup>(deprecated as v0.8.2)</sup>
    - `/opt/alb/alb-cache` -> `/var/opt/alb/alb-cache/`
    - `/opt/alb/alb-backups` -> `/var/opt/alb/alb-backups`
    - `/opt/alb/alb-logs/` -> `/var/log/alb/`
    - `/opt/alb/apps-backups` -> `/var/opt/alb/apps-backups/`
    - <strike>`/opt/alb/apps-data/` -> `/var/app/`</strike><sup>(deprecated as v0.8.2)</sup>
    - `/opt/alb/apps-logs/` -> `/var/log/app/`
    - `/opt/alb/bin/` _(Planed, not fully implemented)_
      - Maybe in future releases this will have links to ansible facts, like
        - `/opt/alb/bin/alb_apps` -> `/etc/ansible/facts.d/alb_apps.fact`
        - ... so when executing `alb_apps` in one host someone would know a JSON
          representation of the state of the node.
        - Today a user have to use `/etc/ansible/facts.d/alb_ufw.fact | jq`
    - `/opt/alb/info/` _(Planed, not fully implemented)_
    - `/opt/alb/sysapps-backups` -> `/var/opt/alb/sysapps-backups/`
    - <strike>`/opt/alb/sysapps-data/` -> `/var/sysapp/`</strike><sup>(deprecated as v0.8.2)</sup>
    - `/opt/alb/sysapps-logs/` -> `/var/log/sysapp/`
    - `/opt/alb/haproxy/` -> `/etc/haproxy/`
    - `/opt/alb/nginx/` -> `/usr/local/openresty/nginx/`
    - `/opt/alb/letsencrypt/` -> `/etc/resty-auto-ssl/letsencrypt/`
- **ALB logs files**:
  - `/var/log/alb/access.log`
  - `/var/log/alb/error.log`
  - `/var/log/alb/letsencrypt.log`
  - `/var/log/alb/apps/` -> `/var/log/app/`
- **Data created on Runtime by ALB or via hooks** _(Planed, not fully implemented)_
  - <strike>/var/alb/</strike> (this was not well aligned with Filesystem Hierarchy Standard 3.0)
  - `/var/opt/alb/`
    - `/var/opt/alb/alb-backups/`
    - `/var/opt/alb/apps-backups/`
      - `/var/opt/alb/apps-backups/{{ app_id }}/` <sup>(Should be created on demand)</sup>
    - `/var/opt/alb/sysapps-backups/`
      - `/var/opt/alb/sysapps-backups/{{ app_id }}/` <sup>(Should be created on demand)</sup>
    - `/var/opt/alb/alb-cache/`
    - `/var/opt/alb/alb-tmp/`

#### Usage of Apps

If your ALB setup already is working, these are the files and folders that
are specific for each App.

- **App rule**
  - `/opt/alb/apps/{{ app_uid }}.conf`
- **App data** _(if some parameter require custom folder to store data, but
  the specific path is not specified by the app, this pattern will be used)_
  - `/var/app/{{ app_uid }}/`
- **App logs** _(when not using `/var/log/alb/...` and not specified custom path)_
  - `/var/log/app/{{ app_uid }}/access.log`
  - `/var/log/app/{{ app_uid }}/error.log`

Tip: `/var/www/SomeFolder` and `/home/SomeUser/SomeFolder` are common pattens
of folders for your apps. The use of `/var/app/{{ app_uid }}/` is mostly to
avoid conflicts with existend content, and is not a requirement at all.

<!--

@NOTE This part is commented out, explanation here
       https://github.com/fititnt/ap-application-load-balancer/issues/8#issuecomment-555401930
       (fititnt, 2019-11-19 07:32 BRT)

  #### Shared usage for third party tools

Some variables when present on a play of a playbook using ALB will create or
update contents of specific files on each server. **Consider this list as
suggestion, not as one strong enforcement, and that most of these options will
not automatically be considered if not enabled for other tools**, in special the
ones that could be useful for Firewalls. 

Some considerations:
- `alb_vars_saveondisk: no` will enforce not store the suggested variables on
  these documented paths.
  - **Use this option if you are concerned with vunerable applications that
    could leak sensive data**.
- Since you is already using Ansible if want to reuse these data on other tools
  consider that can be simple use the ALBs variables as information.
  - It can be easier do this can change other applications to watch for changes
    on these files.

  ##### `alb_ips_remoteadmins`
- File: `/opt/alb/remoteadmins`

  ##### `alb_ips_dmz`
- File: `/opt/alb/dmz`

  ##### `alb_ips_whitelist`
- File: `/var/alb/ips_whitelist.txt`

  ##### `alb_ips_blacklist`
- File: `/var/alb/ips_blacklist.txt`

  ##### `alb_domains_whitelist`
- File: `/var/alb/domains_whitelist.txt`

  ##### `alb_domains_blacklist`
- File: `/var/alb/domains_blacklist.txt`

-->

### System users

- `www-data`
  - This user (created OpenResty if already does not exist on the system) is
    used sometimes as default user for common programs.
- `alb`
- `{{ app_uid }}` or `{{ app_systemuser }}` (Optional, not created by default)
  - Planned, but not implemented

## NLB Internals
> Tip: consider reading first the [ALB Internals](#alb-internals).

Before going further, consider that the features related to _"network load
balancer"_ (the _"more Layer 4 features"_) from AP-ALB are _an extra_, not a
main objective, when otimizing automation with Ansible on this project. It does
not means that the HAproxy is not important: it is! To list some details:

- HAProxy is by default is installed with ALB and is in front of every ALB App.
  - The averange user maybe not even need to know what HAProxy is doing. **The
    idea is "it just works fine" out of the box**.
  - **BUT** if later on production some feature get too complicated to push
    OpenResty to the limits... the **HAProxy already is there!**
- HAProxy reuse some variables of AP-ALB
- Yes, OpenResty logs already will register the user Real IP
- (...)

### Ports
> Note: these defaults can be changed.

- HAproxy `0.0.0.0:80` -> OpenResty: `127.0.0.1:8080`
  - HAProxy listem to HTTP :80 port then will redirect to OpenResty :8080
  - Even without custom firewall rule the extra OpenResty port will not be open
    to the world.
- HAproxy `0.0.0.0:443` -> OpenResty: `127.0.0.1:4443`
  - HAProxy listem to HTTPS :443 port then will redirect to OpenResty :4443
  - Even without custom firewall rule the extra OpenResty port will not be open
    to the world.
  - The HTTPS/TLS termination is done by OpenResty.
    - This is an option that could be improved later and make HAProxy also do
      the HTTPS.

HAproxy can be used for other types of load balancing, like to intermediate
MariaDB/MySQL, MongoDB, Apache, etc in a very efficient way.

### Directory structures

As version **v0.6.0-alpha**, `/opt/nlb/` is symbolic link to `/opt/alb/`. This
may change on future.

- **NLB configuration files**:
  - `/opt/nlb/` -> `/opt/alb/`
    - **`/opt/alb/alb.conf`** -> `/usr/local/openresty/nginx/conf/nginx.conf`
    - **`/opt/alb/nlb.cfg`** -> `/etc/haproxy/haproxy.cfg`
    - `/opt/alb/alb-data/` -> `/var/alb/`
    - `/opt/alb/alb-logs/` -> `/var/log/alb/`
    - `/opt/alb/apps/` _(Store OpenResty/NGinx rule for each app as **`/opt/alb/apps/{{ app_id }}.conf`**)_
    - `/opt/alb/info/` _(Planed, not fully implemented)_
    - `/opt/alb/apps-data/` -> `/var/app/`
    - `/opt/alb/apps-logs/` -> `/var/log/app/`
    - `/opt/alb/haproxy/` -> `/etc/haproxy/`
    - `/opt/alb/nginx/` -> `/usr/local/openresty/nginx/`
    - `/opt/alb/letsencrypt/` -> `/etc/resty-auto-ssl/letsencrypt/`

_@TODO improve documentation of NLB Internals (fititnt, 2019-11-08 23:10 BRT)_

# AP-ALB Component Internals

## Apps

- See [README.md#apps](README.md#apps)
- See [ALB Internals](#alb-internals)

## Common

- See [README.md#common](README.md#common)

## HAProxy

- See [NLB Internals](#nlb-internals).

## Logrotate

- See [README.md#logrotate](README.md#logrotate)

## OpenResty

- See [ALB Internals](#alb-internals).

## UFW

> _To avoid acidental use, this feature is not enabled by default.
> `alb_manange_ufw: yes` is explicitly required._

> _Under certain circumstances, even if `alb_manange_ufw: yes` is enabled, 
port `alb_ssh_port: 22` will be kept open or the ALB will stop before starting
changing the UFW. You can override this on `alb_ufw_rules_always` or following
the instructions on the error message._

### Summary
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

### External documentation

- Ansible documentation: <https://docs.ansible.com/ansible/latest/modules/ufw_module.html>
- UFW Introduction: <https://help.ubuntu.com/community/UFW>
- UFW Manual: <http://manpages.ubuntu.com/manpages/cosmic/en/man8/ufw.8.html>

---

> _@TODO: document the optimal setup of firewall using AP-ALB (fititnt, 2019-11-08 22:13 BRT)_

# To Do

- Add (or at least document) how to share HTTPS certificates accross cluster
of load balancers
  - Hint: check <https://github.com/GUI/lua-resty-auto-ssl> and use Redis as
    storage instead of local filesystem.

<!--

- Rewrite/reorganize some tasks files, in special the
  [tasks/default-files.yml](tasks/default-files.yml) that is doing too much for
  different services
- Document strategy to use AP-ALB to secure Elastic Search without X-Pack
  - Some links about
    - https://discuss.elastic.co/t/basic-authentication-of-es-without-x-pack/94840
    - https://discuss.elastic.co/t/basic-auth-on-kibana-using-nginx/158871

-->