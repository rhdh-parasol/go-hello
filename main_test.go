package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHealthHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	w := httptest.NewRecorder()

	healthHandler(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", w.Code)
	}

	var resp HealthResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if resp.Status != "ok" {
		t.Errorf("expected status 'ok', got %q", resp.Status)
	}

	if resp.Version == "" {
		t.Error("expected non-empty version")
	}
}

func TestGreetHandler_DefaultName(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/greet", nil)
	w := httptest.NewRecorder()

	greetHandler(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", w.Code)
	}

	var resp GreetResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if resp.Message != "Hello, World!" {
		t.Errorf("expected 'Hello, World!', got %q", resp.Message)
	}
}

func TestGreetHandler_CustomName(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/greet?name=Fullsend", nil)
	w := httptest.NewRecorder()

	greetHandler(w, req)

	var resp GreetResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if resp.Message != "Hello, Fullsend!" {
		t.Errorf("expected 'Hello, Fullsend!', got %q", resp.Message)
	}

	if resp.Name != "Fullsend" {
		t.Errorf("expected name 'Fullsend', got %q", resp.Name)
	}
}
