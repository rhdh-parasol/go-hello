package main

import (
	"bytes"
	"encoding/json"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// --- Existing tests (preserved) ---

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

// --- POST /v1/greet tests ---

func TestV1GreetHandler_ValidName(t *testing.T) {
	body := `{"name":"Ada"}`
	req := httptest.NewRequest(http.MethodPost, "/v1/greet", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	v1GreetHandler(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", w.Code)
	}

	var resp GreetResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if resp.Message != "Hello, Ada!" {
		t.Errorf("expected 'Hello, Ada!', got %q", resp.Message)
	}
	if resp.Name != "Ada" {
		t.Errorf("expected name 'Ada', got %q", resp.Name)
	}
}

func TestV1GreetHandler_TrimmedName(t *testing.T) {
	body := `{"name":"  Ada  "}`
	req := httptest.NewRequest(http.MethodPost, "/v1/greet", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	v1GreetHandler(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", w.Code)
	}

	var resp GreetResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if resp.Name != "Ada" {
		t.Errorf("expected trimmed name 'Ada', got %q", resp.Name)
	}
}

func TestV1GreetHandler_EmptyName(t *testing.T) {
	body := `{"name":""}`
	req := httptest.NewRequest(http.MethodPost, "/v1/greet", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	v1GreetHandler(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected status 400, got %d", w.Code)
	}

	var resp ErrorResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("failed to decode error response: %v", err)
	}

	if resp.Error != "validation_error" {
		t.Errorf("expected error 'validation_error', got %q", resp.Error)
	}
	if resp.Message != "name is required" {
		t.Errorf("expected message 'name is required', got %q", resp.Message)
	}
}

func TestV1GreetHandler_WhitespaceOnlyName(t *testing.T) {
	body := `{"name":"   "}`
	req := httptest.NewRequest(http.MethodPost, "/v1/greet", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	v1GreetHandler(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected status 400, got %d", w.Code)
	}
}

func TestV1GreetHandler_NameTooLong(t *testing.T) {
	longName := strings.Repeat("A", 65)
	body := `{"name":"` + longName + `"}`
	req := httptest.NewRequest(http.MethodPost, "/v1/greet", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	v1GreetHandler(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected status 400, got %d", w.Code)
	}

	var resp ErrorResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("failed to decode error response: %v", err)
	}

	if resp.Message != "name must be between 1 and 64 characters" {
		t.Errorf("unexpected message: %q", resp.Message)
	}
}

func TestV1GreetHandler_MalformedJSON(t *testing.T) {
	body := `not-json`
	req := httptest.NewRequest(http.MethodPost, "/v1/greet", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	v1GreetHandler(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected status 400, got %d", w.Code)
	}

	var resp ErrorResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("failed to decode error response: %v", err)
	}

	if resp.Message != "invalid JSON body" {
		t.Errorf("expected message 'invalid JSON body', got %q", resp.Message)
	}
}

func TestV1GreetHandler_MissingBody(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/v1/greet", nil)
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	v1GreetHandler(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected status 400, got %d", w.Code)
	}
}

func TestV1GreetHandler_WrongContentType(t *testing.T) {
	body := `{"name":"Ada"}`
	req := httptest.NewRequest(http.MethodPost, "/v1/greet", strings.NewReader(body))
	req.Header.Set("Content-Type", "text/plain")
	w := httptest.NewRecorder()

	v1GreetHandler(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected status 400, got %d", w.Code)
	}

	var resp ErrorResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("failed to decode error response: %v", err)
	}

	if resp.Message != "Content-Type must be application/json" {
		t.Errorf("expected Content-Type error, got %q", resp.Message)
	}
}

func TestV1GreetHandler_NameExactly64Chars(t *testing.T) {
	name := strings.Repeat("A", 64)
	body := `{"name":"` + name + `"}`
	req := httptest.NewRequest(http.MethodPost, "/v1/greet", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	v1GreetHandler(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("expected status 200 for 64-char name, got %d", w.Code)
	}
}

// --- Liveness and readiness probe tests ---

func TestLiveHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/live", nil)
	w := httptest.NewRecorder()

	liveHandler(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", w.Code)
	}

	var resp map[string]string
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if resp["status"] != "ok" {
		t.Errorf("expected status 'ok', got %q", resp["status"])
	}
}

func TestReadyHandler_WhenReady(t *testing.T) {
	ready.Store(true)
	req := httptest.NewRequest(http.MethodGet, "/ready", nil)
	w := httptest.NewRecorder()

	readyHandler(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", w.Code)
	}

	var resp map[string]string
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if resp["status"] != "ok" {
		t.Errorf("expected status 'ok', got %q", resp["status"])
	}
}

func TestReadyHandler_WhenShuttingDown(t *testing.T) {
	ready.Store(false)
	defer ready.Store(true) // restore for other tests

	req := httptest.NewRequest(http.MethodGet, "/ready", nil)
	w := httptest.NewRecorder()

	readyHandler(w, req)

	if w.Code != http.StatusServiceUnavailable {
		t.Errorf("expected status 503, got %d", w.Code)
	}

	var resp map[string]string
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if resp["status"] != "shutting_down" {
		t.Errorf("expected status 'shutting_down', got %q", resp["status"])
	}
}

// --- Logging middleware tests ---

func TestLoggingMiddleware_RequestIDHeader(t *testing.T) {
	handler := loggingMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	// Redirect slog to discard for this test
	slog.SetDefault(slog.New(slog.NewJSONHandler(bytes.NewBuffer(nil), nil)))
	defer slog.SetDefault(slog.New(slog.NewJSONHandler(bytes.NewBuffer(nil), nil)))

	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	requestID := w.Header().Get("X-Request-ID")
	if requestID == "" {
		t.Fatal("expected X-Request-ID header to be set")
	}

	if len(requestID) != 32 {
		t.Errorf("expected 32-char hex request ID, got %d chars: %q", len(requestID), requestID)
	}
}

func TestLoggingMiddleware_LogShape(t *testing.T) {
	var logBuf bytes.Buffer
	logger := slog.New(slog.NewJSONHandler(&logBuf, nil))
	slog.SetDefault(logger)

	handler := loggingMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	// Parse log output
	var logEntry map[string]any
	if err := json.Unmarshal(logBuf.Bytes(), &logEntry); err != nil {
		t.Fatalf("log output is not valid JSON: %v\nOutput: %s", err, logBuf.String())
	}

	// Verify required fields
	requiredFields := []string{"time", "level", "msg", "method", "path", "status", "duration_ms", "request_id"}
	for _, field := range requiredFields {
		if _, ok := logEntry[field]; !ok {
			t.Errorf("missing required log field: %s", field)
		}
	}

	// Verify field values
	if logEntry["method"] != "GET" {
		t.Errorf("expected method 'GET', got %v", logEntry["method"])
	}
	if logEntry["path"] != "/health" {
		t.Errorf("expected path '/health', got %v", logEntry["path"])
	}

	// Verify request_id matches X-Request-ID header
	headerID := w.Header().Get("X-Request-ID")
	if logEntry["request_id"] != headerID {
		t.Errorf("request_id mismatch: header=%q log=%v", headerID, logEntry["request_id"])
	}
}

func TestLoggingMiddleware_CapturesStatusCode(t *testing.T) {
	var logBuf bytes.Buffer
	logger := slog.New(slog.NewJSONHandler(&logBuf, nil))
	slog.SetDefault(logger)

	handler := loggingMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNotFound)
	}))

	req := httptest.NewRequest(http.MethodGet, "/missing", nil)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	var logEntry map[string]any
	if err := json.Unmarshal(logBuf.Bytes(), &logEntry); err != nil {
		t.Fatalf("log output is not valid JSON: %v", err)
	}

	status, ok := logEntry["status"].(float64)
	if !ok || int(status) != 404 {
		t.Errorf("expected status 404 in log, got %v", logEntry["status"])
	}
}
