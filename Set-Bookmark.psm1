$configPath = "$Env:USERPROFILE\.config\Set-Bookmark\bookmarks.json"

function Set-Bookmark {
  <#
  .SYNOPSIS
  Set-Bookmark is a PowerShell module that allows you to bookmark directories and quickly navigate to them.

  .DESCRIPTION
  Set-Bookmark stores the bookmarks in a JSON file in  $Env:USERPROFILE\.config\Set-Bookmark\bookmarks.json

  .PARAMETER Name
  The name / alias of the bookmarked path. Alias: n

  .PARAMETER Path
  The path to bookmark. Defaults to the current directory.

  .PARAMETER Add
  Add a new bookmark. Alias: a

  .PARAMETER Remove
  Remove a bookmark. Alias: r, d, Delete

  .PARAMETER List
  List all bookmarks. Alias: l

  .EXAMPLE
  Set-Bookmark p C:\Projects -Add
  Adds a bookmark named 'p' for the path 'C:\Projects'

  .EXAMPLE
  Set-Bookmark p -Remove
  Removes the bookmark named 'p'

  .EXAMPLE
  Set-Bookmark -List
  Lists all bookmarks
#>

  [CmdletBinding()]
  param(
    [Alias("n")]
    [string]$Name,
    [string]$Path = (Get-Location).Path,
    [Alias("a")]
    [switch]$Add,
    [Alias("r", "d", "Delete")]
    [switch]$Remove,
    [Alias("l")]
    [switch]$List
  )

  if (-not (Test-Path $configPath)) {
    New-Item -Path $configPath -ItemType File -Force | Out-Null
    @{d = "C:\Dev" } | ConvertTo-Json | Set-Content $configPath
  }

  $bookmarks = Get-Content $configPath -Raw | ConvertFrom-Json -AsHashtable

  if ($Add) {
    if ($bookmarks.ContainsKey($Name)) {
      Write-Host "'$Name' already exists." -ForegroundColor Yellow
      $overwrite = Read-Host "Overwrite? (y/n)"
      if ($overwrite -inotmatch "y") {
        return
      }
    }
    $bookmarks[$Name] = $Path
    $bookmarks | ConvertTo-Json | Set-Content $configPath
    Write-Host "$Name -> $Path added" -ForegroundColor Green
    return
  }

  if ($List -or $PSBoundParameters.Count -eq 0) {
    $bookmarks | Format-Table -AutoSize `
    @{Label = "Name"; Expression = { $_.Key } }, `
    @{Label = "Path"; Expression = { $_.Value } }
    return
  }

  if ($Remove) {
    $bookmarks.Remove($Name)
    $bookmarks | ConvertTo-Json | Set-Content $configPath
    Write-Host "$Name removed" -ForegroundColor Yellow
    return
  }

  if ($Name) {
    if ($bookmarks.ContainsKey($Name)) {
      Set-Location $bookmarks[$Name]
    }
    else {
      Write-Error "$Name not found"
    }
  }
}

Register-ArgumentCompleter -CommandName Set-Bookmark -ParameterName Name -ScriptBlock {
  param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

  try {
    if (Test-Path $configPath) {
      $bookmarks = Get-Content $configPath -Raw | ConvertFrom-Json -AsHashtable
      $bookmarks.Keys | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
      }
    }
  }
  catch {
    # Handle errors or do nothing
  }
}