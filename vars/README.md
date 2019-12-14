# AP-ALB internal variables

> **Hey, are you looking for the variables you are meant to customize? They are
> not here, but at [defaults/main.yml](../defaults/main.yml). And at the
> [README.md](README.md) you also have extra information.**

The file [vars/main.yml](main.yml) is always loaded, for all OSs. All variable
under `var/` are meant to be a place to Ansible Role developers put "internal"
variables, to make easier to not hardcode values on tasks files. To support
multiple operational systems at same time (our case here) this logic actually
make simpler to give long term maintenance!

If you are trying to implement a new distro and/or make more deeper
customizations, you _may_ need to know how these `alb_internal_*` variables are
loaded.

We make heavy use of [include_vars](https://docs.ansible.com/ansible/latest/modules/include_vars_module.html)
and [with_first_found](https://docs.ansible.com/ansible/latest/plugins/lookup/first_found.html)
as you could see on [../tasks/main.yml](../tasks/main.yml) _"Variable loading
based on node Operational System"_. The initial version, without subdirectories,
was inspired on the [openstack/openstack-ansible-galera_server](https://github.com/openstack/openstack-ansible-galera_server).

## Variables loading order based on operational system

From the 1 (first) to the 4 (last) each value found on earlier files can be
overriden by the last ones.

1. [vars/os-family/the-os-family.yml](os-family/)
    1. [vars/os-family/unknown.yml](os-family/unknown.yml) <sup>if running without Ansible detect the OS</sup>
    2. [vars/os-family/untested.yml](os-family/untested.yml) <sup>if runnin a OS without a dedicated file at `vars/os-family/os-family.yml`</sup>
2. [vars/os-family/os-family-version/os-family-VER.yml](os-family/os-family-version)
3. [vars/os-family/distribution/the-os-distro.yml](os-family/distribution/)
4. [vars/os-family/distribution/version/the-os-distro-VER.yml](os-family/distribution/version/)

When using AP-ALB, you will get the real information of what is loaded.
See [example output](#example).

## Special user overides

As defined on [tasks/main.yml](../tasks/main.yml), since Ansible does not
easily allow user customize this type of variable, we provide some special
varialbes that, if exist and point to an YAML file, will replace (or add) what
is already on the base Role:

- `alb_vars_osfamily`
- `alb_vars_osfamilyversion`
- `alb_vars_distribution`
- `alb_vars_distribution_version`

Please onsider can submit a Pull Request or open an issue to comment
improvements that you had to make use these special variables.

## Note about lists (arrays)

Note that when replacing a list, like this:

```yaml
alb_internal_bootstrap_extra_tools:
  - name: py36-pip
    state: present
  - name: nmap
    state: present
```

Even if you want just `py36-pip` with `py37-pip`, you will need to override
the complete list `alb_internal_bootstrap_extra_tools`.

## Example

For a directory structure like this one

```bash
# fititnt at bravo in /alligo/code/fititnt/ap-application-load-balancer/vars on git:master x [18:09:16]
$ tree
.
├── main.yml
├── os-family
│   ├── archlinux.yml
│   ├── debian.yml
│   ├── distribution
│   │   ├── cloudlinux.yml
│   │   ├── no-os-family-customization.yml
│   │   ├── ubuntu.yml
│   │   └── version
│   │       ├── debian-10.yml
│   │       ├── debian-11.yml
│   │       ├── debian-9.yml
│   │       ├── no-distribution-customization.yml
│   │       └── ubuntu-18.yml
│   ├── freebsd.yml
│   ├── os-family-version
│   │   ├── no-os-family-version-customization.yml
│   │   └── redhat-7.yml
│   ├── redhat.yml
│   ├── suse.yml
│   ├── unknown.yml
│   └── untested.yml
└── README.md

4 directories, 19 files
```

And one **Ubuntu Server 18.04**, a **Debian 10**, one **FreeBSD 12**, a **CentOS 7** and one
**CentOS 8**:

```bash
TASK [ap-application-load-balancer : ALB | OS Family variables] ********************************************************************
ok: [ap_echo_ubuntu18] => (item=(...)ap-application-load-balancer/vars/os-family/debian.yml)
ok: [ap_foxtrot_debian10] => (item=(...)ap-application-load-balancer/vars/os-family/debian.yml)
ok: [rocha_basalto_freebsd12] => (item=(...)ap-application-load-balancer/vars/os-family/freebsd.yml)
ok: [ap_golf_centos7] => (item=(...)ap-application-load-balancer/vars/os-family/redhat.yml)
ok: [rocha_anortosito_centos8] => (item=(...)ap-application-load-balancer/vars/os-family/redhat.yml)

TASK [ap-application-load-balancer : ALB | OS Family version variables] ************************************************************
ok: [ap_echo_ubuntu18] => (item=(...)ap-application-load-balancer/vars/os-family/os-family-version/no-os-family-version-customization.yml)
ok: [ap_foxtrot_debian10] => (item=(...)ap-application-load-balancer/vars/os-family/os-family-version/no-os-family-version-customization.yml)
ok: [ap_golf_centos7] => (item=(...)ap-application-load-balancer/vars/os-family/os-family-version/redhat-7.yml)
ok: [rocha_basalto_freebsd12] => (item=(...)ap-application-load-balancer/vars/os-family/os-family-version/no-os-family-version-customization.yml)
ok: [rocha_anortosito_centos8] => (item=(...)ap-application-load-balancer/vars/os-family/os-family-version/no-os-family-version-customization.yml)

TASK [ap-application-load-balancer : ALB | Distribution variables (may override OS Family variables, if exist)] ********************
ok: [ap_echo_ubuntu18] => (item=(...)ap-application-load-balancer/vars/os-family/distribution/ubuntu.yml)
ok: [ap_foxtrot_debian10] => (item=(...)ap-application-load-balancer/vars/os-family/distribution/no-os-family-customization.yml)
ok: [ap_golf_centos7] => (item=(...)ap-application-load-balancer/vars/os-family/distribution/no-os-family-customization.yml)
ok: [rocha_anortosito_centos8] => (item=(...)ap-application-load-balancer/vars/os-family/distribution/no-os-family-customization.yml)
ok: [rocha_basalto_freebsd12] => (item=(...)ap-application-load-balancer/vars/os-family/distribution/no-os-family-customization.yml)

TASK [ap-application-load-balancer : ALB | Specific version distribution variables (may override OS Family and Distribution variables, if exist)] ***
ok: [ap_echo_ubuntu18] => (item=(...)ap-application-load-balancer/vars/os-family/distribution/version/ubuntu-18.yml)
ok: [ap_foxtrot_debian10] => (item=(...)ap-application-load-balancer/vars/os-family/distribution/version/debian-10.yml)
ok: [rocha_basalto_freebsd12] => (item=(...)ap-application-load-balancer/vars/os-family/distribution/version/no-distribution-customization.yml)
ok: [ap_golf_centos7] => (item=(...)ap-application-load-balancer/vars/os-family/distribution/version/no-distribution-customization.yml)
ok: [rocha_anortosito_centos8] => (item=(...)ap-application-load-balancer/vars/os-family/distribution/version/no-distribution-customization.yml)
```

* "(...)" means a full path. This is ommited here to make shorter output. 