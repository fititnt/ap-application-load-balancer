# AP-ALB variables

The file [vars/main.yml](main.yml) is always loaded, for all OSs.

## Variables loading order based on operational system

From the 1 (first) to the 4 (last) eacn value found on earlier files can be
overriden by the last ones.

1. [vars/os-family/the-os-family.yml](os-family/)
    1. [vars/os-family/unknown.yml](os-family/unknown.yml) <sup>if running without Ansible detect the OS</sup>
    2. [vars/os-family/untested.yml](os-family/untested.yml) <sup>if runnin a OS without a dedicated file at `vars/os-family/os-family.yml`</sup>
2. [vars/os-family/os-family-version/os-family-VER.yml](os-family/os-family-version)
3. [vars/os-family/distribution/the-os-distro.yml](os-family/distribution/)
4. [vars/os-family/distribution/version/the-os-distro-VER.yml](os-family/distribution/version/)

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