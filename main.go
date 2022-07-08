package main

import (
	"encoding/json"
	"log"
	"net/http"
)

func index(w http.ResponseWriter, r *http.Request) {
	log.Println("incoming request for /")
	json.NewEncoder(w).Encode(map[string]string{"message": "success"})
}

func main() {
	http.HandleFunc("/", index)
	log.Println("listening on port 8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
