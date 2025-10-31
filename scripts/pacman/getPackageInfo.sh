#!/bin/bash

# Script: getPackageInfo.sh
# Descripción: Obtiene información detallada de un paquete de pacman incluyendo análisis de seguridad
# Devuelve: JSON con información del paquete y evaluación de seguridad
# Uso: ./getPackageInfo.sh <package_name>

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

# Obtener toda la información del paquete de una sola vez
info=$(pacman -Qi "$PACKAGE_NAME" 2>/dev/null)

if [ -n "$info" ]; then
    # Extraer cada campo de la información del paquete
    version=$(echo "$info" | grep -E "^(Version|Versión)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
    desc=$(echo "$info" | grep -E "^(Description|Descripción)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
    install_date=$(echo "$info" | grep -E "^(Install Date|Fecha de instalación)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
    build_date=$(echo "$info" | grep -E "^(Build Date|Fecha de creación)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
    install_reason=$(echo "$info" | grep -E "^(Install Reason|Motivo de la instalación)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
    size=$(echo "$info" | grep -E "^(Installed Size|Tamaño de la instalación)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
    required_by=$(echo "$info" | grep -E "^(Required By|Exigido por)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
    depends_on=$(echo "$info" | grep -E "^(Depends On|Depende de)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
    
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
    
    # Análisis de seguridad
    # Determinar si es un paquete huérfano
    IS_ORPHAN=false
    if [ "$install_reason" = "As a dependency" ] || [ "$install_reason" = "Como dependencia" ]; then
        # Verificar si realmente es huérfano (no requerido por nadie)
        if [ -z "$required_by" ] || [ "$required_by" = "None" ] || [ "$required_by" = "Nada" ]; then
            IS_ORPHAN=true
        fi
    fi

    # Verificar si es un paquete crítico del sistema
    IS_SYSTEM_CRITICAL=false
    CRITICAL_PACKAGES="linux linux-lts systemd glibc pacman"
    for critical in $CRITICAL_PACKAGES; do
        if [ "$PACKAGE_NAME" = "$critical" ] || echo "$PACKAGE_NAME" | grep -q "^$critical"; then
            IS_SYSTEM_CRITICAL=true
            break
        fi
    done

    # Determinar si tiene dependencias directas e inversas
    HAS_DIRECT_DEPS=false
    HAS_REVERSE_DEPS=false
    
    if [ -n "$depends_on" ] && [ "$depends_on" != "None" ] && [ "$depends_on" != "Nada" ]; then
        HAS_DIRECT_DEPS=true
    fi
    
    if [ -n "$required_by" ] && [ "$required_by" != "None" ] && [ "$required_by" != "Nada" ]; then
        HAS_REVERSE_DEPS=true
    fi

    # Calcular puntuación de seguridad (0-100, donde 100 es completamente seguro de eliminar)
    SAFETY_SCORE=50

    if [ "$IS_ORPHAN" = true ]; then
        SAFETY_SCORE=80  # Más seguro si es huérfano
    elif [ "$HAS_REVERSE_DEPS" = false ]; then
        SAFETY_SCORE=70  # Seguro si no tiene dependencias inversas
    else
        SAFETY_SCORE=20  # Menos seguro si otros paquetes dependen de él
        SAFETY_SCORE=$((SAFETY_SCORE - 10))  # Penalización adicional
    fi

    if [ "$IS_SYSTEM_CRITICAL" = true ]; then
        SAFETY_SCORE=0  # Nada seguro si es crítico
    fi

    # Preparar razones
    REASONS_NOT_SAFE=()
    if [ "$IS_SYSTEM_CRITICAL" = true ]; then
        REASONS_NOT_SAFE+=("Critical system package")
    fi

    if [ "$HAS_REVERSE_DEPS" = true ]; then
        REASONS_NOT_SAFE+=("Required by other packages")
    fi

    # Convertir arrays a formato JSON
    REASONS_JSON="["
    FIRST=true
    for reason in "${REASONS_NOT_SAFE[@]}"; do
        if [ -n "$reason" ]; then
            if [ "$FIRST" = true ]; then
                FIRST=false
            else
                REASONS_JSON="$REASONS_JSON, "
            fi
            REASONS_JSON="$REASONS_JSON\"$reason\""
        fi
    done
    REASONS_JSON="$REASONS_JSON]"

    # Determinar si es seguro
    IS_SAFE_TO_REMOVE=false
    if [ $SAFETY_SCORE -ge 70 ]; then
        IS_SAFE_TO_REMOVE=true
    fi
    
    # Escapar caracteres especiales en los strings para JSON
    version=$(echo "$version" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\\/\\\\/g')
    desc=$(echo "$desc" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\\/\\\\/g')
    install_date=$(echo "$install_date" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\\/\\\\/g')
    build_date=$(echo "$build_date" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\\/\\\\/g')
    install_reason=$(echo "$install_reason" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\\/\\\\/g')
    size=$(echo "$size" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\\/\\\\/g')
    
    # Salida JSON
    cat <<EOF
{
  "name": "$PACKAGE_NAME",
  "version": "$version",
  "description": "$desc",
  "install_date": "$install_date",
  "build_date": "$build_date",
  "install_reason": "$install_reason",
  "installed_size": $size_bytes,
  "has_dependencies": $HAS_DIRECT_DEPS,
  "has_reverse_dependencies": $HAS_REVERSE_DEPS,
  "is_safe_to_remove": $IS_SAFE_TO_REMOVE,
  "reasons_not_safe": $REASONS_JSON,
  "is_system_critical": $IS_SYSTEM_CRITICAL,
  "is_orphan": $IS_ORPHAN,
  "safety_score": $SAFETY_SCORE
}
EOF
else
    # Si no se pudo obtener información, retornar error
    echo '{"error": "Could not retrieve package information"}' >&2
    exit 1
fi