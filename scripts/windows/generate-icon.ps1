# Package the shared logo as a multi-resolution Windows icon.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Resolve-Path (Join-Path $PSScriptRoot '../..')
$source = [Drawing.Image]::FromFile((Join-Path $root 'assets/images/launcher-logo.png'))
$sizes = @(16,24,32,48,64,128,256)
$images = foreach ($size in $sizes) {
  $bitmap = [Drawing.Bitmap]::new($size,$size)
  $graphics = [Drawing.Graphics]::FromImage($bitmap)
  $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $ratio = [Math]::Min($size / $source.Width, $size / $source.Height)
  $w = [int]($source.Width * $ratio)
  $h = [int]($source.Height * $ratio)
  $graphics.DrawImage($source,[int](($size-$w)/2),[int](($size-$h)/2),$w,$h)
  $memory = [IO.MemoryStream]::new()
  $bitmap.Save($memory,[Drawing.Imaging.ImageFormat]::Png)
  ,$memory.ToArray()
  $memory.Dispose()
  $graphics.Dispose()
  $bitmap.Dispose()
}
$source.Dispose()
$writer = [IO.BinaryWriter]::new([IO.File]::Create((Join-Path $root 'windows/runner/resources/app_icon.ico')))
try {
  $writer.Write([uint16]0)
  $writer.Write([uint16]1)
  $writer.Write([uint16]$sizes.Count)
  $offset = 6 + 16 * $sizes.Count
  for ($i=0; $i -lt $sizes.Count; $i++) {
    $dimension = [byte]($sizes[$i] % 256)
    $writer.Write($dimension)
    $writer.Write($dimension)
    $writer.Write([uint16]0)
    $writer.Write([uint16]1)
    $writer.Write([uint16]32)
    $writer.Write([uint32]$images[$i].Length)
    $writer.Write([uint32]$offset)
    $offset += $images[$i].Length
  }
  foreach ($image in $images) { $writer.Write([byte[]]$image) }
} finally { $writer.Dispose() }
