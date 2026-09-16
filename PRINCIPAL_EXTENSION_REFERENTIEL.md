# Extension minimale du PC Principal pour ÉCOLE GESTION PROF MOBILE V0.3

L'analyse du binaire V1.6.7 montre que le Principal possède déjà les fonctions/objets nécessaires, notamment :

- `schoolHizbArabicName`
- `schoolJuzArabicName`
- `schoolQuranSurahNumberByName`
- `schoolLessonItems`
- `schoolLessonLabel`
- `SchoolLesson`
- `SchoolLessonFollowUp`

La version mobile **ne doit pas recréer ces listes**. Le Principal doit les exposer en lecture seule via :

`GET /api/v1/reference-data?teacher=...&code=...`

avec la même authentification professeur/code que `/api/v1/sync`.

## Contenu attendu

1. `schoolTitle` : le titre exact à afficher dans le mobile ;
2. `surahs` : numéro, nom, nom arabe, nombre de versets ;
3. `hizbs` : numéro + nom arabe détenu par le Principal ;
4. `juzs` : numéro + nom arabe détenu par le Principal ;
5. `lessons` : identifiant, numéro, matière, libellé ;
6. `incidentTypes` : natures proposées dans le rideau Incident.

Le téléphone met ce référentiel en cache. À chaque synchronisation, toute modification du Principal remplace le cache mobile.

## Écriture / historique

Le Principal reste la base officielle. Les événements mobiles comportent un identifiant unique + un `deviceId`. Le Principal doit conserver ces identifiants afin de :

- ne pas enregistrer deux fois la même saisie après une coupure réseau ;
- permettre l'alternance téléphone / logiciel Prof Windows ;
- reconstruire l'historique sur un nouveau téléphone à partir de la base Principal.

Cette extension n'oblige pas à supprimer ou modifier les endpoints V6 existants du logiciel Prof Windows.
