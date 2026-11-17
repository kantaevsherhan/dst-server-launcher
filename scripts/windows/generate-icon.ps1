# Original geometric campfire mark. No game artwork is used.
Add-Type -AssemblyName System.Drawing
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$bmp = [Drawing.Bitmap]::new(256,256)
$g = [Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([Drawing.ColorTranslator]::FromHtml('#111716'))
$green = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#83C76D'))
$dark = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#111716'))
$g.FillEllipse($green,20,20,216,216)
$flame = [Drawing.Drawing2D.GraphicsPath]::new()
$flame.AddBezier(128,51,89,91,82,105,92,133)
$flame.AddBezier(92,133,104,166,154,166,165,134)
$flame.AddBezier(165,134,179,102,145,74,128,51)
$g.FillPath($dark,$flame)
$g.FillEllipse($green,112,111,32,34)
$pen = [Drawing.Pen]::new([Drawing.ColorTranslator]::FromHtml('#111716'),12)
$pen.StartCap = [Drawing.Drawing2D.LineCap]::Round
$pen.EndCap = [Drawing.Drawing2D.LineCap]::Round
$g.DrawLine($pen,77,168,179,191)
$g.DrawLine($pen,77,191,179,168)
$icon = [Drawing.Icon]::FromHandle($bmp.GetHicon())
$stream = [IO.File]::Create((Join-Path $root 'windows\runner\resources\app_icon.ico'))
$icon.Save($stream)
$stream.Dispose(); $icon.Dispose(); $pen.Dispose(); $green.Dispose(); $dark.Dispose(); $flame.Dispose(); $g.Dispose(); $bmp.Dispose()
