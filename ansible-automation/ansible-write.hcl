# Чтение и запись в нужные пути
path "secret/data/applications/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Чтение метаданных (нужно для CAS при обновлении)
path "secret/metadata/applications/*" {
  capabilities = ["read", "list"]
}
