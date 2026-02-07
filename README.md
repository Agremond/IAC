IAC Project
# IAC — Infrastructure as Code

Проект автоматизации инфраструктуры и настройки безопасности серверов с использованием **Ansible**.

Основной фокус — безопасная начальная настройка серверов, ротация паролей root, интеграция с HashiCorp Vault для хранения секретов.

## Основные возможности

- Начальная настройка («бутстрап») новых серверов  
  - Создание административного пользователя  
  - Настройка sudo без пароля  
  - Добавление SSH-ключа и отключение root-доступа по паролю  
- Ротация пароля root (две реализации)  
  - v1 — генерация пароля на контроллере + запись в Vault  
  - v2 — генерация пароля **внутри Vault** по заданной политике (рекомендуемый способ)  
- Хранение секретов в **HashiCorp Vault** (KV v2 + AppRole аутентификация)  
- Разделение окружений: dev / test / prod  
- Кастомные фильтры и оптимизированная конфигурация Ansible

## Требования

- Ansible ≥ 2.14 (рекомендуется последняя стабильная версия)
- Python 3.9+
- Доступ к HashiCorp Vault (KV v2 + включённые password-политики для v2)
- Установленные коллекции (см. ниже)

### Установка зависимостей

```bash
# Установка коллекций
./galaxy.sh
# или вручную:
ansible-galaxy collection install -r ansible-automation/collections/requirements.yml

# (опционально) установка python-зависимостей, если используете кастомные плагины
pip install -r requirements.txt
```
### Настройка
Получите ID и токен для доступа к хранилищу паролей
```bash

[root@mskd-vault ~]# vault read auth/approle/role/ansible-role/role-id
Key        Value
---        -----
role_id    9317ceb2-9257-890b-d1da-5979c092b88b

[root@mskd-vault ~]# vault write -f auth/approle/role/ansible-role/secret-id
Key                   Value
---                   -----
secret_id             ac04f6a6-5a70-3b68-82aa-ff330e423664
secret_id_accessor    bba77148-6cf1-e46e-077d-5cae9996d8e8
secret_id_num_uses    0
secret_id_ttl         720h
```

Настройте подключение к Vault в переменных окружения (или в group_vars / ansible-vault):
```bash
export VAULT_ADDR="https://vault.example.com"
export VAULT_ROLE_ID="your-approle-role-id"
export VAULT_SECRET_ID="your-approle-secret-id"
```
Настройте инвентари в папках hosts/dev, hosts/test, hosts/prod находятся файлы инвентари и group_vars/all.yml.
Укажите свои хосты и нужные переменные.
Проверьте ansible.cfg
Конфигурация уже оптимизирована для скорости и удобства отладки.

### Использование

1. Начальная настройка сервера (bootstrap)

```Bash
ansible-playbook \
  -i hosts/dev/inventory \
  playbooks/security/bootstrap.yml \
  --ask-pass
  
 ansible-playbook \
 -i hosts/prod/inventory \
 playbooks/security/rotate-root-password.yml \
 -e "ansible_ssh_extra_args='-o PubkeyAuthentication=no -o PreferredAuthentications=password'" \
 --ask-pass --ask-become-pass
```  

После выполнения рекомендуется отключить парольный доступ по SSH.


2. Ротация пароля root
```Bash
ansible-playbook \
  -i hosts/prod/inventory \
  playbooks/security/rotate-root-password-v2.yml  --ask-become-pass
```  
Пароль будет сгенерирован внутри Vault по политике strong-root и записан в KV-путь:
```text
secret/data/servers/root-passwords/{{ inventory_hostname }}
```
