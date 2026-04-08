
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$baseUrl = "https://raw.githubusercontent.com/Atlas2590/PS-Server/main"
$files = @("Lib_Utils.ps1", "Lib_AD.ps1", "Lib_GPO.ps1", "Lib_FileZilla.ps1", "Main.ps1")

Write-Host "`n--- Inizializzazione AD Tools Cloud ---" -ForegroundColor Cyan

foreach ($f in $files) {
    $url = "$baseUrl/$f"
    try {
        # Usiamo un User-Agent per simulare un browser e forzare l'encoding UTF8
        $code = Invoke-RestMethod -Uri $url -Method Get -Headers @{"User-Agent"="Mozilla/5.0"}
        
        if ($null -ne $code) {
            Invoke-Expression $code
            Write-Host " [+] $f caricato correttamente." -ForegroundColor Green
        }
    } catch {
        Write-Host " [!] Errore su $f" -ForegroundColor Red
        Write-Host "     Dettaglio: $($_.Exception.Message)" -ForegroundColor Gray
    }
}

if (Get-Command Show-MenuPrincipale -ErrorAction SilentlyContinue) {
    Show-MenuPrincipale
} else {
    Write-Host "`n[!] ERRORE: Funzione Show-MenuPrincipale non trovata." -ForegroundColor Red
}
