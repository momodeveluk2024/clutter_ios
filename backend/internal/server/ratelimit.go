package server

import (
	"net/http"
	"sync"
	"time"

	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/httpx"
)

type rateLimiter struct {
	mu      sync.Mutex
	limit   int
	window  time.Duration
	buckets map[string]*rateBucket
}

type rateBucket struct {
	count    int
	resetAt  time.Time
	lastSeen time.Time
}

func newRateLimiter(limit int, window time.Duration) *rateLimiter {
	return &rateLimiter{
		limit:   limit,
		window:  window,
		buckets: map[string]*rateBucket{},
	}
}

func (l *rateLimiter) middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		key := clientIP(r)
		now := time.Now()

		l.mu.Lock()
		bucket := l.buckets[key]
		if bucket == nil || now.After(bucket.resetAt) {
			bucket = &rateBucket{resetAt: now.Add(l.window)}
			l.buckets[key] = bucket
		}
		bucket.count++
		bucket.lastSeen = now
		allowed := bucket.count <= l.limit

		for key, bucket := range l.buckets {
			if now.Sub(bucket.lastSeen) > 5*l.window {
				delete(l.buckets, key)
			}
		}
		l.mu.Unlock()

		if !allowed {
			httpx.WriteError(w, http.StatusTooManyRequests, "too many requests")
			return
		}

		next.ServeHTTP(w, r)
	})
}
