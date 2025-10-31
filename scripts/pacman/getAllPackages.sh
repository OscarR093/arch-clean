#!/bin/bash

# Script: getAllPackages.sh
# Descripción: Obtiene todos los paquetes instalados con pacman
# Devuelve: JSON con información compatible con la estructura Package en Rust
# Uso: ./getAllPackages.sh

# Variable para acumular la información de paquetes
packages_json=""

# Obtener paquetes instalados manualmente (no como dependencias)
while IFS= read -r package; do
    # Obtener toda la información del paquete de una sola vez
    info=$(pacman -Qiq "$package" 2>/dev/null)
    
    if [ -n "$info" ]; then
        # Extraer cada campo de la información del paquete
        # Adaptado para funcionar con diferentes configuraciones regionales
        version=$(echo "$info" | grep -E "^(Version|Versión)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
        desc=$(echo "$info" | grep -E "^(Description|Descripción)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
        install_date=$(echo "$info" | grep -E "^(Install Date|Fecha de instalación)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
        install_reason=$(echo "$info" | grep -E "^(Install Reason|Motivo de la instalación)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
        size=$(echo "$info" | grep -E "^(Installed Size|Tamaño de la instalación)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
        
        # Convertir el tamaño a bytes para cálculos posteriores
        size_bytes=0
        if [ -n "$size" ]; then
            # Extraer el número y unidad del tamaño
            size_num=$(echo "$size" | sed 's/[[:space:]]*$//' | sed 's/^[[:space:]]*//' | grep -oE '[0-9.]+')
            size_unit=$(echo "$size" | sed 's/[[:space:]]*$//' | sed 's/^[[:space:]]*//' | grep -oE '[KMGTP]iB' | head -1)

            # Convertir según la unidad
            case $size_unit in
                "KiB") size_bytes=$(echo "$size_num * 1024" | bc -l 2>/dev/null | cut -d '.' -f 1);;
                "MiB") size_bytes=$(echo "$size_num * 1024 * 1024" | bc -l 2>/dev/null | cut -d '.' -f 1);;
                "GiB") size_bytes=$(echo "$size_num * 1024 * 1024 * 1024" | bc -l 2>/dev/null | cut -d '.' -f 1);;
                "TiB") size_bytes=$(echo "$size_num * 1024 * 1024 * 1024 * 1024" | bc -l 2>/dev/null | cut -d '.' -f 1);;
                *) size_bytes=$(echo "$size_num" | cut -d '.' -f 1 2>/dev/null);;  # Bytes directos si no hay unidad
            esac
        fi
        
        # Escapar caracteres especiales en los strings para JSON
        # Usar jq si está disponible para escapar correctamente
        if command -v jq >/dev/null 2>&1; then
            package_json=$(jq -n --arg name "$package" --arg version "$version" --arg desc "$desc" --arg install_date "$install_date" --arg install_reason "$install_reason" --argjson size_bytes "$size_bytes" '{
                name: $name,
                version: $version,
                description: $desc,
                install_date: $install_date,
                installed_size: $size_bytes,
                install_reason: $install_reason
            }')
        else
            # Si jq no está disponible, usar métodos bash para escapar
            # Escapar caracteres especiales en los strings para JSON
            version=$(printf '%s\n' "$version" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\r/\\r/g; s/\n/\\n/g')
            desc=$(printf '%s\n' "$desc" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\r/\\r/g; s/\n/\\n/g')
            install_date=$(printf '%s\n' "$install_date" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\r/\\r/g; s/\n/\\n/g')
            install_reason=$(printf '%s\n' "$install_reason" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\r/\\r/g; s/\n/\\n/g')
            
            package_json="    {
      \"name\": \"$package\",
      \"version\": \"$version\",
      \"description\": \"$desc\",
      \"install_date\": \"$install_date\",
      \"installed_size\": $size_bytes,
      \"install_reason\": \"$install_reason\"
    }"
        fi
        
        # Agregar coma si no es el primer elemento
        if [ -n "$packages_json" ]; then
            packages_json="$packages_json,$package_json"
        else
            packages_json="$package_json"
        fi
    fi
done < <(pacman -Qeq 2>/dev/null)

# Imprimir el array JSON completo
echo "["
echo "$packages_json"
echo "]"