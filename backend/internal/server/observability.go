package server

import (
	"fmt"
	"net/http"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

type statusRecorder struct {
	http.ResponseWriter
	status int
	bytes  int
}

func (r *statusRecorder) WriteHeader(status int) {
	r.status = status
	r.ResponseWriter.WriteHeader(status)
}

func (r *statusRecorder) Write(body []byte) (int, error) {
	if r.status == 0 {
		r.status = http.StatusOK
	}
	written, err := r.ResponseWriter.Write(body)
	r.bytes += written
	return written, err
}

func (a *App) observeRequests(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		started := time.Now()
		recorder := &statusRecorder{ResponseWriter: w}
		next.ServeHTTP(recorder, r)
		if recorder.status == 0 {
			recorder.status = http.StatusOK
		}

		route := chi.RouteContext(r.Context()).RoutePattern()
		if route == "" {
			route = r.URL.Path
		}
		latency := time.Since(started)
		a.metrics.record(r.Method, route, recorder.status, latency)

		attrs := []any{
			"method", r.Method,
			"path", r.URL.Path,
			"route", route,
			"status", recorder.status,
			"latency_ms", latency.Milliseconds(),
			"request_id", middleware.GetReqID(r.Context()),
		}
		if userID := a.userIDFromRequest(r); userID != "" {
			attrs = append(attrs, "user_id", userID)
		}
		a.logger.Info("http request", attrs...)
	})
}

func (a *App) userIDFromRequest(r *http.Request) string {
	header := r.Header.Get("Authorization")
	if !strings.HasPrefix(header, "Bearer ") {
		return ""
	}
	userID, _, err := a.tokenizer.ParseAccessToken(strings.TrimPrefix(header, "Bearer "))
	if err != nil {
		return ""
	}
	return userID.String()
}

type metrics struct {
	mu       sync.Mutex
	requests map[metricKey]requestMetric
}

type metricKey struct {
	Method string
	Route  string
	Status int
}

type requestMetric struct {
	Count      int64
	LatencySum float64
}

func newMetrics() *metrics {
	return &metrics{requests: map[metricKey]requestMetric{}}
}

func (m *metrics) record(method, route string, status int, latency time.Duration) {
	m.mu.Lock()
	defer m.mu.Unlock()
	key := metricKey{Method: method, Route: route, Status: status}
	value := m.requests[key]
	value.Count++
	value.LatencySum += latency.Seconds()
	m.requests[key] = value
}

func (m *metrics) writePrometheus(w http.ResponseWriter) {
	m.mu.Lock()
	defer m.mu.Unlock()

	w.Header().Set("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
	_, _ = fmt.Fprintln(w, "# HELP nutrivita_http_requests_total Total HTTP requests.")
	_, _ = fmt.Fprintln(w, "# TYPE nutrivita_http_requests_total counter")
	keys := make([]metricKey, 0, len(m.requests))
	for key := range m.requests {
		keys = append(keys, key)
	}
	sort.Slice(keys, func(i, j int) bool {
		if keys[i].Route != keys[j].Route {
			return keys[i].Route < keys[j].Route
		}
		if keys[i].Method != keys[j].Method {
			return keys[i].Method < keys[j].Method
		}
		return keys[i].Status < keys[j].Status
	})
	for _, key := range keys {
		value := m.requests[key]
		labels := prometheusLabels(key)
		_, _ = fmt.Fprintf(w, "nutrivita_http_requests_total{%s} %d\n", labels, value.Count)
	}

	_, _ = fmt.Fprintln(w, "# HELP nutrivita_http_request_duration_seconds_sum Total request latency in seconds.")
	_, _ = fmt.Fprintln(w, "# TYPE nutrivita_http_request_duration_seconds_sum counter")
	for _, key := range keys {
		value := m.requests[key]
		_, _ = fmt.Fprintf(w, "nutrivita_http_request_duration_seconds_sum{%s} %.6f\n", prometheusLabels(key), value.LatencySum)
	}
}

func prometheusLabels(key metricKey) string {
	return strings.Join([]string{
		`method="` + escapePrometheusLabel(key.Method) + `"`,
		`route="` + escapePrometheusLabel(key.Route) + `"`,
		`status="` + strconv.Itoa(key.Status) + `"`,
	}, ",")
}

func escapePrometheusLabel(value string) string {
	value = strings.ReplaceAll(value, `\`, `\\`)
	value = strings.ReplaceAll(value, "\n", `\n`)
	value = strings.ReplaceAll(value, `"`, `\"`)
	return value
}
