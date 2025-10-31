#!/bin/bash
# Script de prueba para generar datos de ejemplo

echo '[
  {
    "name": "test-package",
    "version": "1.0.0",
    "description": "A test package for demonstration",
    "install_date": "2023-01-01",
    "installed_size": 1024,
    "install_reason": "explicit"
  },
  {
    "name": "another-package",
    "version": "2.1.3",
    "description": "Another test package",
    "install_date": "2023-02-15",
    "installed_size": 2048,
    "install_reason": "dependency"
  }
]'