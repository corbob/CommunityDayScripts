function Invoke-GH {
    gh @args | ConvertFrom-Json
}
