package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

func referenceData() map[string]any {
	return map[string]any{
		"surahs": []any{
			map[string]any{"number": 1, "name": "Al-Fatiha", "arabic": "الفاتحة", "verseCount": 7},
			map[string]any{"number": 2, "name": "Al-Baqara", "arabic": "البقرة", "verseCount": 286},
			map[string]any{"number": 112, "name": "Al-Ikhlas", "arabic": "الإخلاص", "verseCount": 4},
			map[string]any{"number": 113, "name": "Al-Falaq", "arabic": "الفلق", "verseCount": 5},
			map[string]any{"number": 114, "name": "An-Nas", "arabic": "الناس", "verseCount": 6},
		},
		"hizbs": []any{
			map[string]any{"number": 1, "arabic": "حِزْبُ ١", "name": "Hizb 1"},
			map[string]any{"number": 2, "arabic": "حِزْبُ ٢", "name": "Hizb 2"},
			map[string]any{"number": 60, "arabic": "حِزْبُ ٦٠", "name": "Hizb 60"},
		},
		"juzs": []any{
			map[string]any{"number": 1, "arabic": "جُزْءُ ١", "name": "Juz 1"},
			map[string]any{"number": 30, "arabic": "جُزْءُ عَمَّ", "name": "Juz 30"},
		},
		"lessons": []any{
			map[string]any{"id": "AR-01", "number": 1, "subject": "Arabe", "name": "Leçon 1"},
			map[string]any{"id": "AQ-03", "number": 3, "subject": "Aqida", "name": "Leçon 3"},
			map[string]any{"id": "FQ-02", "number": 2, "subject": "Fiqh", "name": "Leçon 2"},
			map[string]any{"id": "SR-04", "number": 4, "subject": "Sira", "name": "Leçon 4"},
			map[string]any{"id": "TJ-01", "number": 1, "subject": "Tajwid", "name": "Leçon 1"},
		},
		"incidentTypes": []string{"Discipline", "Comportement", "Matériel", "Travail / devoir", "Respect / langage", "Sécurité", "Autre"},
		"source":        "PC Principal — référentiel test",
	}
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/api/v1/ping", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprint(w, `{"ok":true,"protocolVersion":6}`)
	})
	mux.HandleFunc("/api/v1/sync", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]any{
			"protocolVersion": 6,
			"schoolName":      "CENTRE CMEO — TEST LOCAL",
			"schoolTitle":     "CENTRE CMEO — TEST LOCAL",
			"schoolYear":      "2026-2027",
			"teacher":         r.URL.Query().Get("teacher"),
			"classes": []any{
				map[string]any{"id": "CLS-A1", "name": "A1", "teacher": r.URL.Query().Get("teacher")},
			},
			"students": []any{
				map[string]any{"id": "E1", "studentId": "E1", "matricule": "A1-001", "name": "ELEVE_TEST_01", "firstName": "PRENOM_TEST_01", "classId": "CLS-A1", "gender": "F", "history": []any{map[string]any{"category": "attendance", "date": "2026-09-10", "title": "Absence", "details": "Absence justifiée"}, map[string]any{"category": "evaluation", "date": "2026-09-12", "title": "Évaluation Arabe", "details": "16/20"}}},
				map[string]any{"id": "E2", "studentId": "E2", "matricule": "A1-002", "name": "ELEVE_TEST_02", "firstName": "PRENOM_TEST_02", "classId": "CLS-A1", "gender": "F"},
			},
			"bulletinPeriods": []any{},
			"planning":        []any{},
			"generatedAt":     time.Now().Format(time.RFC3339),
		})
	})
	mux.HandleFunc("/api/v1/reference-data", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(referenceData())
	})
	mux.HandleFunc("/api/v1/events", func(w http.ResponseWriter, r *http.Request) {
		var body map[string]any
		_ = json.NewDecoder(r.Body).Decode(&body)
		ids := []string{}
		if list, ok := body["events"].([]any); ok {
			for _, raw := range list {
				if m, ok := raw.(map[string]any); ok {
					if id, ok := m["id"].(string); ok {
						ids = append(ids, id)
					}
				}
			}
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]any{"received": len(ids), "rejected": 0, "duplicates": 0, "acknowledgedIds": ids, "errors": []string{}})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "18080"
	}
	log.Printf("Mock Principal V6 + référentiel mobile : http://0.0.0.0:%s", port)
	log.Fatal(http.ListenAndServe(":"+port, mux))
}
