# AP-ALB vars/os-family/os-family-version
Since `vars/os-family/family.yml` should idealy contain the most updated version
for each base family, the directory `vars/os-family/os-family-version` should
contain any customization to older, but yet supported, OS versions.

Most of the time, these variables could be at
`vars/os-family/distribution/my-distro.yml` and/or at
`vars/os-family/distribution/version/my-distro-123.yml` but some base OS
families, like RHEL, are used by so many other OSs that is more easy have some
simpler customization about the base version.

## About precedence

Variables on this folder replace the ones from the `vars/os-family/family.yml`
(are the 2nd to be injected), but can be replaced by
`vars/os-family/distribution/my-distro.yml` and
`vars/os-family/distribution/version/my-distro-123.yml`.