# 📜 Script PowerShell

Ce script PowerShell permet d'ajouter une règle Deny sur l'attribut msDs-AllowedToActOnBehalfOfOtherIdentity pour SELF, empêchant ainsi les ordinateurs de définir une délégation RBCD sur eux-mêmes.

### ⚙️ Utilisation du script

#### > Appliquer la restriction sur le containerpar défaut "Computers":
``` 
PS C:\Users\AISI\Desktop> .\remed_RBCD.ps1 -TargetDN "CN=Computers,DC=aisi,DC=local"

Objet cible à modifier : CN=Computers,DC=aisi,DC=local
Application de la nouvelle règle (Set-Acl)...
OK : La règle Deny a été ajoutée avec succès pour SELF sur 'msDs-AllowedToActOnBehalfOfOtherIdentity' (objets Computer) !
Fin du script.
```

#### > Appliquer la restriction sur une Unité d’Organisation (OU)
```
PS C:\Users\AISI\Desktop> .\remed_RBCD.ps1 -TargetDN "OU=testOU,DC=aisi,DC=local"
Objet cible à modifier : OU=testOU,DC=aisi,DC=local
Application de la nouvelle règle (Set-Acl)...
OK : La règle Deny a été ajoutée avec succès pour SELF sur 'msDs-AllowedToActOnBehalfOfOtherIdentity' (objets Computer) !
Fin du script.
```
