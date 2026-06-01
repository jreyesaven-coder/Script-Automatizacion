# LimpiarLogs.ps1 — Limpiador interactivo de logs

## ¿Qué hace?

Escanea una carpeta de logs en Windows, muestra cuánto ocupa cada tipo de fichero y te pregunta qué quieres hacer con ellos. Puedes borrar los más antiguos, comprimir los recientes en un ZIP con fecha, o las dos cosas a la vez. Tiene un modo `--dry-run` para ver exactamente qué haría sin tocar nada todavía.

## ¿Por qué lo elegimos?

En las FCT vimos que los servidores acumulaban gigas de logs que nadie limpiaba a mano porque era un rollo. Cada vez que el disco se llenaba había que entrar, mirar a ojo qué podías borrar y rezar para no cargarte algo importante. Este script automatiza ese proceso y además te deja elegir, no borra a lo loco.

## Cómo se usa

```powershell
# Básico (escanea C:\Windows\Logs, umbral de 30 días)
powershell -ExecutionPolicy Bypass -File ".\LimpiarLogs.ps1"

# Con ruta y antigüedad personalizadas
powershell -ExecutionPolicy Bypass -File ".\LimpiarLogs.ps1" -RutaBase "C:\Logs\App" -DiasMaximos 15

# Modo simulación: muestra qué haría sin borrar ni comprimir nada
powershell -ExecutionPolicy Bypass -File ".\LimpiarLogs.ps1" -DryRun
```

Al ejecutarlo aparece un menú interactivo con 4 opciones. Recomendamos empezar siempre con `-DryRun` para revisar el resumen antes de hacer nada.

## Qué aprendimos

No sabíamos que PowerShell tenía `Compress-Archive` integrado sin necesitar instalar nada externo. También aprendimos a usar `try/catch` para que si un fichero está en uso o no tienes permisos el script no se rompa entero, simplemente avisa del error y sigue con los demás.

## Posibles mejoras

- Enviar el resumen por correo automáticamente al terminar
- Añadir un fichero de configuración `.json` para no tener que pasar los parámetros cada vez
- Programarlo con el Programador de tareas de Windows para que se ejecute solo cada semana
- Soporte para más extensiones configurables, no solo `.log`, `.txt` y `.evtx`
