# Loader.ps1
$baseUrl = "https://raw.githubusercontent.com/Atlas2590/PS-Server/main"
$files = @("Lib_Utils.ps1", "Lib_AD.ps1", "Lib_GPO.ps1", "Lib_FileZilla.ps1", "Main.ps1")

Write-Host "Inizializzazione AD Tools Cloud..." -ForegroundColor Cyan

foreach ($f in $files) {
    try {
        $url = "$baseUrl/$f"
        $code = Invoke-RestMethod -Uri $url -Method Get
        Invoke-Expression $code
        Write-Host " [+] Modulo $f caricato." -ForegroundColor Green
    } catch {
        Write-Host " [!] Errore nel caricamento di $f" -ForegroundColor Red
    }
}

# Avvia la funzione principale definita nel Main.ps1
Show-MenuPrincipale
