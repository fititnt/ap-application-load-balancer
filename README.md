# AP Application Load Balancer

```bash
tail -f /var/log/application_load_balancer/access.log
tail -f /var/log/application_load_balancer/error.log
```

Um guia sem automação de ansible de como fazer algo parecido pode ser lido em
<https://github.com/EticaAI/aguia-pescadora/blob/master/diario-de-bordo/tsuru-inicializacao/seu-computador.sh>.

Veja também

- https://github.com/fititnt/cplp-aiops/issues/58
- https://github.com/fititnt/cplp-aiops/issues/59
- https://github.com/fititnt/cplp-aiops/tree/master/logbook/aguia-pescadora-charlie/__external-configs
- https://github.com/EticaAI/aguia-pescadora/issues/26
- https://github.com/EticaAI/aguia-pescadora/blob/master/diario-de-bordo/delta.sh


Arquivos 

- Erros do OpenResty (NGinx, AutoSSL, proxy de entrada...)
    - `tail -f /usr/local/openresty/nginx/logs/error.log`
    - `tail -f /var/log/openrestyautossl/error.log`
- Acesso do OpenResty (NGinx, AutoSSL, proxy de entrada...)
    - `tail -f /usr/local/openresty/nginx/logs/access.log`
    - `tail -f /var/log/openrestyautossl/access.log`

Dica: você pode usar também o ngxtop <https://github.com/lebinh/ngxtop>.

Requirements
------------

- Ubuntu
  - Ubuntu 18.04 (Recommended)

Role Variables
--------------

[defaults/main.yml](defaults/main.yml)

Dependencies
------------

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }

License
-------

Public Domain
