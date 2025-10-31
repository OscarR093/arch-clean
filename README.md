# Arch Clean

Arch Clean es una herramienta gráfica para la gestión segura de paquetes en sistemas Arch Linux y derivados. La aplicación proporciona una interfaz intuitiva para desinstalar paquetes, revisar dependencias y mantener tu sistema limpio y optimizado.

## Características principales

### Actual
- **Interfaz gráfica GTK**: Visualización de paquetes instalados con información detallada
- **Información de paquetes**: Nombre, versión, descripción, fecha de instalación, tamaño y razón de instalación
- **Sistema de iconos**: Visualización de iconos para paquetes cuando están disponibles
- **Carga de paquetes**: Lista paquetes instalados explícitamente (no como dependencias)
- **Gestión segura**: Mostrar información detallada para decisiones informadas de desinstalación

### Funcionalidades planeadas

#### Gestión de paquetes
- Desinstalación segura con advertencia sobre posibles dependencias
- Visualización de dependencias y paquetes que dependen del seleccionado
- Búsqueda y filtrado de paquetes

#### Gestión avanzada
- Identificación y limpieza de dependencias huérfanas
- Limpieza de cache de paquetes en un solo clic
- Gestión de paquetes AUR (a través de yay/paru)
- Gestión de paquetes Flatpak

#### Seguridad y verificación
- Previsualización de lo que sucederá al desinstalar un paquete
- Protección contra desinstalación accidental de paquetes críticos
- Historial de operaciones de paquetes

## Sistemas de paquetes soportados

- **Pacman**: Sistema de paquetes principal de Arch Linux
- **Yay/Paru**: Gestores de paquetes AUR
- **Flatpak**: Sistema de paquetes universales

## Estado actual del proyecto

- ✅ Interfaz gráfica funcional con GTK4
- ✅ Carga de paquetes instalados
- ✅ Visualización de información detallada del paquete
- ✅ Sistema de iconos modularizado
- ✅ Gestión de errores de formato JSON
- ⏳ Desinstalación de paquetes
- ⏳ Detección de dependencias huérfanas
- ⏳ Limpieza de cache

## Requisitos

- Arch Linux (o distribución derivada)
- Rust (cargo)
- GTK4 desarrollo bibliotecas
- Pacman (y opcionalmente Yay/Paru)
- JQ (para mejor manejo de JSON)

## Instalación

1. Clonar el repositorio
2. Asegurarse de tener los requisitos instalados
3. Ejecutar `cargo run` para compilar y ejecutar

## Contribución

Las contribuciones son bienvenidas. Puedes ayudar:

- Reportando problemas
- Proponiendo nuevas características
- Corrigiendo errores
- Mejorando la documentación
- Añadiendo soporte para más sistemas de paquetes

## Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## Contribuciones Open Source

Arch Clean es un proyecto completamente open source y cualquier contribución es bienvenida. El proyecto se mantiene bajo la filosofía de software libre, lo que significa que puedes:

- Usar el software para cualquier propósito
- Estudiar cómo funciona y modificarlo
- Distribuir copias
- Mejorar el software y hacer públicas esas mejoras