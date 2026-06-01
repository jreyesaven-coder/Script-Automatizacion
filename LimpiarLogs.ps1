# =============================================================================
# LimpiarLogs.ps1 - Limpiador inteligente de logs para Windows 11
# Autor: Script Battle - ADSO 2ASI
# Descripcion: Escanea carpetas de logs, muestra uso por tipo, permite elegir
#              interactivamente que limpiar, comprime los que conserva y
#              tiene modo --dry-run para simular sin borrar nada.
# Uso: .\LimpiarLogs.ps1 [-RutaBase "C:\Ruta\Logs"] [-DiasMaximos 30] [-DryRun]
# =============================================================================

param(
    [string]$RutaBase    = "$env:SystemRoot\Logs",  # Ruta base donde buscar logs
    [int]   $DiasMaximos = 30,                       # Antiguedad maxima en dias
    [switch]$DryRun                                  # Si se activa, simula sin borrar
)

# --- Colores de consola para una salida mas clara --------------------------
function Escribir-Color {
    param([string]$Texto, [string]$Color = "White")
    Write-Host $Texto -ForegroundColor $Color
}

function Escribir-Titulo {
    param([string]$Texto)
    Write-Host ""
    Write-Host ("=" * 62) -ForegroundColor Cyan
    Write-Host "  $Texto" -ForegroundColor Cyan
    Write-Host ("=" * 62) -ForegroundColor Cyan
    Write-Host ""
}

function Escribir-Separador { Write-Host ("-" * 62) -ForegroundColor DarkGray }

# --- Convierte bytes a una unidad legible (KB, MB, GB) --------------------
function Formatear-Tamano {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    return "$Bytes B"
}

# --- Comprime una lista de ficheros en un .zip con fecha en el nombre -----
function Comprimir-Logs {
    param([System.IO.FileInfo[]]$Ficheros, [string]$CarpetaDestino)

    # Crear carpeta de comprimidos si no existe
    $carpetaZip = Join-Path $CarpetaDestino "logs_comprimidos"
    if (-not (Test-Path $carpetaZip)) {
        New-Item -ItemType Directory -Path $carpetaZip | Out-Null
    }

    $fecha      = Get-Date -Format "yyyyMMdd_HHmmss"
    $nombreZip  = Join-Path $carpetaZip "logs_backup_$fecha.zip"

    Escribir-Color "  Comprimiendo $($Ficheros.Count) fichero(s) en:" "DarkYellow"
    Escribir-Color "  $nombreZip" "Yellow"

    if (-not $DryRun) {
        try {
            Compress-Archive -Path $Ficheros.FullName -DestinationPath $nombreZip -Force
            Escribir-Color "  Compresion completada correctamente." "Green"
        } catch {
            Escribir-Color "  ERROR al comprimir: $_" "Red"
        }
    } else {
        Escribir-Color "  [DRY-RUN] Se habria creado el ZIP (no se ha hecho nada)." "Magenta"
    }
}

# ===========================================================================
#  INICIO DEL SCRIPT
# ===========================================================================

Escribir-Titulo "LIMPIADOR INTELIGENTE DE LOGS - Windows 11"

# Mostrar modo actual
if ($DryRun) {
    Escribir-Color "  MODO DRY-RUN activado: no se borrara ni comprimira nada real." "Magenta"
    Write-Host ""
}

# Comprobar que la ruta base existe
if (-not (Test-Path $RutaBase)) {
    Escribir-Color "ERROR: La ruta '$RutaBase' no existe o no tienes acceso." "Red"
    Escribir-Color "Prueba con: .\LimpiarLogs.ps1 -RutaBase 'C:\MiCarpetaDeLogs'" "Yellow"
    exit 1
}

Escribir-Color "  Ruta analizada : $RutaBase" "White"
Escribir-Color "  Antiguedad max : $DiasMaximos dias" "White"
Escribir-Color "  Fecha limite   : $((Get-Date).AddDays(-$DiasMaximos).ToString('dd/MM/yyyy'))" "White"
Write-Host ""

# ===========================================================================
#  FASE 1: Escaneo de ficheros de log
# ===========================================================================

Escribir-Color "Escaneando ficheros..." "Cyan"

# Buscar todos los .log y .txt recursivamente
$todosFicheros = Get-ChildItem -Path $RutaBase -Recurse -File `
                  -Include "*.log","*.txt","*.evtx" `
                  -ErrorAction SilentlyContinue

if ($todosFicheros.Count -eq 0) {
    Escribir-Color "No se encontraron ficheros de log en la ruta indicada." "Yellow"
    exit 0
}

# Separar antiguos (candidatos a borrar) y recientes (candidatos a comprimir)
$fechaLimite  = (Get-Date).AddDays(-$DiasMaximos)
$logsAntiguos = $todosFicheros | Where-Object { $_.LastWriteTime -lt $fechaLimite }
$logsRecientes = $todosFicheros | Where-Object { $_.LastWriteTime -ge $fechaLimite }

# ===========================================================================
#  FASE 2: Resumen por extension
# ===========================================================================

Escribir-Titulo "RESUMEN DE FICHEROS ENCONTRADOS"

# Agrupar por extension y calcular tamano total de cada grupo
$grupos = $todosFicheros | Group-Object Extension | Sort-Object Name
foreach ($g in $grupos) {
    $tamTotal = ($g.Group | Measure-Object -Property Length -Sum).Sum
    Write-Host ("  {0,-8}  {1,5} fichero(s)   {2,10}" -f `
        $g.Name, $g.Count, (Formatear-Tamano $tamTotal)) -ForegroundColor White
}

Escribir-Separador
$tamanoTotal  = ($todosFicheros | Measure-Object -Property Length -Sum).Sum
$tamanoViejo  = ($logsAntiguos  | Measure-Object -Property Length -Sum).Sum
Write-Host ("  Total encontrado  : {0,6} fichero(s)  {1}" -f `
    $todosFicheros.Count, (Formatear-Tamano $tamanoTotal)) -ForegroundColor White
Write-Host ("  Antiguos (>$DiasMaximos d) : {0,6} fichero(s)  {1}" -f `
    $logsAntiguos.Count, (Formatear-Tamano $tamanoViejo)) -ForegroundColor Yellow
Write-Host ""

# ===========================================================================
#  FASE 3: Menu interactivo
# ===========================================================================

Escribir-Titulo "QUE QUIERES HACER?"

Write-Host "  [1]  Borrar logs antiguos (mas de $DiasMaximos dias)" -ForegroundColor Yellow
Write-Host "  [2]  Comprimir logs recientes (menos de $DiasMaximos dias)" -ForegroundColor Yellow
Write-Host "  [3]  Borrar antiguos Y comprimir recientes" -ForegroundColor Yellow
Write-Host "  [4]  Solo ver resumen detallado (no tocar nada)" -ForegroundColor Yellow
Write-Host "  [0]  Salir sin hacer nada" -ForegroundColor DarkGray
Write-Host ""

$opcion = Read-Host "  Elige una opcion"

# ===========================================================================
#  FASE 4: Ejecutar la opcion elegida
# ===========================================================================

switch ($opcion) {

    "1" {
        # --- Borrar logs antiguos -------------------------------------------
        Escribir-Titulo "BORRANDO LOGS ANTIGUOS"

        if ($logsAntiguos.Count -eq 0) {
            Escribir-Color "  No hay ficheros con mas de $DiasMaximos dias. Nada que borrar." "Green"
            break
        }

        $borrados  = 0
        $errores   = 0
        $espacioLiberado = 0L

        foreach ($f in $logsAntiguos) {
            $antiguedad = [math]::Round(((Get-Date) - $f.LastWriteTime).TotalDays)
            Write-Host ("  {0,-45} {1,8}  ({2}d)" -f `
                $f.Name, (Formatear-Tamano $f.Length), $antiguedad) -ForegroundColor Gray

            if (-not $DryRun) {
                try {
                    $espacioLiberado += $f.Length
                    Remove-Item $f.FullName -Force
                    $borrados++
                } catch {
                    Escribir-Color "    ERROR: $_" "Red"
                    $errores++
                }
            } else {
                # En dry-run contamos igual para mostrar el resumen
                $espacioLiberado += $f.Length
                $borrados++
            }
        }

        Escribir-Separador
        $prefijo = if ($DryRun) { "[DRY-RUN] Se habrian borrado" } else { "Borrados" }
        Escribir-Color "  $prefijo : $borrados fichero(s)  ($(Formatear-Tamano $espacioLiberado) liberados)" "Green"
        if ($errores -gt 0) { Escribir-Color "  Errores  : $errores" "Red" }
    }

    "2" {
        # --- Comprimir logs recientes ----------------------------------------
        Escribir-Titulo "COMPRIMIENDO LOGS RECIENTES"

        if ($logsRecientes.Count -eq 0) {
            Escribir-Color "  No hay ficheros recientes para comprimir." "Green"
            break
        }

        Comprimir-Logs -Ficheros $logsRecientes -CarpetaDestino $RutaBase
    }

    "3" {
        # --- Borrar antiguos Y comprimir recientes ---------------------------
        Escribir-Titulo "OPERACION COMPLETA"

        # Primero borrar
        if ($logsAntiguos.Count -gt 0) {
            Escribir-Color "  Paso 1/2: Borrando $($logsAntiguos.Count) logs antiguos..." "Yellow"
            $espacioLiberado = 0L
            foreach ($f in $logsAntiguos) {
                if (-not $DryRun) {
                    try { $espacioLiberado += $f.Length; Remove-Item $f.FullName -Force }
                    catch { Escribir-Color "    ERROR borrando $($f.Name): $_" "Red" }
                } else {
                    $espacioLiberado += $f.Length
                }
            }
            $prefijo = if ($DryRun) { "[DRY-RUN] Habrian sido borrados" } else { "Borrados" }
            Escribir-Color "  $prefijo $($logsAntiguos.Count) fichero(s) ($(Formatear-Tamano $espacioLiberado))" "Green"
        } else {
            Escribir-Color "  Paso 1/2: No hay logs antiguos que borrar." "DarkGray"
        }

        # Luego comprimir recientes
        Write-Host ""
        if ($logsRecientes.Count -gt 0) {
            Escribir-Color "  Paso 2/2: Comprimiendo $($logsRecientes.Count) logs recientes..." "Yellow"
            Comprimir-Logs -Ficheros $logsRecientes -CarpetaDestino $RutaBase
        } else {
            Escribir-Color "  Paso 2/2: No hay logs recientes que comprimir." "DarkGray"
        }
    }

    "4" {
        # --- Resumen detallado -----------------------------------------------
        Escribir-Titulo "DETALLE DE TODOS LOS FICHEROS"

        foreach ($f in ($todosFicheros | Sort-Object LastWriteTime)) {
            $dias   = [math]::Round(((Get-Date) - $f.LastWriteTime).TotalDays)
            $color  = if ($dias -gt $DiasMaximos) { "Yellow" } else { "Gray" }
            Write-Host ("  {0,-40} {1,9}  {2,4}d  {3}" -f `
                $f.Name, (Formatear-Tamano $f.Length), $dias, `
                $f.LastWriteTime.ToString("dd/MM/yyyy")) -ForegroundColor $color
        }
    }

    "0" {
        Escribir-Color "  Saliendo sin modificar nada. Hasta luego." "DarkGray"
    }

    default {
        Escribir-Color "  Opcion no valida. Ejecuta el script de nuevo." "Red"
    }
}

# ===========================================================================
#  RESUMEN FINAL
# ===========================================================================

Write-Host ""
Escribir-Separador
Escribir-Color "  Script finalizado. $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" "Cyan"
if ($DryRun) { Escribir-Color "  Recuerda: modo DRY-RUN, no se ha modificado nada." "Magenta" }
Escribir-Separador
Write-Host ""
