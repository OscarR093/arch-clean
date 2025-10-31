// src/ui.rs
use crate::package::Package;
use gtk::prelude::*;
use gtk::{Application, ApplicationWindow, Box, Button, Label, ListBox, ListBoxRow, Orientation, ScrolledWindow};
use std::process::Command;
use serde_json;

pub fn build_ui(app: &Application) {
    let window = ApplicationWindow::builder()
        .application(app)
        .title("Arch Clean")
        .default_width(1000)
        .default_height(700)
        .build();

    let main_box = Box::new(Orientation::Vertical, 12);
    main_box.set_margin_start(12);
    main_box.set_margin_end(12);
    main_box.set_margin_top(12);
    main_box.set_margin_bottom(12);

    // Título
    let title = Label::new(Some("Arch Clean"));
    title.set_markup("<span size='xx-large' weight='bold'>Arch Clean</span>");
    main_box.append(&title);

    // Botón
    let refresh_button = Button::with_label("Cargar paquetes explícitos");
    let list_box = ListBox::new();
    let scrolled = ScrolledWindow::new();
    scrolled.set_child(Some(&list_box));
    scrolled.set_vexpand(true);

    // Clonamos para el closure
    let list_box_clone = list_box.clone();
    refresh_button.connect_clicked(move |_| {
        load_packages(&list_box_clone);
    });

    main_box.append(&refresh_button);
    main_box.append(&scrolled);
    window.set_child(Some(&main_box));
    window.present();

    // Carga inicial
    load_packages(&list_box);
}

fn load_packages(list_box: &ListBox) {
    list_box.remove_all();

    // Mostrar "Cargando..."
    let loading = ListBoxRow::new();
    let label = Label::new(Some("Cargando paquetes..."));
    loading.set_child(Some(&label));
    list_box.append(&loading);

    // Ejecutar script
    let script_path = "/home/oscarr093/proyectos/arch-clean/scripts/pacman/getAllPackages.sh"; // Ruta absoluta
    let output = Command::new("pkexec")
        .arg(script_path)
        .output();

    // Limpiar lista
    list_box.remove_all();

    match output {
        Ok(output) if output.status.success() => {
            let json_str = String::from_utf8_lossy(&output.stdout);
            
            // Para depuración, vamos a imprimir el final del JSON si hay un error
            match serde_json::from_str::<Vec<Package>>(&json_str) {
                Ok(packages) => {
                    if packages.is_empty() {
                        let row = ListBoxRow::new();
                        let label = Label::new(Some("No se encontraron paquetes explícitos."));
                        row.set_child(Some(&label));
                        list_box.append(&row);
                    } else {
                        for pkg in packages {
                            let row = create_package_row(&pkg);
                            list_box.append(&row);
                        }
                    }
                }
                Err(e) => {
                    // Si falla el parseo, mostrar el error específico
                    println!("Error de parseo JSON: {}", e);
                    
                    // Mostrar el error específico del JSON
                    let json_str = json_str.to_string();
                    let error_line = e.line();
                    let error_column = e.column();
                    
                    println!("Error en línea: {}, columna: {}", error_line, error_column);
                    
                    // Mostrar contexto alrededor del error
                    let lines: Vec<&str> = json_str.lines().collect();
                    let start = if error_line > 3 { error_line - 3 } else { 0 };
                    let end = std::cmp::min(lines.len(), error_line + 2);
                    
                    println!("Contexto del error:");
                    for i in start..end {
                        let marker = if i == error_line - 1 { " >>> " } else { "     " };
                        println!("{}{}: {}", marker, i + 1, lines[i]);
                    }
                    
                    show_error(list_box, &format!("Error JSON: {} (línea {}, columna {})", e, error_line, error_column));
                }
            }
        }
        Ok(output) => {
            let err = String::from_utf8_lossy(&output.stderr);
            show_error(list_box, &format!("Error del script: {}", err));
        }
        Err(e) => {
            show_error(list_box, "No se pudo ejecutar el script. ¿Está en la ruta?");
            println!("Error: {}", e);
        }
    }
}

fn create_package_row(pkg: &Package) -> ListBoxRow {
    let row = ListBoxRow::new();
    let vbox = Box::new(Orientation::Vertical, 4);
    vbox.set_margin_start(8);
    vbox.set_margin_end(8);
    vbox.set_margin_top(8);
    vbox.set_margin_bottom(8);

    let name = format!("<b>{}</b> <span foreground='#555'>{}</span>", pkg.name, pkg.version);
    let desc = pkg.description.chars().take(80).collect::<String>() + "...";
    let size_mb = pkg.installed_size as f64 / 1024.0 / 1024.0;
    let info = format!("{} | {:.1} MiB | {}", pkg.install_reason, size_mb, pkg.install_date);

    let name_label = Label::new(None);
    name_label.set_markup(&name);
    name_label.set_xalign(0.0);

    let desc_label = Label::new(Some(&desc));
    desc_label.set_xalign(0.0);
    desc_label.add_css_class("dim-label");

    let info_label = Label::new(Some(&info));
    info_label.set_xalign(0.0);
    info_label.add_css_class("dim-label");

    vbox.append(&name_label);
    vbox.append(&desc_label);
    vbox.append(&info_label);

    row.set_child(Some(&vbox));
    row
}

fn show_error(list_box: &ListBox, msg: &str) {
    let row = ListBoxRow::new();
    let label = Label::new(Some(msg));
    label.add_css_class("error");
    row.set_child(Some(&label));
    list_box.append(&row);
}


