# Protocole mobile V0.3 — compatibilité réseau V6

## Endpoints V6 conservés

- `GET /api/v1/ping`
- `GET /api/v1/sync?teacher=...&code=...`
- `POST /api/v1/events?teacher=...&code=...`

Le logiciel Prof Windows peut donc continuer à utiliser le protocole V6 existant.

## Extension de référentiel (lecture seule)

La V0.3 mobile utilise également :

- `GET /api/v1/reference-data?teacher=...&code=...`

Cette route doit renvoyer les listes déjà détenues par le PC Principal. Le téléphone les met en cache pour le hors-ligne.

```json
{
  "schoolTitle": "TITRE EXACT DU PC PRINCIPAL",
  "surahs": [{"number": 1, "name": "Al-Fatiha", "arabic": "الفاتحة", "verseCount": 7}],
  "hizbs": [{"number": 1, "arabic": "..."}],
  "juzs": [{"number": 1, "arabic": "..."}],
  "lessons": [{"id": "...", "number": 1, "subject": "Arabe", "name": "Leçon 1"}],
  "incidentTypes": ["Discipline", "Matériel", "Autre"]
}
```

**Règle : les noms arabes ne sont pas maintenus séparément dans l'application mobile. Le PC Principal est la source de référence.**

## Titre de l'application

Le mobile accepte, par ordre de priorité : `schoolTitle`, `principalTitle`, `appTitle`, `establishmentTitle`, puis `schoolName`. L'extension de référentiel peut aussi fournir `schoolTitle` sans changer la structure historique de `/api/v1/sync`.

## Événements utilisés par la V0.3

- `attendance` : `date`, absence/retard, `justified`, heure d'arrivée pour le retard, remarque facultative ;
- `quranValidation` : Sourate + numéro + nom arabe, versets de/à, Hizb/Juz + numéros/noms arabes, mode mémorisation/révision/validation ;
- `lessonFollowUp` : matière, `lessonId`, leçon, état et observation ;
- `communication` avec `kind=incident` : nature, priorité et description.

Chaque événement possède un `id` unique et un `deviceId`. Il reste d'abord dans la file locale puis est retiré uniquement après accusé du Principal.

## Compatibilité fonctionnelle à prévoir côté Principal

Le binaire V1.6.7 contient `SchoolLessonFollowUp`, mais le poste Prof V1.6.7 n'expose pas encore explicitement une catégorie réseau `lessonFollowUp`. L'intégration finale côté Principal doit accepter cette catégorie et la convertir vers son objet `SchoolLessonFollowUp`.

L'endpoint `/api/v1/reference-data` est également une extension à ajouter au Principal pour que le mobile utilise les noms arabes, les leçons et les natures d'incident détenus par le PC au lieu d'entretenir sa propre liste.
