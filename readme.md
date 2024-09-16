# Set-Bookmark PowerShell Module

`Set-Bookmark` is a PowerShell module that allows you to bookmark directories and quickly navigate to them. Bookmarks are stored in a JSON file located at `$Env:USERPROFILE\.config\Set-Bookmark\bookmarks.json`.

## Features

- **Add Bookmarks**: Bookmark a directory and assign a name to it.
- **Remove Bookmarks**: Delete bookmarks by name.
- **List Bookmarks**: View all saved bookmarks.
- **Navigate Bookmarks**: Quickly change the current directory by using a bookmark.

## Installation

1. Clone or download the repository to your machine.
2. Import the module into your PowerShell session:
    ```powershell
    Import-Module path\to\Set-Bookmark.psm1
    ```
3. Optionally, add the import statement to your PowerShell profile to automatically load the module in every session.

## Usage

### Adding a Bookmark

To add a bookmark for the current directory or a specific path:

```powershell
Set-Bookmark -Add -Name "mybookmark"
```

## Command Alias
To alias the `Set-Bookmark` command to `'g'` add this line to your Powershell profile

```powershell
Set-Alias -Name g -Value Set-Bookmark
```

## Examples

### Add a bookmark for your projects folder
```powershell
PS> g p C:\Projects
p -> C:\Projects added
```


### List all bookmarks
```powershell
PS> g
Name Path
---- ----
h    C:\Users\username
d    C:\Dev
p    C:\Projects
s    C:\Dev\scratch
```