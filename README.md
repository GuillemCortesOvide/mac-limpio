## ▶️ Cómo ejecutar el script / How to run the script

### 🇪🇸 Español (macOS / Linux)

1) Descarga el archivo y entra en la carpeta donde está.

2) Dale permisos de ejecución (solo la primera vez):

```bash
chmod +x mac-limpio.sh
```

3) Ejecútalo:

```bash
./mac-limpio.sh review
```

**Alternativa (sin `chmod`)**:

```bash
bash mac-limpio.sh review
```

🔐 **Nota macOS (Gatekeeper / Quarantine)**  
Si macOS bloquea el archivo por haber sido descargado de Internet, puedes quitar el atributo de cuarentena:

```bash
xattr -d com.apple.quarantine mac-limpio.sh
```


### 🇬🇧 English (macOS / Linux)

1) Download the file and `cd` into the folder where it is.

2) Make it executable (only needed once):

```bash
chmod +x mac-limpio.sh
```

3) Run it:

```bash
./mac-limpio.sh review
```

**Alternative (without `chmod`)**:

```bash
bash mac-limpio.sh review
```

🔐 **macOS note (Gatekeeper / Quarantine)**  
If macOS blocks the file because it was downloaded from the Internet, remove the quarantine attribute:

```bash
xattr -d com.apple.quarantine safe-mac-cleanup.sh
```


📄 Licencia / License

 Español — GNU GPL v2.0

Este proyecto está licenciado bajo la GNU General Public License versión 2 (GPL-2.0).

Copyright (C) 2026
Guillem Cortés Ovide

Este programa es software libre; puedes redistribuirlo y/o modificarlo
bajo los términos de la Licencia Pública General de GNU tal como fue publicada
por la Free Software Foundation; ya sea la versión 2 de la Licencia, o
(a tu elección) cualquier versión posterior.

Este programa se distribuye con la esperanza de que sea útil,
pero SIN NINGUNA GARANTÍA; sin siquiera la garantía implícita de
COMERCIABILIDAD o IDONEIDAD PARA UN PROPÓSITO PARTICULAR.
Consulta la Licencia Pública General de GNU para más detalles.

Deberías haber recibido una copia de la Licencia Pública General de GNU
junto con este programa; si no es así, puedes consultarla en:

👉 https://www.gnu.org/licenses/old-licenses/gpl-2.0.html

 English — GNU GPL v2.0

This project is licensed under the GNU General Public License version 2 (GPL-2.0).

Copyright (C) 2026
Guillem Cortés Ovide

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, see:

👉 https://www.gnu.org/licenses/old-licenses/gpl-2.0.html

