<#
.SYNOPSIS
    Ajoute une ACE (Access Control Entry) de type Deny pour SELF sur l'attribut
    msDs-AllowedToActOnBehalfOfOtherIdentity, pour les objets de type Computer,
    descendants de l'objet AD ciblé (container ou OU).
    
    Avec gestion d'erreurs et messages clairs si l'utilisateur
    n'a pas les privilèges requis.

.DESCRIPTION
    - Vérifie d'abord si PowerShell est lancé en mode administrateur local.
    - Importe le module ActiveDirectory.
    - Récupère l'objet cible (container ou OU).
    - Récupère les GUID de l'attribut et de la classe Computer.
    - Crée et applique l'ACE de type Deny pour SELF.

.PARAMETER TargetDN
    DN de l'objet AD (par ex. "CN=Computers,DC=aisi,DC=local" ou "OU=MyComputers,DC=aisi,DC=local").

.PARAMETER WhatIf
    Affiche la règle qui serait ajoutée sans l'appliquer.

.NOTES
    Nécessite le module ActiveDirectory (RSAT).
    Doit être exécuté en PowerShell en mode Administrateur.
    Et requiert des droits suffisants en AD (souvent Domain Admin).
#>

Param(
    [Parameter(Mandatory=$true)]
    [string]$TargetDN,  # Ex: "CN=Computers,DC=aisi,DC=local" ou "OU=MyComputers,DC=aisi,DC=local"
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

#region [Vérification du mode Administrateur local]
# -- Vérification si l’utilisateur a ouvert la session PowerShell "en tant qu’Administrateur"
$principal = New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())
if(-not ($principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))) {
    Write-Host "ERREUR : Vous devez exécuter ce script en mode Administrateur (clic droit > 'Exécuter en tant qu'administrateur')." -ForegroundColor Red
    return
}
#endregion

#region [Import du module ActiveDirectory]
try {
    Import-Module ActiveDirectory -ErrorAction Stop
}
catch {
    Write-Host "ERREUR : Impossible de charger le module ActiveDirectory. Vérifiez que RSAT est installé et que vous avez les droits adéquats." -ForegroundColor Red
    return
}
#endregion

Write-Host "Objet cible à modifier : $TargetDN" -ForegroundColor Cyan

#region [Récupération de l’objet AD visé]
try {
    $TargetObject = Get-ADObject -Identity $TargetDN -ErrorAction Stop
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    Write-Host "ERREUR : L'objet '$TargetDN' est introuvable dans l'AD. Vérifiez la syntaxe (CN=..., OU=...)." -ForegroundColor Red
    return
}
catch {
    Write-Host "ERREUR : Problème lors de la récupération de l'objet '$TargetDN' : $($_.Exception.Message)" -ForegroundColor Red
    return
}
#endregion

#region [Récupération des GUID : attribut + classe]
try {
    $rootDSE = Get-ADRootDSE
    $schemaNC = $rootDSE.SchemaNamingContext

    # 1) GUID de l'attribut msDs-AllowedToActOnBehalfOfOtherIdentity
    $attribute = Get-ADObject -SearchBase $schemaNC `
                              -LDAPFilter '(ldapDisplayName=msDs-AllowedToActOnBehalfOfOtherIdentity)' `
                              -Properties schemaIDGUID
    if (-not $attribute) {
        Write-Host "ERREUR : Attribut msDs-AllowedToActOnBehalfOfOtherIdentity introuvable dans le schéma !" -ForegroundColor Red
        return
    }
    $attributeGUID = [Guid]$attribute.schemaIDGUID

    # 2) GUID de la classe 'computer'
    $computerClass = Get-ADObject -SearchBase $schemaNC `
                                  -LDAPFilter '(ldapDisplayName=computer)' `
                                  -Properties schemaIDGUID
    if (-not $computerClass) {
        Write-Host "ERREUR : Classe 'computer' introuvable dans le schéma !" -ForegroundColor Red
        return
    }
    $computerClassGUID = [Guid]$computerClass.schemaIDGUID
}
catch {
    Write-Host "ERREUR : Problème lors de la récupération des GUID : $($_.Exception.Message)" -ForegroundColor Red
    return
}
#endregion

#region [Création de l'ACE]
try {
    $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
        ([System.Security.Principal.NTAccount]"NT AUTHORITY\SELF"),        # Identité
        ([System.DirectoryServices.ActiveDirectoryRights]"WriteProperty"), # Droits
        ([System.Security.AccessControl.AccessControlType]"Deny"),         # Type: Deny
        $attributeGUID,                                                    # GUID de l'attribut
        ([System.DirectoryServices.ActiveDirectorySecurityInheritance]"Descendents"), # Héritage sur objets descendants
        $computerClassGUID                                                 # Appliqué seulement sur la classe "Computer"
    )
}
catch {
    Write-Host "ERREUR : Problème lors de la création de l'ACE : $($_.Exception.Message)" -ForegroundColor Red
    return
}
#endregion

#region [Ajout de la règle dans la DACL]
try {
    $acl = Get-Acl -Path "AD:$TargetDN"

    # Ajout de la nouvelle ACE dans la DACL
    $acl.AddAccessRule($ACE)

    if ($WhatIf) {
        Write-Host "[WhatIf] Voici la règle qui SERAIT ajoutée, sans appliquer :" -ForegroundColor Yellow
        Write-Host "--------------------------------------------------------------"
        Write-Host "     CN/OU Cible        : $TargetDN                          "
        Write-Host "     Identité affectée  : $($ACE.IdentityReference)"
        Write-Host "     Type d'accès       : $($ACE.AccessControlType)"
        Write-Host "     Droit AD           : $($ACE.ActiveDirectoryRights)"
        Write-Host "     Attribut ciblé     : msDs-AllowedToActOnBehalfOfOtherIdentity"
        Write-Host "     Appliqué à         : Descendants uniquement (Classe 'Computer')"
        Write-Host "--------------------------------------------------------------"
        Write-Host "`n[WhatIf] Aucune modification n'est réellement appliquée." -ForegroundColor Yellow
    }
    else {
        Write-Host "Application de la nouvelle règle (Set-Acl)..." -ForegroundColor Cyan
        Set-Acl -Path "AD:$TargetDN" -AclObject $acl
        Write-Host "OK : La règle Deny a été ajoutée avec succès pour SELF sur 'msDs-AllowedToActOnBehalfOfOtherIdentity' (objets Computer) !" -ForegroundColor Green
    }
}
catch [System.UnauthorizedAccessException] {
    Write-Host "ERREUR : Accès refusé. Vous n'avez pas les permissions suffisantes dans AD (ex. vous devez probablement être Domain Admin) et/ou PowerShell n'est pas en mode Admin." -ForegroundColor Red
    return
}
catch {
    Write-Host "ERREUR : Problème lors de l'ajout ou l'application de la règle ACL : $($_.Exception.Message)" -ForegroundColor Red
    return
}
#endregion

Write-Host "Fin du script." -ForegroundColor Cyan
