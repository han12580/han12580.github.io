param(
  [string]$jsonFile = "notes-export.json"
)

if(-not (Test-Path $jsonFile)){
  Write-Error "JSON 文件不存在: $jsonFile"
  exit 1
}

try{
  $raw = Get-Content -Raw -Path $jsonFile -ErrorAction Stop
  $data = $raw | ConvertFrom-Json -ErrorAction Stop
}catch{
  Write-Error "解析 JSON 失败: $_"
  exit 1
}

$notes = $data.notes
if(-not $notes){ Write-Error "JSON 不包含 notes 字段或为空。"; exit 1 }

$papersDir = Join-Path -Path (Get-Location) -ChildPath "papers"
if(-not (Test-Path $papersDir)){ New-Item -ItemType Directory -Path $papersDir | Out-Null }

$index = @()
foreach($n in $notes){
  $meta = $n.meta
  if(-not $meta){ continue }
  # derive path
  $path = $meta.path
  if(-not $path){ $name = "note-$($meta.id -as [string])"; $path = "papers/$name.html" }
  # sanitize path
  $filename = Split-Path $path -Leaf
  $fullPath = Join-Path $papersDir $filename
  # write html content
  $html = $n.html -replace "\r\n","`n"
  Set-Content -Path $fullPath -Value $html -Encoding UTF8
  # add entry to index (ensure path is relative)
  $index += @{ id = $meta.id; title = $meta.title; authors = $meta.authors; date = $meta.date; tags = $meta.tags; path = "papers/$filename" }
  Write-Host "Wrote $fullPath"
}

# write papers/index.json
$indexJson = $index | ConvertTo-Json -Depth 10
Set-Content -Path (Join-Path $papersDir 'index.json') -Value $indexJson -Encoding UTF8
Write-Host "Wrote papers/index.json"
Write-Host "导入完成。请用 git add/commit/push 提交更改。"