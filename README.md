# Script-Powershell
Ensemble de script powershell

### Utilisation

#### Script remed_RBCD.ps1

Appliquer le script sur le Common-Name "Computers":
``` 
PS C:\Users\AISI\Desktop> .\remed_RBCD.ps1 -TargetDN "CN=Computers,DC=aisi,DC=local"

Objet cible à modifier : CN=Computers,DC=aisi,DC=local
Application de la nouvelle règle (Set-Acl)...
OK : La règle Deny a été ajoutée avec succès pour SELF sur 'msDs-AllowedToActOnBehalfOfOtherIdentity' (objets Computer) !
Fin du script.
```

Appliquer le script sur une unité d’organisation "testOU":
```
PS C:\Users\AISI\Desktop> .\remed_RBCD.ps1 -TargetDN "OU=testOU,DC=aisi,DC=local"
Objet cible à modifier : OU=testOU,DC=aisi,DC=local
Application de la nouvelle règle (Set-Acl)...
OK : La règle Deny a été ajoutée avec succès pour SELF sur 'msDs-AllowedToActOnBehalfOfOtherIdentity' (objets Computer) !
Fin du script.
```
