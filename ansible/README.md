# ansible/ — Configuración del sistema operativo

Este directorio contiene los playbooks y roles de Ansible que transforman las VMs creadas por Terraform en nodos listos para correr K3s, más un servidor OpenLDAP independiente.

## ¿Qué hace?

| Orden | Playbook | Roles/Acciones | Hosts |
|---|---|---|---|
| 1 | `playbooks/01-hardening.yml` | SSH seguro, UFW, fail2ban | `managed` |
| 2 | `playbooks/02-nfs.yml` | Montaje de shares NFS/SMB | `k8s_cluster` |
| 3 | `playbooks/03-k3s.yml` | Instala K3s master + workers | `k8s_cluster` |
| 4 | `playbooks/04-ldap.yml` | OpenLDAP, estructura y políticas | `identity_servers` |

El orquestador principal es [`site.yml`](site.yml).

## Estructura

```text
ansible/
├── ansible.cfg                 # Configuración de Ansible
├── site.yml                    # Importa los 4 playbooks en orden
├── inventory.yml               # IPs estáticas de las VMs
├── requirements.yml            # Colecciones/roles de Galaxy
├── group_vars/
│   ├── all.yml                 # Variables comunes
│   └── vault.yml               # Secretos cifrados con ansible-vault
├── playbooks/
│   ├── 01-hardening.yml
│   ├── 02-nfs.yml
│   ├── 03-k3s.yml
│   └── 04-ldap.yml
└── roles/
    ├── hardening/              # SSH, firewall, fail2ban
    ├── k3s/                    # Instalación y join de nodos
    ├── ldap/                   # Servidor OpenLDAP
    └── nfs/                    # Montaje de almacenamiento
```

## Inventario

El inventario usa IPs estáticas asignadas por Terraform:

| Grupo | Hosts |
|---|---|
| `k8s_masters` | `k8s-master-01` (`10.10.10.11`) |
| `k8s_workers` | `k8s-worker-01` (`10.10.10.12`), `k8s-worker-02` (`10.10.10.13`) |
| `identity_servers` | `ldap-server` (`10.10.10.20`) |
| `managed` | Todos los anteriores |

## Cómo ejecutar

```bash
cd ansible/

# Verificar conectividad
ansible all -m ping --vault-password-file ~/.vault_pass

# Ejecutar todo
ansible-playbook site.yml --vault-password-file ~/.vault_pass

# Ejecutar solo una parte
ansible-playbook site.yml -t hardening --vault-password-file ~/.vault_pass
ansible-playbook site.yml -t nfs --vault-password-file ~/.vault_pass
ansible-playbook site.yml -t k3s --vault-password-file ~/.vault_pass
ansible-playbook site.yml -t ldap --vault-password-file ~/.vault_pass

# En despliegue local sin NAS, omitir NFS
ansible-playbook site.yml --skip-tags nfs --vault-password-file ~/.vault_pass
```

## Secretos

Las contraseñas y tokens sensibles viven en [`group_vars/vault.yml`](group_vars/vault.yml) y deben estar cifrados con Ansible Vault:

```bash
# Crear/editar secretos
ansible-vault create group_vars/vault.yml
ansible-vault edit group_vars/vault.yml

# Cifrar un vault existente
ansible-vault encrypt group_vars/vault.yml
```

El fichero `~/.vault_pass` es local y nunca se versiona.

## Validación

Tras ejecutar los playbooks, verifica que K3s está levantado:

```bash
ssh arq3d@10.10.10.11 "kubectl get nodes"
```

## Enlaces

- [README principal](../README.md)
- [Runbook de bootstrap](../docs/runbooks/bootstrap.md)
- [Runbook de despliegue local](../docs/runbooks/local-deployment.md)
- [Decisiones técnicas](../docs/decisions/)
