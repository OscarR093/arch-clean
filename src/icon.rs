// src/icon.rs
use std::path::Path;
use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct IconManager {
    icon_paths: Vec<String>,
    icon_cache: HashMap<String, Option<String>>,
}

impl IconManager {
    pub fn new() -> Self {
        let icon_paths = vec![
            // Directorios de iconos comunes
            "/usr/share/pixmaps/".to_string(),
            "/usr/share/icons/hicolor/48x48/apps/".to_string(),
            "/usr/share/icons/hicolor/64x64/apps/".to_string(),
            "/usr/share/icons/hicolor/128x128/apps/".to_string(),
            "/usr/share/icons/hicolor/256x256/apps/".to_string(),
            "/usr/share/icons/hicolor/scalable/apps/".to_string(),
            // Directorios de iconos para temas específicos
            "/usr/share/icons/breeze/apps/48/".to_string(),  // KDE
            "/usr/share/icons/gnome/48x48/apps/".to_string(),  // GNOME
        ];

        IconManager {
            icon_paths,
            icon_cache: HashMap::new(),
        }
    }

    pub fn find_icon_for_package(&mut self, package_name: &str) -> Option<String> {
        // Verificar cache primero
        if let Some(cached_result) = self.icon_cache.get(package_name) {
            return cached_result.clone();
        }

        // Buscar iconos en las rutas definidas
        let icon_extensions = ["png", "svg", "xpm"];
        
        for path in &self.icon_paths {
            for ext in &icon_extensions {
                let icon_path = format!("{}{}.{}", path, package_name, ext);
                if Path::new(&icon_path).exists() {
                    self.icon_cache.insert(package_name.to_string(), Some(icon_path.clone()));
                    return Some(icon_path);
                }
                
                // Buscar con nombres derivados (por ejemplo, si el paquete es my-app, buscar my_app, my, app, etc.)
                if let Some(derived_icon) = self.find_derived_icon(package_name, path, ext) {
                    self.icon_cache.insert(package_name.to_string(), Some(derived_icon.clone()));
                    return Some(derived_icon);
                }
            }
        }

        // No se encontró icono, cachear el resultado
        self.icon_cache.insert(package_name.to_string(), None);
        None
    }

    fn find_derived_icon(&self, package_name: &str, base_path: &str, ext: &str) -> Option<String> {
        let variants = self.get_name_variants(package_name);
        
        for variant in variants {
            let icon_path = format!("{}{}.{}", base_path, variant, ext);
            if Path::new(&icon_path).exists() {
                return Some(icon_path);
            }
        }
        
        None
    }

    fn get_name_variants(&self, package_name: &str) -> Vec<String> {
        let mut variants = vec![package_name.to_string()];
        
        // Agregar variantes comunes
        if package_name.contains('-') {
            // Para paquetes como 'vlc-media-player' o 'git-gui'
            variants.push(package_name.replace('-', "_"));
            variants.push(package_name.split('-').next().unwrap_or(package_name).to_string());
        }
        
        // Añadir variantes comunes
        if package_name.ends_with("-bin") || package_name.ends_with("-git") {
            variants.push(package_name.trim_end_matches("-bin").trim_end_matches("-git").to_string());
        }
        
        variants
    }

    pub fn get_default_icon() -> String {
        // Icono genérico
        "/usr/share/icons/hicolor/48x48/mimetypes/application-x-executable.png".to_string()
    }
}