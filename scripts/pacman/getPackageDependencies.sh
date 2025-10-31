#!/bin/bash

# Script: getPackageDependencies.sh
# Descripción: Obtiene las dependencias directas de un paquete de pacman
# Devuelve: JSON con la lista de dependencias y su información
# Uso: ./getPackageDependencies.sh <package_name>

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

# Obtener lista de dependencias directas
DEPS=$(pacman -Qi "$PACKAGE_NAME" 2>/dev/null | grep -E "^(Depends On|Depende de)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')

# Si no hay dependencias o es "None"/"Nada", crear array vacío
if [ -z "$DEPS" ] || [ "$DEPS" = "None" ] || [ "$DEPS" = "Nada" ]; then
    cat <<EOF
{
  "package": "$PACKAGE_NAME",
  "dependencies": []
}
EOF
    exit 0
fi

# Convertir dependencias a array JSON
DEPS_ARRAY="["
FIRST=true

# Separar las dependencias (pueden estar separadas por espacios)
IFS=' ' read -ra DEP_LIST <<< "$DEPS"

for dep in "${DEP_LIST[@]}"; do
    # Limpiar la dependencia (eliminar condiciones como >=, <=, =)
    CLEAN_DEP=$(echo "$dep" | sed 's/[<>=].*//')
    
    # Solo procesar si no está vacío
    if [ -n "$CLEAN_DEP" ] && [ "$CLEAN_DEP" != "None" ] && [ "$CLEAN_DEP" != "Nada" ]; then
        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            DEPS_ARRAY="$DEPS_ARRAY, "
        fi
        
        # Obtener información de la dependencia si está instalada
        if pacman -Q "$CLEAN_DEP" >/dev/null 2>&1; then
            # Obtener información detallada de la dependencia
            dep_info=$(pacman -Qi "$CLEAN_DEP" 2>/dev/null)
            dep_version=$(echo "$dep_info" | grep -E "^(Version|Versión)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
            dep_desc=$(echo "$dep_info" | grep -E "^(Description|Descripción)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
            dep_size=$(echo "$dep_info" | grep -E "^(Installed Size|Tamaño de la instalación)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
            dep_install_reason=$(echo "$dep_info" | grep -E "^(Install Reason|Motivo de la instalación)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
            
            # Convertir el tamaño a bytes
            dep_size_bytes=0
            if [ -n "$dep_size" ]; then
                dep_size_num=$(echo "$dep_size" | sed 's/[[:space:]]*$//' | sed 's/^[[:space:]]*//' | grep -oE '[0-9.]+')
                dep_size_unit=$(echo "$dep_size" | sed 's/[[:space:]]*$//' | sed 's/^[[:space:]]*//' | grep -oE '[KMGTP]iB' | head -1)

                case $dep_size_unit in
                    "KiB") dep_size_bytes=$(echo "$dep_size_num * 1024" | bc -l 2>/dev/null | cut -d '.' -f 1);;
                    "MiB") dep_size_bytes=$(echo "$dep_size_num * 1024 * 1024" | bc -l 2>/dev/null | cut -d '.' -f 1);;
                    "GiB") dep_size_bytes=$(echo "$dep_size_num * 1024 * 1024 * 1024" | bc -l 2>/dev/null | cut -d '.' -f 1);;
                    "TiB") dep_size_bytes=$(echo "$dep_size_num * 1024 * 1024 * 1024 * 1024" | bc -l 2>/dev/null | cut -d '.' -f 1);;
                    *) dep_size_bytes=$(echo "$dep_size_num" | cut -d '.' -f 1 2>/dev/null);;
                esac
            fi
            
            # Escapar caracteres especiales
            dep_version=$(echo "$dep_version" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\\/\\\\/g')
            dep_desc=$(echo "$dep_desc" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\\/\\\\/g')
            
            # Verificar si es una dependencia huérfana o compartida
            dep_required_by=$(echo "$dep_info" | grep -E "^(Required By|Exigido por)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
            is_orphan=false
            if [ "$dep_install_reason" = "As a dependency" ] || [ "$dep_install_reason" = "Como dependencia" ]; then
                if [ -z "$dep_required_by" ] || [ "$dep_required_by" = "None" ] || [ "$dep_required_by" = "Nada" ]; then
                    is_orphan=true
                fi
            fi
            
            # Construir objeto de dependencia
            DEPS_ARRAY="$DEPS_ARRAY{
      \"name\": \"$CLEAN_DEP\",
      \"version\": \"$dep_version\",
      \"description\": \"$dep_desc\",
      \"installed_size\": $dep_size_bytes,
      \"install_reason\": \"$dep_install_reason\",
      \"is_orphan\": $is_orphan,
      \"is_installed\": true
    }"
        else
            # Si la dependencia no está instalada, solo incluir el nombre
            DEPS_ARRAY="$DEPS_ARRAY{
      \"name\": \"$CLEAN_DEP\",
      \"version\": \"\",
      \"description\": \"\",
      \"installed_size\": 0,
      \"install_reason\": \"\",
      \"is_orphan\": false,
      \"is_installed\": false
    }"
        fi
    fi
done

DEPS_ARRAY="$DEPS_ARRAY]"

# Salida JSON
cat <<EOF
{
  "package": "$PACKAGE_NAME",
  "dependencies": $DEPS_ARRAY
}
EOF