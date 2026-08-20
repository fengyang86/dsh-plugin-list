<#
.SYNOPSIS
  按 plugins.json 清单安装 dsh 插件（多机同步用）。跨平台：Windows / macOS / Linux 均可用 pwsh 运行。

.DESCRIPTION
  读取本仓库 plugins.json，逐项执行 dsh plugin --profile <Profile> add <spec>。
  - 平台不匹配的项自动跳过（platforms 字段）
  - 已安装的项跳过（按 profile package.json 的 dependencies 判断）
  - 本地插件（local: true）默认跳过，除非 local.json 提供了本机 spec（每台机器路径不同）

.PARAMETER Profile
  dsh profile 名，默认 web。

.PARAMETER Dsh
  dsh 命令；默认探测 PATH 上的 dsh。在源码运行环境（如本仓库的 pnpm dsh）请传 -Dsh "pnpm dsh" 并在 dsh checkout 目录执行。

.PARAMETER DryRun
  只打印计划执行的命令，不真正安装。

.EXAMPLE
  pwsh ./install.ps1 -DryRun
  pwsh ./install.ps1 -Profile web -Dsh "pnpm dsh"
#>
param(
  [string]$Profile = 'web',
  [string]$Dsh = '',
  [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$manifest = Get-Content (Join-Path $root 'plugins.json') -Raw | ConvertFrom-Json
$local = @{}
$localPath = Join-Path $root 'local.json'
if (Test-Path $localPath) {
  $local = Get-Content $localPath -Raw | ConvertFrom-Json
}

# 平台判定（兼容 Windows PowerShell 5.1 与 pwsh）
if ($IsWindows -or $env:OS -match 'Windows') { $platform = 'win32' }
elseif ($IsMacOS) { $platform = 'darwin' }
elseif ($IsLinux) { $platform = 'linux' }
else { $platform = 'unknown' }
Write-Host "== platform: $platform, profile: $Profile ==" -ForegroundColor Cyan

if ($Dsh -eq '') {
  if (Get-Command dsh -ErrorAction SilentlyContinue) { $Dsh = 'dsh' }
  else { Write-Warning '未找到 dsh 命令：请用 -Dsh 指定（源码运行可传 "pnpm dsh"，并在 dsh checkout 目录执行本脚本）' }
}

# 已安装集合：profile package.json 的 dependencies 键
$installed = @{}
$profilePkg = Join-Path $env:USERPROFILE ".dshprofiles$Profilepackage.json"
if (Test-Path $profilePkg) {
  $pp = Get-Content $profilePkg -Raw | ConvertFrom-Json
  if ($pp.dependencies) { $pp.dependencies.PSObject.Properties | ForEach-Object { $installed[$_.Name] = $true } }
}

$count = 0
foreach ($p in $manifest.plugins) {
  $name = [string]$p.name
  # 平台过滤
  if ($p.platforms -and ($p.platforms -notcontains $platform)) {
    Write-Host "[skip ] $name（平台不适用）" -ForegroundColor DarkGray
    continue
  }
  # 本地插件：需 local.json 提供本机 spec
  $spec = [string]$p.spec
  if ($p.local) {
    if ($local.$name -and $local.$name.spec) { $spec = [string]$local.$name.spec }
    else { Write-Host "[skip ] $name（本地插件，local.json 未提供本机 spec）" -ForegroundColor DarkGray; continue }
  }
  # 已安装判断：npm spec 按包名；link: 每次都重跑（幂等重链）
  $isLink = $spec.StartsWith('link:')
  $pkgName = if ($isLink) { $null } else { $spec }
  if (-not $isLink -and $installed.ContainsKey($pkgName)) {
    Write-Host "[done ] $name（已安装）" -ForegroundColor Green
    continue
  }
  $count++
  if ($DryRun) {
    Write-Host "[plan ] $name -> dsh plugin --profile $Profile add $spec" -ForegroundColor Yellow
    continue
  }
  Write-Host "[inst ] $name -> $spec" -ForegroundColor Yellow
  if ($Dsh -ne '') {
    & $Dsh plugin --profile $Profile add $spec
    if ($LASTEXITCODE -ne 0) { Write-Error "安装失败：$name（$spec）" }
  }
}
Write-Host "== 完成：$count 项待处理 ==" -ForegroundColor Cyan
if ($DryRun -and $count -gt 0) { Write-Host "（DryRun 模式未执行任何安装）" }
