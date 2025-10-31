#!/bin/bash

# Script: getPackageReverseDeps.sh
# Descripción: Obtiene los paquetes que dependen de un paquete específico de pacman
# Devuelve: JSON con la lista de paquetes que requieren este
# Uso: ./getPackageReverseDeps.sh <package_name>

PACKAGE_NAME="$1"

if [ -z "$PACKAGE_NAME" ]; then
    echo '{"error": "Package name is required"}' >&2
    exit 1
fi

# Verificar si el paquete existe
if ! pacman -Q "$PACKAGE_NAME" >/dev/null 2>&1; then
    echo '{"error": "Package not found"}' >&2
    exit 1
fi

# Obtener lista de paquetes que dependen de este
REVERSE_DEPS=$(pacman -Qi "$PACKAGE_NAME" 2>/dev/null | grep -E "^(Required By|Exigido por)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')

# Si no hay dependencias inversas o es "None"/"Nada", crear array vacío
if [ -z "$REVERSE_DEPS" ] || [ "$REVERSE_DEPS" = "None" ] || [ "$REVERSE_DEPS" = "Nada" ]; then
    cat <<EOF
{
  "package": "$PACKAGE_NAME",
  "reverse_dependencies": []
}
EOF
    exit 0
fi

# Convertir dependencias inversas a array JSON
REVERSE_DEPS_ARRAY="["
FIRST=true

# Separar los paquetes (pueden estar separados por espacios)
IFS=' ' read -ra REVERSE_DEP_LIST <<< "$REVERSE_DEPS"

for rev_dep in "${REVERSE_DEP_LIST[@]}"; do
    # Solo procesar si no está vacío
    if [ -n "$rev_dep" ] && [ "$rev_dep" != "None" ] && [ "$rev_dep" != "Nada" ]; then
        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            REVERSE_DEPS_ARRAY="$REVERSE_DEPS_ARRAY, "
        fi
        
        # Obtener información del paquete que depende de este
        if pacman -Q "$rev_dep" >/dev/null 2>&1; then
            # Obtener información detallada del paquete dependiente
            rev_dep_info=$(pacman -Qi "$rev_dep" 2>/dev/null)
            rev_dep_version=$(echo "$rev_dep_info" | grep -E "^(Version|Versión)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
            rev_dep_desc=$(echo "$rev_dep_info" | grep -E "^(Description|Descripción)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
            rev_dep_size=$(echo "$rev_dep_info" | grep -E "^(Installed Size|Tamaño de la instalación)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
            rev_dep_install_reason=$(echo "$rev_dep_info" | grep -E "^(Install Reason|Motivo de la instalación)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
            
            # Convertir el tamaño a bytes
            rev_dep_size_bytes=0
            if [ -n "$rev_dep_size" ]; then
                rev_dep_size_num=$(echo "$rev_dep_size" | sed 's/[[:space:]]*$//' | sed 's/^[[:space:]]*//' | grep -oE '[0-9.]+')
                rev_dep_size_unit=$(echo "$rev_dep_size" | sed 's/[[:space:]]*$//' | sed 's/^[[:space:]]*//' | grep -oE '[KMGTP]iB' | head -1)

                case $rev_dep_size_unit in
                    "KiB") rev_dep_size_bytes=$(echo "$rev_dep_size_num * 1024" | bc -l 2>/dev/null | cut -d '.' -f 1);;
                    "MiB") rev_dep_size_bytes=$(echo "$rev_dep_size_num * 1024 * 1024" | bc -l 2>/dev/null | cut -d '.' -f 1);;
                    "GiB") rev_dep_size_bytes=$(echo "$rev_dep_size_num * 1024 * 1024 * 1024" | bc -l 2>/dev/null | cut -d '.' -f 1);;
                    "TiB") rev_dep_size_bytes=$(echo "$rev_dep_size_num * 1024 * 1024 * 1024 * 1024" | bc -l 2>/dev/null | cut -d '.' -f 1);;
                    *) rev_dep_size_bytes=$(echo "$rev_dep_size_num" | cut -d '.' -f 1 2>/dev/null);;
                esac
            fi
            
            # Escapar caracteres especiales
            rev_dep_version=$(echo "$rev_dep_version" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\\/\\\\/g')
            rev_dep_desc=$(echo "$rev_dep_desc" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\\/\\\\/g')
            
            # Determinar si el paquete dependiente es crítico
            IS_CRITICAL=false
            CRITICAL_PACKAGES="linux linux-lts systemd glibc pacman"
            for critical in $CRITICAL_PACKAGES; do
                if [ "$rev_dep" = "$critical" ] || echo "$rev_dep" | grep -q "^$critical"; then
                    IS_CRITICAL=true
                    break
                fi
            done
            
            # Construir objeto de dependencia inversa
            REVERSE_DEPS_ARRAY="$REVERSE_DEPS_ARRAY{
      \"name\": \"$rev_dep\",
      \"version\": \"$rev_dep_version\",
      \"description\": \"$rev_dep_desc\",
      \"installed_size\": $rev_dep_size_bytes,
      \"install_reason\": \"$rev_dep_install_reason\",
      \"is_system_critical\": $IS_CRITICAL,
      \"is_installed\": true
    }"
        else
            # Si el paquete dependiente no está instalado, solo incluir el nombre
            REVERSE_DEPS_ARRAY="$REVERSE_DEPS_ARRAY{
      \"name\": \"$rev_dep\",
      \"version\": \"\",
      \"description\": \"\",
      \"installed_size\": 0,
      \"install_reason\": \"\",
      \"is_system_critical\": false,
      \"is_installed\": false
    }"
        fi
    fi
done

REVERSE_DEPS_ARRAY="$REVERSE_DEPS_ARRAY]"

# Salida JSON
cat <<EOF
{
  "package": "$PACKAGE_NAME",
  "reverse_dependencies": $REVERSE_DEPS_ARRAY
}
EOF