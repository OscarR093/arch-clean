// src/package.rs
use serde::Deserialize;

#[derive(Deserialize, Debug, Clone)]
pub struct Package {
    pub name: String,
    pub version: String,
    pub description: String,
    pub install_date: String,
    pub installed_size: u64,
    pub install_reason: String,
}

