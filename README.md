# Amoxtli: Markdown Viewer

Visor de Markdown formateado para macOS 27. Gratuito y 100% open source (MIT). Nativo: solo frameworks de Apple, sin dependencias de terceros y sin WKWebView.

![Captura de pantalla](docs/screenshot.png) <!-- placeholder -->

## Funciones

- Abre archivos `.md` y `.markdown` desde Finder, Open With o ⌘O.
- Muestra encabezados, listas anidadas, citas, bloques de código, tablas, imágenes remotas y estilos de texto.
- Explica los errores en la ventana: archivo vacío, UTF-8 inválido o archivo ilegible.
- Abre links web y de correo con el sistema, y los links `#ancla` hacen scroll al encabezado. Cualquier otro esquema se ignora y se avisa.
- Al pasar el mouse sobre un link muestra su URL completa, como la barra de estado de Safari.
- Menú contextual en links: abrir en la app predeterminada, "Abrir con" y copiar el enlace.

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

## Links: por qué `NSTextView` y no `Text`

SwiftUI `Text` no sirve para el hover ni para el menú por link. En el SDK de macOS 27:

- `onHover`, `onContinuousHover` y `contextMenu` actúan sobre la vista completa, no sobre un link.
- `OpenURLAction` solo se entera del clic.
- `Text.Layout` solo se puede leer dentro de un `TextRenderer`, al dibujar.

Por eso los bloques de texto usan un `NSViewRepresentable` sobre una subclase de `NSTextView` (`MarkdownTextView`), de solo lectura y seleccionable:

- **Hover:** `NSTrackingArea`, `mouseMoved` y `characterIndexForInsertion(at:)` leyendo el atributo `.link`.
- **Menú:** override de `menu(for:)`.
- **Teclado:** ⇥ y ⇧⇥ recorren los links del bloque, y ↩ abre el seleccionado.

La contrapartida es que cada bloque es una vista de texto independiente: la selección y "Seleccionar todo" no cruzan de un bloque a otro.

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
