# AP-ALB Application Rules (The "Load Balancer listener" standard)
[![GitHub: fititnt/ap-application-load-balancer](../img/badges/github.svg)](https://github.com/fititnt/ap-application-load-balancer) [![Website: ap-application-load-balancer.etica.ai](../img/badges/website.svg)](https://ap-application-load-balancer.etica.ai/)

TL;DR:
- **The AP-ALB Ansible Role use YAML definitions as internal way to know what
  what is the desired final state of a ALB node. It means that, by default,
  there is not graphical user interface or API**.
- The control node (hint: can be your own notebook controling just one cheap
  VPS) will need root access to convert apply the YAML instructions.
  - AP-ALB by design will try protect from human errors related to
    misconfigurations.
  - AP-ALB alone, without human supervision is not able to protect from
    intentional configurations aimed to steal data from another applications.
- For more advanced cases (to abstract the security issues with root or use
  non-YAML alternative), you can still use AP-ALB to control your nodes, but
  - Use [Ansible AWX](https://github.com/ansible/awx) /
    [Ansible Tower](https://www.ansible.com/products/tower)
  - Create your own custom GUI / custom API to pre-process the YAML files used
    by AP-ALB (or any other *-ALB implementation)
- Read this documentation considering that some features AP-ALB are very
  exclusive to AP-ALB (or any solution that abstract HAProxy and
  OpenResty/NGinx) and do not have equivalent on cloud Load Balancers. Examples
  - AP-ALB may both installed on dedicated Load Balancer servers and also on
    the servers that have the applications running
    - It means that you can replace your Apache and Nginx with AP-ALB.

<!--
The AP-ALB Ansible Role use YAML definitions as internal way to apply changes on
your ALB nodes and (because of the underlining components HAProxy & OpenResty)
the AP-ALB will require root access. This implementation could work fine on
smaller implementations (when you have some trust on your developers will use this
to access data from other applications) or medium to large hosting companies
where you have someone from help desk to do some quick review.

Other pertinent aspect: The control node (hint: can be your own notebook
controling just one cheap VPS), because because of the underlining components
HAProxy & OpenResty, will need root access.
-->

## Table of Contents

<!-- TOC -->

- [AP-ALB Application Rules (The "Load Balancer listener" standard)](#ap-alb-application-rules-the-load-balancer-listener-standard)
    - [Table of Contents](#table-of-contents)
    - [Overview of Applications Variables on servers using AP-ALB standard](#overview-of-applications-variables-on-servers-using-ap-alb-standard)
    - [Applications variables](#applications-variables)
        - [app_*](#app_)
            - [app_uid](#app_uid)
            - [app_state](#app_state)
            - [app_domain](#app_domain)
            - [app_domain_extras](#app_domain_extras)
            - [app_debug](#app_debug)
            - [app_forcehttps](#app_forcehttps)
            - [app_hook_after](#app_hook_after)
            - [app_hook_before](#app_hook_before)
            - [app_index](#app_index)
            - [app_root](#app_root)
            - [app_tags](#app_tags)
        - [app_data_*](#app_data_)
            - [app_data_directories](#app_data_directories)
            - [app_data_files](#app_data_files)
            - [app_data_hook_export_after](#app_data_hook_export_after)
            - [app_data_hook_export_before](#app_data_hook_export_before)
            - [app_data_hook_import_after](#app_data_hook_import_after)
            - [app_data_hook_import_before](#app_data_hook_import_before)
        - [app_*_strategy](#app__strategy)
            - [app_alb_strategy](#app_alb_strategy)
            - [app_backup_strategy](#app_backup_strategy)
            - [app_ha_strategy](#app_ha_strategy)
            - [app_nlb_strategy](#app_nlb_strategy)
        - [app_alb_*](#app_alb_)
            - [app_alb_hosts](#app_alb_hosts)
            - [app_alb_proxy](#app_alb_proxy)
            - [app_alb_proxy_defaults](#app_alb_proxy_defaults)
            - [app_alb_proxy_location](#app_alb_proxy_location)
            - [app_alb_proxy_params](#app_alb_proxy_params)
            - [app_alb_raw](#app_alb_raw)
            - [app_alb_raw_file](#app_alb_raw_file)
        - [Deprecated app_* variables](#deprecated-app_-variables)
            - [app_raw_conf](#app_raw_conf)
            - [No default value for app_alb_strategy](#no-default-value-for-app_alb_strategy)
    - [AP-ALB Application Rules compared to other load balancers](#ap-alb-application-rules-compared-to-other-load-balancers)
        - [Azure Load balancer](#azure-load-balancer)
        - [AWS Application Load Balancers Listeners](#aws-application-load-balancers-listeners)
        - [Google Cloud Load Balancing](#google-cloud-load-balancing)

<!-- /TOC -->

## Overview of Applications Variables on servers using AP-ALB standard

Variables prefixed with `app_` are used by [Apps](#apps) and [Sysapps](#sysapps)
and have some extra customization via [ALB Strategies](#alb-strategies).

These are key elements that form a single dictionary (think _object_) for the
`alb_apps` (list of dictionaries) and `alb_sysapps` (list of dictionaries).

**Quick example:**

```yaml
    alb_apps:

      - app_uid: "static-files"
        app_domain: "assets.example.org"
        app_root: "/var/www/html"
        app_alb_strategy: "files-local"

      - app_uid: "minio"
        app_domain: "minio.example.org"
        app_alb_proxy: "http://localhost:9091"
        app_alb_strategy: "proxy"

    alb_sysapps:

      - app_uid: "consul"
        app_domain: "consul.{{ ansible_default_ipv4.address }}.nip.io"
        app_alb_strategy: "proxy"
        app_alb_proxy: "http://127.0.0.1:8500"
```

**New on v0.8.6-alpha**: internally ALB will merge `alb_sysapps_alb` +
`alb_sysapps_always` + `alb_sysapps` and `alb_app_always` + `alb_apps`. Ansible
default behavior when the same variable is defined default and then some hosts
also specify the variable is override. To make it easier for who want some
apps/sysapps be on all nodes on a datacenter (and to avoid you use advanced
features like `hash_behaviour` or implement plugins like
[leapfrogonline/ansible-merge-vars](https://github.com/leapfrogonline/ansible-merge-vars))
we suggest use as convention  `alb_sysapps_always` and `alb_app_always`.


## Applications variables

### app_*

> Note: as v0.8.x, this section still maybe not reflex all implementation, but
> as here as a plan of action (fititnt, 2019-12-04 17:27 BRT)

#### app_uid
- **Required**: _always_
- **Default**: _no default_
- **Type of Value**: `String`, `[a-zA-Z0-9\-\_]`
  - Safe to use: _Letters (lower and UPPERCASE), Numbers, Underline, Hyphen_
  - Not safe so safe to use (but not blocked): _`:`, `;`, UTF-8 characters (requires you system to support)_
  - Definely not use: _blank spaces, `/`, `\`, control character (NUL \0, LF \n, ...)_
- **About uniqueness**:
  - **Should be unique per node** (but `alb_apps` and `alb_sysapps` can reuse same app_id)
  - **Is recommended to reuse 'app_id` on different nodes that are same
    application**
    - Example 1: Active-Active HA load balancing
    - Example 2: Active-Passive HA load balancing
  -  Note: Is not strongly required be unique per cluster of nodes, even if are very
     different applications or version of applications (think production vs
     staging)
- **Examples of Value**: `hello-world`, `hello_world`

Internaly, AP-ALB use `app_uid` common name for configutation files (like
`/opt/alb/apps/{{ app_uid }}.conf`), default logs directory, default data
diretory, internal aliases for which load balance and more.

#### app_state
- **Required**: _no (implicit value)_
- **Default**: "present"
- **Examples of Value**: `present`, `absent`

`app_state` defaults to `present`, so you did not need to define. If you want
remove one app, it's configurations rules, log files, etc, you should at least
once re-run one time with the same `app_uid` and `app_state: absent` for each
node. After this, you can remove referentes to the old app/sysapp.

Note: implementators **should not** automaticaly remove backups based only on
this configutation.

#### app_domain
- **Required**: _yes_
- **Default**: _Default value is user configurable, based on `app_uid`_
- **Type of Value**: `String`, `Regex String`
  - Check [NGinx/Server Names for advanced options](http://nginx.org/en/docs/http/server_names.html)
- **Examples of Value**: `hello-world.example.org`, `hello-world.*`, `"hello-world.{{ ansible_default_ipv4.address }}.nip.io"`

Most `app_type` expect at least one main domain so the the AP-ALB will know what
to do when a request comes in.

#### app_domain_extras
- **Required**: _no_
- **Default**: _no default_
- **Type of Value**: list of `String`, `Regex String`
- **Examples of Value**:
> ```yaml
> # Empty list
> app_domain_extras: []
> # Please avoid using 'app_domain_extras: ' without defined itens and ': []' at the end
> ```
> ```yaml
> # List with 3 extra domains
> app_domain_extras:
>   - "hello-world.example.org"
>   - "hello-world.*"
>   - "hello-world.{{ ansible_default_ipv4.address }}.nip.io"
> ```
- **Advanced documentation**
  - Check [NGinx/Server Names for advanced options](http://nginx.org/en/docs/http/server_names.html)

Use this to add extra domains to [app_domain](#app_domain).

#### app_debug
- **Required**: _no_
- **Default**: `alb_forcedebug`<sup>(If defined)</sup>, `alb_default_app_forcedebug`<sup>(If defined)</sup>
- **Type of Value**: _Boolean_
- **Examples of Value**: `yes`, `true`, `no`, `false`

Mark one app in special to show more information, useful for debug. The
information depends on the [app_type](#app_type) implementation.

#### app_forcehttps
- **Required**: _no_
- **Default**: `false`, `alb_default_app_forcehttps`<sup>(If defined)</sup>
- **Type of Value**: _Boolean_
- **Examples of Value**: `yes`, `true`, `no`, `false`

If true, acessing HTTP port will redirect 301 to the `app_domain`.

This option is one alternative to not use Ansible Host vars or Ansible Group
Vars to define what Application run where. So you could have only one `alb_apps`
`alb_sysapps` for the entire cluster (or more than one cluster if using more
than one datacenter).

> @TODO: implement this feature (fititnt, 2019-12-04 22:43 BRT)

#### app_hook_after
- **Required**: _no_
- **Default**: _no default_
- **Type of Value**: _String_ (path to a single Ansible Tasks file to execute)
- **Examples of Value**: `{{ playbook_dir }}/hooks/app-static-html.yml`, `{{ role_path }}/ad-hoc-alb/hooks/debug.yml`, `{{ role_path }}/ad-hoc-alb/hooks/example/example_app_hook_after.yml`

You can execute custom tasks specific to one app after deployed.

#### app_hook_before
- **Required**: _no_
- **Default**: _no default_
- **Type of Value**: _String_ (path to a single Ansible Tasks file to execute)
- **Examples of Value**: `{{ playbook_dir }}/hooks/app-static-html.yml`, `{{ role_path }}/ad-hoc-alb/hooks/debug.yml`, `{{ role_path }}/ad-hoc-alb/hooks/example/example_app_hook_before.yml`


You can execute custom tasks specific to one app after deployed.

#### app_index
- **Required**: _no_
- **Default**: _no default_, `alb_default_app_index`<sup>(If defined)</sup>
- **Type of Value**: _String_ (name of files separed by spaces)
- **Examples of Value**: `index.html index.php`
- **Advanced documentation**
  - <https://docs.nginx.com/nginx/admin-guide/web-server/serving-static-content/>

#### app_root
- **Required**: _no_
- **Default**: _no default_, `alb_default_app_root`<sup>(If defined)</sup>
- **Type of Value**: _String_ (folder path)
- **Examples of Value**: `/var/html/www/`
- **Advanced documentation**
  - <https://docs.nginx.com/nginx/admin-guide/web-server/serving-static-content/#root>


#### app_tags
- **Required**: _no_
- **Default**: _no default_
- **Type of Value**: list of `String`
- **Examples of Value**:

> ```yaml
> # Empty app_tags
> app_domain_extras: []
> # Please avoid using 'app_tags: ' without defined itens and ': []' at the end
> ```
> ```yaml
> # List with 3 extra domains
> app_tags:
>   - "my-tag-1"
>   - "another-tag"
>   - "{{ ansible_default_ipv4.address }}"
> ```

### app_data_*

`app_data_*` are one way to document specific applications that you care about
make backups, or export/import from one node to another. The typical scenario
is you document, at App/Sysapp level, what a different AP-ALB node should have
to be fully operational.

As AP-ALB v0.8.2, this Role alone does not implement the full logistics of how
to make the import/export/backup but you are encoraged to use these variables
as one way to document or reuse future implementations.

Also keep in mind that even if AP-ALB implement these features, is likely that
you would still need configure external services to store backups, since the
priority here would be sincronize 2 nodes that, for example, do not have a
shared (and often sloooow) filesystem.

<!--
- k3s backup/restore procedure [question] #218 https://github.com/rancher/k3s/issues/218
- k3s Backup/restore of master #661 https://github.com/rancher/k3s/issues/661
- https://stackoverflow.com/questions/25675314/how-to-backup-sqlite-database
-->

#### app_data_directories
- **Required**: _no_
- **Default**: _no default_
- **Type of Value**: _list of Strings_ (list of absolute paths of directories on the node)
- **Examples of Value**:
> ```yaml
> app_data_directories:
>   - "/var/www/myapp"
> ```

#### app_data_files
- **Required**: _no_
- **Default**: _no default_
- **Type of Value**: _list of Strings_ (list of absolute paths of directories on the node)
- **Examples of Value**:
> ```yaml
> app_data_files:
>   - "/var/lib/rancher/k3s/server/node-token"
>   - "/var/lib/rancher/k3s/server/db/state.db.bak"
> ```

#### app_data_hook_export_after
- **Required**: _no_
- **Default**: _no default_
- **Type of Value**:  _String_ (Path to a Ansible Tasks file)
- **Examples of Value**: `"{{ playbook_dir }}/delete-temporary-files.yml"`

#### app_data_hook_export_before
- **Required**: _no_
- **Default**: _no default_
- **Type of Value**:  _String_ (Path to a Ansible Tasks file)
- **Examples of Value**: `"{{ playbook_dir }}/database-dump-to-file.yml"`

#### app_data_hook_import_after
- **Required**: _no_
- **Default**: _no default_
- **Type of Value**:  _String_ (Path to a Ansible Tasks file)
- **Examples of Value**: `"{{ playbook_dir }}/populate-database-from-database-dump.yml"`

#### app_data_hook_import_before
- **Required**: _no_
- **Default**: _no default_
- **Type of Value**:  _String_ (Path to a Ansible Tasks file)
- **Examples of Value**: `"{{ playbook_dir }}/install-requeriments-for-this-app-if-already-not-exist.yml"`

### app_*_strategy

#### app_alb_strategy
- **Required**: _always_ (or will be ignored by OpenResty)
- **Default**: _no default_
- **Type of Value**: `String` or _undefined_ or _null_
  - Should be one [ALB Strategies](#alb-strategies)
  - Can be a custom value defined by the user
- **Examples of Value**: `files-local`, `hello-world`, `proxy`, `raw`, `null`

This option define what base OpenResty/NGinx template will be used as base for
process all other variables.

<!--

Note: for sake of simplicity, when using `raw` or your own custom strategy type,
next variables marked just as `**Required**: _yes_` may not be be required, but
often are.

-->

#### app_backup_strategy
> As version v0.8.1-alpha, this app_backup_strategy still not implemented.

#### app_ha_strategy
> As version v0.8.1-alpha, this app_ha_strategy still not implemented.

#### app_nlb_strategy
> As version v0.8.1-alpha, this app_nlb_strategy still not implemented.

<!--
 #### app__proxy_raw
- **app_type**: `proxy`
- **Required**: _no_
- **Type of Value**: list of* Key-Value strings
- **Examples of Value**:
> ```yaml
> # Empty list
> app_domain_extras: []
> # Please avoid using 'app_domain_extras: ' without defined itens and ': []' at the end
> ```
> ```yaml
> # List with 3 extra domains
> app_domain_extras:
>   - "hello-world.example.org"
>   - "hello-world.*"
>   - "hello-world.{{ ansible_default_ipv4.address }}.nip.io"
> ```
-->

<!--
  ### app__raw_*
  #### app__raw_conf_file
  #### app__raw_conf_string
-->

### app_alb_*

#### app_alb_hosts
- **Required**: _no_
- **Default**: _all hosts_
- **Type of Value**: list of `String` equivalent to `{{ inventory_hostname_short }}`
- **Examples of Value**:
> ```yaml
> app_alb_hosts:
>   - "ap_delta"
>   - "ap_echo"
> ```

> @TODO consider implement this planned (but not fully usable) feature as
> additional alternative to Ansible Inventory (fititnt, 2019-12-05 19:17 BRT)

#### app_alb_proxy
- **app_alb_strategy**: `proxy`
- **Required**: _no_
- **Default**: _no default_
- **Type of Value**: _String_
- **Examples of Value**: `http://127.0.0.1:8080`,
- **Advanced documentation**
  - https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/

#### app_alb_proxy_defaults
- **app_type**: `proxy`
- **Default**: true

`app_alb_proxy_defaults` enable defaults inside the main proxy location block, like
these ones:
```
location / {
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    # ...
}
```

Disable if you is having issues or what to make full customization with
`app_alb_proxy_raw`. If you are OK with the defaults, use `app_alb_proxy_params`
to just append new values

#### app_alb_proxy_location
- **app_alb_strategy**: `proxy`
- **Required**: _no_
- **Default**: `/`
- **Type of Value**: _String_
- **Examples of Value**: `/`, `= /`, `~ \.php`
- **Advanced documentation**
  - http://nginx.org/en/docs/http/ngx_http_core_module.html#location

#### app_alb_proxy_params
- **app_alb_strategy**: `proxy`
- **Required**: _no_
- **Default**: _no default_, `alb_default_app_alb_proxy_params`<sup>(If defined)</sup>
- **Examples of Value**:
> ```yaml
> alb_apps:
>   # Laravel example https://laravel.com/docs/deployment
>   - app_uid: "laravel-site"
>   - app_domain: ".example.com"
>   - app_alb_strategy: "proxy"
>   - app_alb_proxy_location: "~ \.php$"
>   - app_alb_proxy: "unix:/var/run/php/php7.4-fpm.sock"
>   - app_alb_proxy_params:
>     - fastcgi_index: "index.php"
>     - fastcgi_param: "SCRIPT_FILENAME $realpath_root$fastcgi_script_name"
>     - include: "fastcgi_params"
> ```

#### app_alb_raw
- **Required**: _no_
- **Default**: _no default_
- **Type of Value**: _String_ (Path to a Jinja2 template file)
- **Examples of Value**:
```yaml
    alb_apps:
      - app_uid: "hello-world-minimal"
        app_domain: "hello-world-minimal.{{ ansible_default_ipv4.address }}.nip.io"
        app_alb_strategy: "minimal"
        app_alb_raw_file: "templates/example_app_alb_raw_file.conf.j2"
        app_alb_raw: >
          charset_types application/json;
          default_type application/json;

          location = /status {
              stub_status;
              allow all;
          }
          location = /ping {
              access_log off;
              return 200 "pong\n";
          }
          location = / {
              content_by_lua_block {
                 local cjson = require "cjson"
                 ngx.status = ngx.HTTP_OK
                 ngx.say(cjson.encode({
                     msg = "Hello, hello-world-minimal! (from app_alb_raw)",
                     status = 200
                 }))
              }
          }
```
See <https://yaml-multiline.info> if having issues with identation.

You can use [app_alb_raw_file](#app_alb_raw_file) as alternative.

#### app_alb_raw_file
- **Required**: _no_
- **Default**: _no default_
- **Type of Value**: _String_ (Path to a Jinja2 template file)
- **Examples of Value**: `templates/example_app_alb_raw_file.conf.j2`

Example of `templates/example_app_alb_raw.conf.j2` content:

```
# File: github.com/fititnt/ansible-linux-ha-cluster/templates/example_app_alb_rawfile.conf.j2
# This file is just one example of using app_alb_raw_file instead of
# app_alb_raw template string

# With app_alb_raw you can't use item.app_uid variable, for example, but here
# you can

location / {
    content_by_lua_block {
       local cjson = require "cjson"
       ngx.status = ngx.HTTP_OK
       ngx.say(cjson.encode({
           msg = "Hello, {{ item.app_uid }}! (from app_alb_raw_file)",
           status = 200
       }))
    }
}
```

### Deprecated app_* variables

#### app_raw_conf
Deprecated. Please use [app_raw_alb](#app_raw_alb) and/or
[app_alb_raw_file](#app_alb_raw_file)

#### No default value for app_alb_strategy
Before AP-ALB v.0.8.x alb_apps[n]app_alb_strategy has default value of
 `hello-word` (and before that,  `files-local`).

Now, value of app_alb_strategy is ommited, the alp_apps / alb_sysapps will be
ignored by OpenResty.

The reason for this is allow on future have apps that can exist only for other
reasons (for example, for NLB/HAProxy, or for Backup tasks). This also means
that a same app group could have variables reused for different strategies

## AP-ALB Application Rules compared to other load balancers

### Azure Load balancer
- <https://docs.microsoft.com/pt-br/azure/load-balancer/>

> @TODO write small paragraph about AP-ALB and Azure Load Balancer (fititnt, 2019-12-15 06:44 BRT)


### AWS Application Load Balancers Listeners
- <https://docs.aws.amazon.com/en_us/elasticloadbalancing/latest/application/load-balancer-listeners.html>

> @TODO write small paragraph about AP-ALB and AWS Application Load Balancers Listeners (fititnt, 2019-12-15 06:44 BRT)

### Google Cloud Load Balancing

- <https://cloud.google.com/load-balancing/docs/apis>

> @TODO write small paragraph about AP-ALB and AWS Google Cloud Load Balancing (fititnt, 2019-12-15 06:44 BRT)
