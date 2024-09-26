$bookmarksPath = "$Env:USERPROFILE\.config\Set-Bookmark\bookmarks.json"

$qwertyProximity = @{
  'q' = @('w', 'a')
  'w' = @('q', 'e', 'a', 's')
  'e' = @('w', 'r', 's', 'd')
  'r' = @('e', 't', 'd', 'f')
  't' = @('r', 'y', 'f', 'g')
  'y' = @('t', 'u', 'g', 'h')
  'u' = @('y', 'i', 'h', 'j')
  'i' = @('u', 'o', 'j', 'k')
  'o' = @('i', 'p', 'k', 'l')
  'p' = @('o', 'l')
  'a' = @('q', 'w', 's', 'z')
  's' = @('a', 'w', 'e', 'd', 'z', 'x')
  'd' = @('s', 'e', 'r', 'f', 'x', 'c')
  'f' = @('d', 'r', 't', 'g', 'c', 'v')
  'g' = @('f', 't', 'y', 'h', 'v', 'b')
  'h' = @('g', 'y', 'u', 'j', 'b', 'n')
  'j' = @('h', 'u', 'i', 'k', 'n', 'm')
  'k' = @('j', 'i', 'o', 'l', 'm')
  'l' = @('k', 'o', 'p')
  'z' = @('a', 's', 'x')
  'x' = @('z', 's', 'd', 'c')
  'c' = @('x', 'd', 'f', 'v')
  'v' = @('c', 'f', 'g', 'b')
  'b' = @('v', 'g', 'h', 'n')
  'n' = @('b', 'h', 'j', 'm')
  'm' = @('n', 'j', 'k')
}

function Test-QWERTYNeighbor {
  param (
    [char]$char1,
    [char]$char2
  )

  # Convert char to string and then use ToLower() with parentheses
  $char1 = ([string]$char1).ToLower()
  $char2 = ([string]$char2).ToLower()

  if ($qwertyProximity.ContainsKey($char1)) {
    return $qwertyProximity[$char1] -contains $char2
  }
  return $false
}



function Get-LevenshteinDistance {
  param (
    [string]$source,
    [string]$target
  )

  $sourceLength = $source.Length
  $targetLength = $target.Length

  # Initialize a matrix of size (sourceLength+1) x (targetLength+1)
  $distanceMatrix = @()

  for ($i = 0; $i -le $sourceLength; $i++) {
    $row = @()
    for ($j = 0; $j -le $targetLength; $j++) {
      $row += 0
    }
    $distanceMatrix += , $row
  }

  # Set up the initial row and column
  for ($i = 0; $i -le $sourceLength; $i++) {
    $distanceMatrix[$i][0] = $i
  }
  for ($j = 0; $j -le $targetLength; $j++) {
    $distanceMatrix[0][$j] = $j
  }

  # Compute the Levenshtein distance
  for ($i = 1; $i -le $sourceLength; $i++) {
    for ($j = 1; $j -le $targetLength; $j++) {
      $cost = if ($source[$i - 1] -eq $target[$j - 1]) { 0 } else { 1 }

      $distanceMatrix[$i][$j] = [math]::Min(
        [math]::Min($distanceMatrix[$i - 1][$j] + 1, $distanceMatrix[$i][$j - 1] + 1),
        $distanceMatrix[$i - 1][$j - 1] + $cost
      )
    }
  }

  return $distanceMatrix[$sourceLength][$targetLength]
}


function Get-ClosestMatch {
  param (
    [string]$inputString,
    [hashtable]$bookmarks
  )

  $closest = $null
  $shortestDistance = [int]::MaxValue
  $inputLength = $inputString.Length

  # Handle single character input
  if ($inputLength -eq 1) {
    # Get the QWERTY neighbors for the input character
    $neighbors = $qwertyProximity[$inputString.ToLower()]
      
    foreach ($key in $bookmarks.Keys) {
      if ($key.Length -eq 1 -and ($neighbors -contains $key.ToLower())) {
        return $key  # Immediately return the first match found
      }
    }
  }

  # Fallback to Levenshtein distance for multi-character input or no QWERTY match
  foreach ($key in $bookmarks.Keys) {
    $distance = Get-LevenshteinDistance -source $inputString -target $key
    if ($distance -lt $shortestDistance) {
      $shortestDistance = $distance
      $closest = $key
    }
    elseif ($distance -eq $shortestDistance) {
      # Prefer the longer string
      if ($closest -and $key.Length -gt $closest.Length) {
        $closest = $key
      }
    }
  }

  return $closest
}

function Open-BookmarksFile {
  param (
    [string]$filePath
  )

  # Try to open the config file in default editor
  if ($env:EDITOR) {
    try {
      Start-Process -FilePath $env:EDITOR -ArgumentList "`"$filePath`"" -NoNewWindow -ErrorAction Stop
      return
    }
    catch {
      Write-Error "Failed to open the editor specified in EDITOR environment variable: $($_.Exception.Message)"
      return
    }
  }

  # Try to open the config file in Visual Studio Code
  try {
    $codePath = (Get-Command code -ErrorAction Stop).Source
    Start-Process -FilePath $codePath -ArgumentList "`"$filePath`"" -NoNewWindow -ErrorAction Stop
    return
  }
  catch {
    # 'code' is not installed
  }

  Write-Error "No editor found. Please set the EDITOR environment variable or install Visual Studio Code."
}


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

  .PARAMETER Edit
  Open the bookmarks file in the default text editor. Alias: e

  .EXAMPLE
  Set-Bookmark p C:\Projects -Add
  Adds a bookmark named 'p' for the path 'C:\Projects'

  .EXAMPLE
  Set-Bookmark p -Remove
  Removes the bookmark named 'p'

  .EXAMPLE
  Set-Bookmark -List
  Lists all bookmarks

  .EXAMPLE
  Set-Bookmark -Edit
  Opens the bookmarks file in the default editor.
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
    [switch]$List,
    [Alias("e")]
    [switch]$Edit,
    [Alias("h")]
    [switch]$Help
  )

  if ($Help) {
    Get-Help Set-Bookmark
    Return
  }

  # Handle the -Edit switch
  if ($Edit) {
    if (Test-Path $bookmarksPath) {
      Open-BookmarksFile -filePath $bookmarksPath
    }
    else {
      Write-Error "Bookmarks file not found at '$bookmarksPath'."
    }
    return
  }

  # Initialize the bookmarks file if it doesn't exist
  if (-not (Test-Path $bookmarksPath)) {
    New-Item -Path $bookmarksPath -ItemType File -Force | Out-Null
    @{ d = "C:\Dev" } | ConvertTo-Json | Set-Content $bookmarksPath
  }

  # Load bookmarks
  try {
    $bookmarks = Get-Content $bookmarksPath -Raw | ConvertFrom-Json -AsHashtable
  }
  catch {
    Write-Error "Failed to read the bookmarks file: $($_.Exception.Message)"
    return
  }

  # List booksmarks (default action if no switches are provided)
  if ($List -or $PSBoundParameters.Count -eq 0) {
    if ($bookmarks.Count -eq 0) {
      Write-Host "No bookmarks found." -ForegroundColor Yellow
    }
    else {
      # Group bookmarks by Path
      $groupedBookmarks = $bookmarks.GetEnumerator() | Group-Object -Property Value

      # Create a custom object for each group with concatenated Names
      $output = $groupedBookmarks | ForEach-Object {
        [PSCustomObject]@{
          Names = ($_.Group | Select-Object -ExpandProperty Key) -join ", "
          Path  = $_.Name
        }
      }

      $output | Format-Table -AutoSize
    }
    return
  }

  # Add a new bookmark
  if ($Add) {
    if ($bookmarks.ContainsKey($Name)) {
      Write-Host "'$Name' already exists." -ForegroundColor Yellow
      $overwrite = Read-Host "Overwrite? (y/n)"
      if ($overwrite -inotmatch "y") {
        return
      }
    }
    $bookmarks[$Name] = $Path
    try {
      $bookmarks | ConvertTo-Json | Set-Content $bookmarksPath
      Write-Host "$Name -> $Path added" -ForegroundColor Green
    }
    catch {
      Write-Error "Failed to write to the configuration file: $($_.Exception.Message)"
    }
    return
  }

  # Remove a bookmark 
  if ($Remove) {
    if ($bookmarks.ContainsKey($Name)) {
      $bookmarks.Remove($Name)
      try {
        $bookmarks | ConvertTo-Json | Set-Content $bookmarksPath
        Write-Host "$Name removed" -ForegroundColor Yellow
      }
      catch {
        Write-Error "Failed to write to the configuration file: $($_.Exception.Message)"
      }
    }
    else {
      Write-Host "'$Name' does not exist." -ForegroundColor Yellow
    }
    return
  }

  # Navigate to a bookmark
  if ($Name) {
    if ($bookmarks.ContainsKey($Name)) {
      Set-Location $bookmarks[$Name]
    }
    else {
      $suggestedName = Get-ClosestMatch -input $Name -bookmarks $bookmarks
      if ($suggestedName) {
        Write-Host "'$Name' not found. Did you mean '$suggestedName'?" -ForegroundColor Yellow
        $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown').VirtualKeyCode
        if ($key -eq 13) {
          # Enter key pressed
          Set-Location $bookmarks[$suggestedName]
        }
        elseif ($key -eq 27) {
          # Esc key pressed
          Return
        }
      }
      else {
        Write-Error "'$Name' not found and no close matches were found."
      }
    }
  }
}

Register-ArgumentCompleter -CommandName Set-Bookmark -ParameterName Name -ScriptBlock {
  param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

  try {
    if (Test-Path $bookmarksPath) {
      $bookmarks = Get-Content $bookmarksPath -Raw | ConvertFrom-Json -AsHashtable
      $bookmarks.Keys | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
      }
    }
  }
  catch {
    # Handle errors or do nothing
  }
}