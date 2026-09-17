package main

import (
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"time"
)

func main() {
	if len(os.Args) < 5 {
		fmt.Println("Usage: principal_probe.exe IP PORT PROFESSEUR CODE")
		fmt.Println("Exemple: principal_probe.exe 192.168.1.10 8080 PROF_TEST 123456")
		os.Exit(2)
	}
	host, port, teacher, code := os.Args[1], os.Args[2], os.Args[3], os.Args[4]
	client := &http.Client{Timeout: 8 * time.Second}
	base := "http://" + host + ":" + port
	for _, path := range []string{"/api/v1/ping", "/api/v1/sync?teacher=" + url.QueryEscape(teacher) + "&code=" + url.QueryEscape(code)} {
		fmt.Println("\n=== GET", path, "===")
		r, err := client.Get(base + path)
		if err != nil {
			fmt.Println("ERREUR:", err)
			continue
		}
		body, _ := io.ReadAll(r.Body)
		r.Body.Close()
		fmt.Println("HTTP", r.StatusCode)
		fmt.Println(string(body))
	}
	fmt.Println("\nAucune donnée n'a été envoyée au Principal. Test en lecture seule.")
}
