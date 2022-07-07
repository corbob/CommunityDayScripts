Get-ChildItem $PSScriptRoot -Include *.ps1 -Recurse | ForEach-Object {
    . $_
}
