# ui_inventory.ps1 - inventario de UI de AirDrop (frontend)
#
# Enumera la UI de las features (pantallas y widgets) con su ruta y el
# tamanio de CADA widget/clase, y lo escribe en docs/ui_inventory.md.
#
# Para que sirve: cuando haya que dissenar pestaas, cajitas o widgets,
# este archivo dice exactamente que archivos componen la UI y cuanto pesa
# cada widget. Correrlo despues de cada fase mantiene el inventario vivo.
#
# La regla de las 60 lineas se mide POR CLASE (un archivo puede tener
# varias), que es como la aplica frontend/AGENTS.md.
#
# Uso (desde la raiz del monorepo o desde frontend/):
#   powershell -ExecutionPolicy Bypass -File tools\ui_inventory.ps1

$ErrorActionPreference = 'Stop'

$frontend = if (Test-Path 'lib') { '.' } else { 'frontend' }
$features = Join-Path $frontend 'lib\features'
$outFile = Join-Path $frontend 'docs\ui_inventory.md'

if (-not (Test-Path $features)) {
  Write-Error "No encuentro $features. Corre el script desde la raiz o desde frontend/."
}

function Get-LineCount($file) {
  (Get-Content $file.FullName).Count
}

# Mide cada clase de nivel superior del archivo y devuelve los pares
# nombre/lineas. La regla de 60 lineas aplica a la clase, no al archivo.
function Get-ClassSizes($file) {
  $lines = Get-Content $file.FullName
  $starts = @()
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^(?:abstract\s+|sealed\s+|final\s+)?class\s+(\w+)') {
      $starts += , @($Matches[1], $i)
    }
  }
  $result = @()
  for ($k = 0; $k -lt $starts.Count; $k++) {
    $name = $starts[$k][0]
    $start = $starts[$k][1]
    $end = if ($k + 1 -lt $starts.Count) { $starts[$k + 1][1] - 1 } else { $lines.Count - 1 }
    # Si entre clase y clase hay funciones libres, corta ahi.
    for ($j = $start + 1; $j -lt $end; $j++) {
      if ($lines[$j] -match '^(Future<|Future |void |String\? |Widget |bool )') { $end = $j - 1; break }
    }
    $result += , @($name, ($end - $start + 1))
  }
  # Coma unaria: obliga a devolver el arreglo de pares como UN objeto,
  # para que un archivo con una sola clase no se desarme en el foreach.
  return , $result
}

$all = Get-ChildItem -Recurse -File $features -Filter '*.dart'

# Pantallas: archivos *_screen.dart. Widgets: cualquier dart con un
# ancestro llamado /widgets/ (incluye subcarpetas como widgets/register/).
# Otros: el resto de presentation/ (homes, controllers) - se listan pero
# la regla de 60 lineas no aplica a controllers.
$screens = $all | Where-Object { $_.Name -like '*_screen.dart' }

$widgets = $all | Where-Object {
  $dir = $_.Directory
  $isWidget = $false
  while ($null -ne $dir) {
    if ($dir.Name -eq 'widgets') { $isWidget = $true; break }
    $dir = $dir.Parent
  }
  $isWidget
}

$other = $all | Where-Object {
  $_.Name -notlike '*_screen.dart' -and
  $_.FullName -notlike '*\widgets\*' -and
  $_.FullName -like '*\presentation\*'
}

function Get-FeatureName($file) {
  $rel = $file.FullName.Substring((Resolve-Path $features).Path.Length + 1)
  return $rel.Split('\')[0]
}

function Group-ByFeature($files) {
  $map = @{}
  foreach ($f in $files) {
    $feature = Get-FeatureName $f
    if (-not $map.ContainsKey($feature)) { $map[$feature] = @() }
    $map[$feature] += $f
  }
  return $map
}

$screensMap = Group-ByFeature $screens
$widgetsMap = Group-ByFeature $widgets
$otherMap = Group-ByFeature $other
$allFeatures = ($screensMap.Keys + $widgetsMap.Keys + $otherMap.Keys) | Sort-Object -Unique

$md = New-Object System.Collections.Generic.List[string]
$md.Add('# Inventario de UI (generado)')
$md.Add('')
$md.Add('> Archivo **generado** por `frontend/tools/ui_inventory.ps1`. No editar')
$md.Add('> a mano: correr el script de nuevo despues de cada fase que agregue o')
$md.Add('> borre UI. Para que sirve: este listado es el mapa de lo que habra que')
$md.Add('> tocar cuando cambie el diseno (pestanas, cajitas, widgets).')
$md.Add('')
$md.Add("Generado: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
$md.Add('')

$longWidgets = New-Object System.Collections.Generic.List[string]
$totalScreens = 0
$totalWidgets = 0
$totalWidgetClasses = 0

foreach ($feature in $allFeatures) {
  $md.Add("## $feature")
  $md.Add('')

  if ($screensMap.ContainsKey($feature)) {
    $md.Add('### Pantallas')
    $md.Add('')
    $md.Add('| Archivo | Lineas |')
    $md.Add('| --- | --- |')
    foreach ($f in ($screensMap[$feature] | Sort-Object Name)) {
      $totalScreens++
      $md.Add("| ``$($f.Name)`` | $(Get-LineCount $f) |")
    }
    $md.Add('')
  }

  if ($widgetsMap.ContainsKey($feature)) {
    $md.Add('### Widgets')
    $md.Add('')
    $md.Add('| Archivo | Widget/clase | Lineas | Estado |')
    $md.Add('| --- | --- | --- | --- |')
    foreach ($f in ($widgetsMap[$feature] | Sort-Object Name)) {
      foreach ($cls in (Get-ClassSizes $f)) {
        $name = $cls[0]
        $n = $cls[1]
        $totalWidgetClasses++
        $state = 'ok'
        if ($n -gt 60) {
          $state = '**>60**'
          $longWidgets.Add("$feature/$($f.Name) :: $name = $n")
        }
        $md.Add("| ``$($f.Name)`` | $name | $n | $state |")
      }
      if ((Get-ClassSizes $f).Count -eq 0) {
        $n = Get-LineCount $f
        $md.Add("| ``$($f.Name)`` | (sin clases) | $n | ok |")
      }
    }
    $md.Add('')
    $totalWidgets += ($widgetsMap[$feature]).Count
  }

  if ($otherMap.ContainsKey($feature)) {
    $md.Add('### Otros (presentation/ sin /widgets)')
    $md.Add('')
    $md.Add('| Archivo | Lineas |')
    $md.Add('| --- | --- |')
    foreach ($f in ($otherMap[$feature] | Sort-Object Name)) {
      $md.Add("| ``$($f.Name)`` | $(Get-LineCount $f) |")
    }
    $md.Add('')
  }
}

$md.Add('## Resumen')
$md.Add('')
$md.Add("- Pantallas ($($screens.Count) archivos): $totalScreens")
$md.Add("- Archivos de widgets: $totalWidgets - clases de widget medidas: $totalWidgetClasses")
$md.Add("- Widgets sobre 60 lineas: $($longWidgets.Count)")
if ($longWidgets.Count -gt 0) {
  $md.Add('')
  $md.Add('Detalle de los que exceden 60 lineas (candidatos a partir):')
  $md.Add('')
  foreach ($w in $longWidgets) { $md.Add("- $w") }
}
$md.Add('')

New-Item -ItemType Directory -Force -Path (Split-Path $outFile) | Out-Null
# UTF-8 con BOM para que los acentos se lean bien en Windows y en GitHub.
[System.IO.File]::WriteAllLines($outFile, $md, (New-Object System.Text.UTF8Encoding($true)))
Write-Output "Inventario escrito en $outFile"
Write-Output "Pantallas: $totalScreens | Archivos widget: $totalWidgets | Clases >60: $($longWidgets.Count)"
