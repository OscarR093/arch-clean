# Módulo Pacman

Este módulo contiene scripts para interactuar con el gestor de paquetes pacman de Arch Linux.

## Scripts Disponibles

### `getAllPackages.sh`

**Descripción:** Obtiene todos los paquetes instalados con pacman y devuelve la información en formato JSON.

### `getPackageInfo.sh`

**Descripción:** Obtiene información detallada de un paquete específico de pacman, incluyendo análisis de seguridad para determinar si es seguro desinstalarlo.

**Uso:** `./getPackageInfo.sh nombre-del-paquete`

**Salida:**
```json
{
  "name": "nombre-del-paquete",
  "version": "versión-del-paquete",
  "description": "descripción-del-paquete",
  "install_date": "fecha-de-instalación",
  "build_date": "fecha-de-compilación",
  "install_reason": "razón-de-instalación",
  "installed_size": tamaño-en-bytes,
  "has_dependencies": true/false,
  "has_reverse_dependencies": true/false,
  "is_safe_to_remove": true/false,
  "reasons_not_safe": ["razón1", "razón2"],
  "is_system_critical": true/false,
  "is_orphan": true/false,
  "safety_score": 0-100
}
```

**Campos de seguridad:**
- `is_safe_to_remove`: Indica si es seguro desinstalar el paquete
- `reasons_not_safe`: Lista de razones por las que no sería seguro eliminar el paquete
- `has_reverse_dependencies`: Booleano que indica si hay paquetes que dependen de este (lista completa en `getPackageReverseDeps.sh`)
- `is_system_critical`: Indica si es un paquete crítico del sistema
- `is_orphan`: Indica si el paquete es una dependencia huérfana
- `safety_score`: Puntuación numérica de seguridad (0-100)

**Criterios de seguridad:**
- Paquetes huérfanos (instalados como dependencias pero no requeridos) = más seguros de eliminar
- Paquetes críticos del sistema = inseguros de eliminar
- Paquetes con dependencias inversas = potencialmente inseguros de eliminar

### `getPackageDependencies.sh`

**Descripción:** Obtiene las dependencias directas de un paquete de pacman con información detallada.

**Uso:** `./getPackageDependencies.sh nombre-del-paquete`

**Salida:**
```json
{
  "package": "nombre-del-paquete",
  "dependencies": [
    {
      "name": "nombre-de-la-dependencia",
      "version": "versión-de-la-dependencia",
      "description": "descripción-de-la-dependencia",
      "installed_size": tamaño-en-bytes,
      "install_reason": "razón-de-instalación",
      "is_orphan": true/false,
      "is_installed": true/false
    }
  ]
}
```

**Campos de dependencia:**
- `name`: Nombre de la dependencia
- `version`: Versión de la dependencia
- `description`: Descripción de la dependencia
- `installed_size`: Tamaño instalado en bytes
- `install_reason`: Cómo fue instalada la dependencia
- `is_orphan`: Si la dependencia es un paquete huérfano
- `is_installed`: Si la dependencia está instalada en el sistema

### `getPackageReverseDeps.sh`

**Descripción:** Obtiene los paquetes que dependen de un paquete específico de pacman.

**Uso:** `./getPackageReverseDeps.sh nombre-del-paquete`

**Salida:**
```json
{
  "package": "nombre-del-paquete",
  "reverse_dependencies": [
    {
      "name": "nombre-del-paquete-dependiente",
      "version": "versión-del-paquete-dependiente", 
      "description": "descripción-del-paquete-dependiente",
      "installed_size": tamaño-en-bytes,
      "install_reason": "razón-de-instalación",
      "is_system_critical": true/false,
      "is_installed": true/false
    }
  ]
}
```

**Campos de dependencia inversa:**
- `name`: Nombre del paquete que depende del original
- `version`: Versión del paquete dependiente
- `description`: Descripción del paquete dependiente
- `installed_size`: Tamaño instalado en bytes
- `install_reason`: Cómo fue instalado el paquete dependiente
- `is_system_critical`: Si el paquete dependiente es crítico para el sistema
- `is_installed`: Si el paquete dependiente está instalado

### `getAllPackages.sh`

**Descripción:** Obtiene todos los paquetes instalados con pacman y devuelve la información en formato JSON.

**Uso:** `./getAllPackages.sh`

**Salida:**
```json
[
  {
    "name": "nombre-del-paquete",
    "version": "versión-del-paquete",
    "description": "descripción-del-paquete",
    "install_date": "fecha-de-instalación",
    "build_date": "fecha-de-compilación",
    "install_reason": "razón-de-instalación",
    "installed_size": tamaño-en-bytes,
    "has_dependencies": true
  }
]
```

**Campos:**
- `name`: Nombre del paquete
- `version`: Versión instalada del paquete
- `description`: Descripción del paquete
- `install_date`: Fecha en que fue instalado el paquete
- `build_date`: Fecha de compilación del paquete
- `install_reason`: Cómo fue instalado (Explicitly installed o as a dependency)
- `installed_size`: Tamaño instalado en bytes
- `has_dependencies`: Indica si el paquete tiene dependencias (siempre true para este script)

**Funcionamiento paso a paso:**

1. `#!/bin/bash` - Shebang para indicar que es un script de bash
2. `echo "["` - Imprime el inicio del array JSON
3. `first=true` - Variable para controlar la coma entre elementos del JSON
4. `pacman -Qeq 2>/dev/null | while read -r package; do` - 
   - `pacman -Qeq` lista paquetes instalados manualmente (no como dependencias)
   - `2>/dev/null` redirige errores para evitar mensajes si hay paquetes huérfanos
   - `while read -r package; do` itera sobre cada paquete
5. `info=$(pacman -Qiq "$package" 2>/dev/null)` - 
   - Obtiene toda la información detallada del paquete
   - `pacman -Qiq` proporciona información completa de un paquete instalado
6. `version=$(echo "$info" | grep -E "^(Version|Versión)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')` - 
   - Extrae la línea que contiene "Version" o "Versión" (soporte multilenguaje)
   - Toma solo el valor después de los dos puntos
   - Elimina espacios al inicio y al final
7. `install_date=$(echo "$info" | grep -E "^(Install Date|Fecha de instalación)" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')` - 
   - Similar a la versión pero para la fecha de instalación
8. `size_num=$(echo "$size" | sed 's/[[:space:]]*$//' | sed 's/^[[:space:]]*//' | grep -oE '[0-9.]+')` - Extrae el número del tamaño limpiando espacios
9. `size_unit=$(echo "$size" | sed 's/[[:space:]]*$//' | sed 's/^[[:space:]]*//' | grep -oE '[KMGTP]iB' | head -1)` - Extrae la unidad del tamaño
10. `case $size_unit in ... esac` - Convierte el tamaño a bytes según la unidad
11. `version=$(echo "$version" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\\/\\\\/g')` - 
    - Escapa comillas dobles
    - Reemplaza saltos de línea con \\n
    - Escapa barras invertidas
12. `if [ "$first" = true ]; then first=false; else echo ","; fi` - 
    - Imprime coma entre elementos del array JSON (menos en el primero)
13. `cat <<EOF ... EOF` - Imprime el objeto JSON con todos los campos
14. `echo "]"` - Imprime el cierre del array JSON

**Dependencias:**
- `bc` para cálculos matemáticos (necesario para conversión de unidades)