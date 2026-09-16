# V0.4 diagnostic — synchronisation avec Principal V1.6.7

Cette version corrige le format réseau mobile après vérification du binaire Principal V1.6.7.

## Cause principale corrigée

Le Principal attend un événement avec `type` et un objet métier imbriqué (`attendance`, `evaluation`, `communication`, `quranValidation`, etc.). La V0.3 envoyait `category` et fusionnait les champs métier à la racine.

## Sécurité de file d'attente

La V0.4 ne retire plus une saisie parce que le Principal renvoie seulement un compteur `received`. Une saisie est retirée uniquement lorsque son identifiant apparaît explicitement dans `acknowledgedIds`.

Les valeurs `received`, `rejected`, `duplicates` et `errors` sont affichées dans le diagnostic du dernier envoi.

## Compatibilité confirmée V1.6.7

Types réseau utilisés :
- attendance
- evaluation
- communication
- quran_validation
- homework
- annual_appreciation

`lessonFollowUp` n'est pas reconnu par V1.6.7 : le suivi de leçon reste local et est signalé comme non compatible au lieu d'être faussement annoncé comme synchronisé.

## Données élèves

Le Principal V1.6.7 envoie `last` et `first`. La V0.4 les lit désormais comme nom et prénom. La sélection d'une classe ouvre une vraie liste d'élèves triée par NOM Prénom.

## Planning

Le planning n'est pas une condition préalable à la réception d'une absence ou d'un retard. Il peut servir à d'autres calculs, mais la validation réseau attendance repose notamment sur l'autorisation professeur/classe/élève et sur le contenu date/type/heure d'arrivée.
