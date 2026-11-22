# install.ps1 — installe la factory dans le dossier courant (depuis le clone du pattern).
# Usage :
#   Nouveau projet :  git clone https://github.com/Mar2684/software-factory.git MonProjet ; cd MonProjet ; .\install.ps1 -Mode New
#   Projet existant : dans le dossier du projet : ..\software-factory\install.ps1 -Mode Existing
# Si PowerShell bloque l'execution des scripts :
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 -Mode New
param([Parameter(Mandatory=$true)][ValidateSet("New","Existing")][string]$Mode)

$patternRoot = $PSScriptRoot

if ($Mode -eq "New") {
  # Cas 1 : on EST deja le dossier du projet (clone du pattern) : rien a copier,
  # on enleve juste l'origine du pattern historique pour repartir d'une origine propre.
  git remote remove origin 2>$null | Out-Null

  # Contrat des deux README : le README du pattern devient la doc de L'USINE (factory/README.md),
  # la racine recoit un README minimal pour LE LOGICIEL (que /factory approve enrichira a chaque merge).
  if (-not (Test-Path "factory/README.md")) {
    if (Test-Path "README.md") { Move-Item "README.md" "factory/README.md" -Force }
  }
  if (-not (Test-Path "README.md")) {
    Set-Content "README.md" "# Mon logiciel`n`nCe dossier est le LOGICIEL produit par l'usine. Sa doc s'ecrit ici, enrichie a chaque merge.`nLa doc de l'USINE vit dans factory/README.md.`n"
  }

  if (-not (Test-Path ".gitignore")) { New-Item ".gitignore" | Out-Null }
  Add-Content ".gitignore" "__pycache__/`nnode_modules/`ndist/`n.factory/`nfactory/board.json.tmp`nworkspace/`nfactory/fiches/essais/"
  Write-Host "Factory installee. Prochain pas : ouvrir une session Vibe Code ici, puis /factory context."
  Write-Host "✅ Projet prêt. L'usine poussera main à chaque /factory approve."
  Write-Host "📌 Prochain pas (lier la sauvegarde) : gh repo create <mon-projet> --private --source . --remote origin --push"
} else {
  # Cas 2 : projet existant : on copie le pattern (.vibe/ + factory/ + install.ps1) DANS le projet.
  foreach ($item in @(".vibe", "factory", "install.ps1")) {
    $dest = Join-Path (Get-Location) $item
    if (Test-Path $dest) { Write-Warning "$item existe deja : non ecrase."; continue }
    Copy-Item -Recurse -Force (Join-Path $patternRoot $item) $dest
  }
  if (-not (Test-Path ".gitignore")) { New-Item ".gitignore" | Out-Null }
  Add-Content ".gitignore" "factory/board.json.tmp`nfactory/fiches/essais/"
  Write-Host "Factory installee dans le projet existant."
  Write-Host "Prochain pas : /factory context AVANT tout job (le resumer dresse la carte du logiciel)."
}
