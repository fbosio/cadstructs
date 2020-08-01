# cadstructs

AutoCAD add-ons to draw building structures.

Currently, prompt messages, command names and comments in the code are
available in Spanish only.

## Compatibility

The scripts work in AutoCAD 2006 (and I suppose they do in newer versions too).

## Installation
Installation depends on each one's way of organizing files.

* If all the AutoCAD projects are stored in the same folder, then
  1. copy the  `cadstructs` directory and the `install.bat` script to that
      folder;
  2. run `install.bat`;
  3. delete `install.bat`, if you want.
* If the projects are scattered all over the hard disk, then
  1. copy the  `cadstructs` directory to the `Support` folder of AutoCAD
    (usually `%APPDATA%\Autodesk\`...`\Support`);
  2. run `APPLOAD` on the AutoCAD command prompt
    (or go to `Tools > Load Application...`)
  3. press `Contents...`
  4. `Add...`
  5. look for `cadstructs\main.lsp`;
  6. double click `main.lsp` or press `Add`;
  7. `Close` the last two windows and that's it.

## Project structure
* `install.sh` adds the AutoLISP files to a local `acaddoc.lsp`;
* `cadstructs` contains the script files:
  - `activex.lsp` loads the supporting code that enables the ActiveX functions
    in AutoLISP. ActiveX is needed for working with dynamic blocks, and allows
    communicating different documents between each other;
  - `custom-commands.lsp` declares the commands;
  - `subroutines.lsp` declares several functions which are called by the
    custom commands;
  - `main.lsp` loads all the other AutoLISP scripts.

## Comandos
En español (I warned you).

* `NOMBRAR` recibe un tipo de elemento estructural y genera textos de la forma
  `prefijo+número`, con el `prefijo` generado a partir del referido elemento
  estructural. Por ejemplo, si el elemento estructural indicado es `Columna`,
  entonces el comando genera textos de la forma `C1`, `C2`, `C3`... etc.

  Este comando pregunta también por un número inicial, y una rotación, de no
  encontrar un estilo de texto adecuado.
* `LOSA` recibe un número inicial y genera losas, incrementando automáticamente
  la numeración.
* `COLAP` intercambia columnas con apeos, y apeos con columnas, aplica también a
  los nombres de los elementos, por ejemplo, `C123` se convierte en `A123`.
* `TITULAR` permite insertar el título de las plantas con el estilo de texto
  adecuado, creándolo cuando dicho estilo no está definido.

Estos comandos se ajustan a un flujo de trabajo muy específico y ponen cada
elemento estructural en una capa determinada. Ejemplo: las columnas y sus
nombres van en una capa `Columnas`, los apeos y sus nombres, en una capa
`Apeos`, etc. En forma similar, los nombres de los elementos tienen un estilo de
texto determinado, que es diferente al de los títulos.
