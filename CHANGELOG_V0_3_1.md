# V0.3.1 — Correctif défilement mobile

- Tous les formulaires utilisent un défilement vertical forcé (`AlwaysScrollableScrollPhysics`).
- Glisser la page masque le clavier (`ScrollViewKeyboardDismissBehavior.onDrag`).
- Les écrans de saisie utilisent explicitement `resizeToAvoidBottomInset: true`.
- Une marge basse dynamique tient compte de la barre système et du clavier.
- Les boutons Enregistrer restent accessibles en bas de page sur petits écrans.
- Les listes Classes et Historique disposent également d’une marge basse de sécurité.
- Aucun changement du protocole réseau V6 ni des données synchronisées.
