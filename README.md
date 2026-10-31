# Amoxtli: Markdown Viewer

Visor de Markdown formateado para macOS 27. Gratuito y 100% open source (MIT). Nativo: solo frameworks de Apple, sin dependencias de terceros y sin WKWebView.

![Captura de pantalla](docs/screenshot.png) <!-- placeholder -->

## Funciones

- Abre archivos `.md` y `.markdown` desde Finder, Open With o ⌘O.
- Muestra encabezados, listas anidadas, citas, bloques de código, tablas, imágenes remotas y estilos de texto.
- Explica los errores en la ventana: archivo vacío, UTF-8 inválido o archivo ilegible.

## Soporte de Markdown

El parser es `AttributedString(markdown:)` de Foundation. Los tests de `AmoxtliTests/MarkdownParserTests.swift` documentan este comportamiento:

| Sintaxis | Estado |
|---|---|
| Tablas GFM, con alineación | Funciona |
| Tachado (`~~x~~`) | Funciona |
| Autolinks (`https://…`) | Funciona |
| Task lists (`- [ ] x`) | No se interpreta: aparece como texto literal |
| Notas al pie (`[^1]`) | No se interpreta: aparece como texto literal |
| Salto de línea duro (dos espacios al final) | Funciona |
| HTML | No se interpreta: aparece como texto literal |
| Imágenes con ruta relativa | No se cargan: se muestra el texto alternativo |

## Compilar

Requiere Xcode 27 y macOS 27.

```bash
xcodebuild -scheme Amoxtli -destination 'platform=macOS' build
```

```bash
xcodebuild -scheme Amoxtli -destination 'platform=macOS' test
```

## Licencia

[MIT](LICENSE)
