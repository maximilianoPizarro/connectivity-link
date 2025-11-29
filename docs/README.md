# Connectivity Link Documentation Site

Este sitio web está construido con Jekyll y utiliza el tema dark de Red Hat.

## Requisitos

- Ruby 2.7 o superior
- Bundler gem

## Instalación

1. Instala las dependencias:

```bash
bundle install
```

## Ejecutar el sitio localmente

Para ejecutar el servidor de desarrollo de Jekyll:

```bash
bundle exec jekyll serve
```

El sitio estará disponible en `http://localhost:4000`

## Construir para producción

Para generar el sitio estático:

```bash
bundle exec jekyll build
```

Los archivos generados estarán en el directorio `_site/`.

## Estructura

- `_config.yml` - Configuración de Jekyll
- `_layouts/` - Plantillas HTML
- `assets/css/` - Estilos CSS
- `index.md` - Página principal
- Todos los recursos (imágenes, favicon) están en la raíz de `docs/` y son servidos públicamente

