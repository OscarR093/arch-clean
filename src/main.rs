// src/main.rs
mod package;
mod icon;
mod ui;

use gtk::prelude::*;
use gtk::Application;
use ui::build_ui;

const APP_ID: &str = "org.tuusuario.ArchClean";

fn main() -> gtk::glib::ExitCode {
    let app = Application::builder()
        .application_id(APP_ID)
        .build();

    app.connect_activate(build_ui);
    app.run()
}
