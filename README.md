# LimpiarLogs.ps1 — Limpiador interactivo de logs

## ¿Qué hace?

Escanea una carpeta de logs en Windows, muestra cuánto ocupa cada tipo de fichero y te pregunta qué hacer: borrar los más antiguos, comprimir los recientes en un ZIP con fecha, o las dos cosas. Tiene modo `-DryRun` para simular sin tocar nada.

## ¿Por qué lo elegimos?

En las FCT los servidores acumulaban gigas de logs que nadie limpiaba porque era un rollo hacerlo a mano. Este script lo automatiza y además te deja elegir, no borra a lo loco.

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

Que PowerShell tiene `Compress-Archive` integrado sin instalar nada, y a usar `try/catch` para que un error en un fichero no rompa todo el script.

## Posibles mejoras

- Programarlo con el Programador de tareas para que corra solo cada semana
- Fichero de configuración `.json` para no pasar parámetros cada vez
