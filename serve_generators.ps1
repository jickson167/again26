# 로컬 HTML 생성기용 미니 서버 (Python 없을 때)
$port = 8888
$root = $PSScriptRoot
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "선수 생성기: http://localhost:$port/player_row_generator_v3.html"
Write-Host "종료: Ctrl+C"
Start-Process "http://localhost:$port/player_row_generator_v3.html"

while ($listener.IsListening) {
  $context = $listener.GetContext()
  $path = $context.Request.Url.LocalPath
  if ($path -eq "/") { $path = "/player_row_generator_v3.html" }
  $relative = $path.TrimStart("/").Replace("/", [IO.Path]::DirectorySeparatorChar)
  $file = Join-Path $root $relative
  if (Test-Path $file -PathType Leaf) {
    $bytes = [System.IO.File]::ReadAllBytes($file)
    $ext = [System.IO.Path]::GetExtension($file).ToLower()
    $type = switch ($ext) {
      ".html" { "text/html; charset=utf-8" }
      ".js" { "application/javascript; charset=utf-8" }
      ".css" { "text/css; charset=utf-8" }
      ".csv" { "text/csv; charset=utf-8" }
      default { "application/octet-stream" }
    }
    $context.Response.ContentType = $type
    $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  } else {
    $context.Response.StatusCode = 404
    $msg = [Text.Encoding]::UTF8.GetBytes("Not found: $path")
    $context.Response.OutputStream.Write($msg, 0, $msg.Length)
  }
  $context.Response.Close()
}
