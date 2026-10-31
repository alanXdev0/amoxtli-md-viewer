# Amoxtli: Markdown Viewer

Visor de Markdown formateado para macOS 27. Gratuito y 100% open source (MIT). Nativo: solo frameworks de Apple, sin dependencias de terceros y sin WKWebView.

![Captura de pantalla](docs/screenshot.png) <!-- placeholder -->

## Funciones

- Abre archivos `.md` y `.markdown` desde Finder, Open With o ⌘O.
- Abre carpetas con File > Open Folder… (⇧⌘O): lista sus archivos Markdown, también los de subcarpetas, agrupados por carpeta. La ventana se restaura al volver a abrir la app.
- Índice del documento en un panel lateral que se oculta con el botón de la barra o con ⌃⌘I. Al elegir una entrada, hace scroll hasta su encabezado.
- Se ofrece como visor Markdown predeterminado al iniciar, con la opción de no volver a preguntar. También se puede establecer desde el menú de la app.
- Muestra encabezados, listas anidadas, citas, bloques de código, tablas, imágenes remotas y estilos de texto.
- Explica los errores en la ventana: archivo vacío, UTF-8 inválido, archivo ilegible, carpeta sin Markdown o carpeta que ya no se encuentra.
- Abre links web y de correo con el sistema, y los links `#ancla` hacen scroll al encabezado. Cualquier otro esquema se ignora y se avisa.
- Al pasar el mouse sobre un link muestra su URL completa, como la barra de estado de Safari.
- Menú contextual en links: abrir en la app predeterminada, "Abrir con" y copiar el enlace.
- Avisa antes de abrir un link a un sitio que no conoce. Ver [Enlaces conocidos](#enlaces-conocidos).

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

- **Hover:** `NSTrackingArea`, `mouseMoved` y `NSLayoutManager.characterIndex(for:in:fractionOfDistanceBetweenInsertionPoints:)` leyendo el atributo `.link`. No usa `characterIndexForInsertion(at:)` porque en una ventana visible devuelve el final del texto.
- **Menú:** override de `menu(for:)`.
- **Teclado:** ⇥ y ⇧⇥ recorren los links del bloque, y ↩ abre el seleccionado. Solo los bloques con links reciben foco con ⇥.

La contrapartida es que cada bloque es una vista de texto independiente: la selección y "Seleccionar todo" no cruzan de un bloque a otro.

## Enlaces conocidos

Un documento puede decir una cosa y enlazar a otra, así que Amoxtli no abre cualquier sitio sin avisar. Cada link web pasa por esta revisión, ya sea con un clic, con ↩ o desde el menú contextual:

- **Se abren directo:** `apple.com`, `github.com`, `mozilla.org`, `swift.org` y `wikipedia.org`, con sus subdominios, y los sitios en los que elegiste confiar. También los links `mailto:`, porque solo crean un borrador.
- **Muestran una alerta:** todos los demás sitios. La alerta enseña el dominio y la URL completa, y permite "Confiar siempre" en ese sitio.
- **Nunca se abren:** los demás esquemas, como `ftp:` o `file:`.

La comparación es por dominio completo: `notgithub.com` y `github.com.example.org` no cuentan como GitHub. Para borrar los sitios de confianza, usa "Olvidar sitios de confianza" en el menú de la app.

## Carpetas

El escaneo omite archivos y carpetas ocultos, el contenido de paquetes como las apps y los enlaces simbólicos. Una subcarpeta sin permiso de lectura se omite y no impide abrir el resto.

La lista refleja la carpeta en el momento de abrirla: para ver archivos nuevos hay que cerrar la ventana y abrirla otra vez. Los links relativos entre archivos, como `otra-nota.md`, no navegan: se ignoran y se avisa, igual que cualquier otro esquema.

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
