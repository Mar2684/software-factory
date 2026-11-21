# install.ps1 — installe la factory dans le dossier courant (depuis le clone du pattern).
# Usage :
#   Nouveau projet :  git clone https://github.com/Mar2684/software-factory.git MonProjet ; cd MonProjet ; .\install.ps1 -New
#   Projet existant : dans le dossier du projet : .\install.ps1 -Existing
param([Parameter(Mandatory=$true)][ValidateSet("New","Existing")][string]$Mode)

$patternRoot = $PSScriptRoot

if ($Mode -eq "New") {
  # Cas 1 : on EST déjà le dossier du projet (clone du pattern) : rien à copier,
  # on enlève juste l'origine du pattern historique pour repartir d'une origine propre.
  git remote remove origin 2>$null | Out-Null
  if (-not (Test-Path ".gitignore")) { New-Item ".gitignore" | Out-Null }
  Add-Content ".gitignore" "__pycache__/`nnode_modules/`ndist/`n.factory/`nfactory/board.json.tmp"
  Write-Host "Factory installee. Prochain pas : ouvrir une session Vibe Code ici, puis /factory context."
} else {
  # Cas 2 : projet existant : on copie le pattern (.vibe/ + factory/ + install.ps1) DANS le projet.
  foreach ($item in @(".vibe", "factory", "install.ps1")) {
    $dest = Join-Path (Get-Location) $item
    if (Test-Path $dest) { Write-Warning "$item existe deja : non ecrase."; continue }
    Copy-Item -Recurse -Force (Join-Path $patternRoot $item) $dest
  }
  Write-Host "Factory installee dans le projet existant."
  Write-Host "Prochain pas : /factory context AVANT tout job (le resumer dresse la carte du logiciel)."
}
