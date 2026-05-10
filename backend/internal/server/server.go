package server

import (
	"context"
	"errors"
	"log/slog"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"

	firebase "firebase.google.com/go/v4"
	firebaseauth "firebase.google.com/go/v4/auth"
	"google.golang.org/api/option"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/go-playground/validator/v10"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	aipkg "github.com/momodeveluk2024/nutrivita-flutter/backend/internal/ai"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/auth"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/config"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/db"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/filestore"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/httpx"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/jobs"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/notifications"
)

type App struct {
	cfg            config.Config
	store          *db.Store
	logger         *slog.Logger
	validate       *validator.Validate
	tokenizer      auth.TokenManager
	authLimit      *rateLimiter
	aiLimit        *rateLimiter
	lockouts       *loginLockouts
	scheduler      jobs.ReminderScheduler
	push           notifications.PushSender
	storage        filestore.ObjectStore
	metrics        *metrics
	ai             aipkg.Provider
	aiProviderName string
	now            func() time.Time
	firebaseAuth   *firebaseauth.Client
}

func New(cfg config.Config, store *db.Store, logger *slog.Logger) *App {
	push := notifications.PushSender(notifications.NewDevLoggerSender(logger))
	var fbAuth *firebaseauth.Client
	if strings.TrimSpace(cfg.FirebaseCredentialsFile) != "" {
		sender, err := notifications.NewFCMSender(context.Background(), cfg.FirebaseCredentialsFile)
		if err != nil {
			logger.Error("configure firebase cloud messaging", "error", err)
		} else {
			push = sender
		}

		opt := option.WithCredentialsFile(cfg.FirebaseCredentialsFile)
		fbApp, err := firebase.NewApp(context.Background(), nil, opt)
		if err != nil {
			logger.Error("configure firebase app", "error", err)
		} else {
			fbAuth, err = fbApp.Auth(context.Background())
			if err != nil {
				logger.Error("configure firebase auth", "error", err)
			}
		}
	}

	app := &App{
		cfg:            cfg,
		store:          store,
		logger:         logger,
		validate:       validator.New(validator.WithRequiredStructEnabled()),
		tokenizer:      auth.NewTokenManager(cfg.JWTSecret, cfg.AccessTokenTTL),
		authLimit:      newRateLimiter(10, time.Minute),
		aiLimit:        newRateLimiter(20, 24*time.Hour),
		lockouts:       newLoginLockouts(5, 15*time.Minute),
		scheduler:      jobs.NewNoopReminderScheduler(logger),
		push:           push,
		storage:        filestore.NewLocalStore("data/uploads", "/uploads"),
		metrics:        newMetrics(),
		aiProviderName: strings.TrimSpace(cfg.AIProvider),
		now:            time.Now,
		firebaseAuth:   fbAuth,
	}
	app.ai = buildAIProvider(cfg, logger)
	return app
}

func (a *App) Routes() http.Handler {
	r := chi.NewRouter()
	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(middleware.Recoverer)
	r.Use(a.observeRequests)
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   a.cfg.AllowedOrigins,
		AllowedMethods:   []string{"GET", "POST", "PATCH", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type"},
		AllowCredentials: false,
		MaxAge:           300,
	}))

	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		httpx.WriteJSON(w, http.StatusOK, map[string]string{"status": "ok"})
	})
	r.Get("/ready", func(w http.ResponseWriter, r *http.Request) {
		if err := a.store.Ping(r.Context()); err != nil {
			httpx.WriteError(w, http.StatusServiceUnavailable, "database unavailable")
			return
		}
		httpx.WriteJSON(w, http.StatusOK, map[string]string{"status": "ready"})
	})
	r.Get("/metrics", func(w http.ResponseWriter, r *http.Request) {
		a.metrics.writePrometheus(w)
	})
	r.Handle("/uploads/*", http.StripPrefix("/uploads/", http.FileServer(http.Dir("data/uploads"))))

	r.Route("/v1", func(r chi.Router) {
		r.Group(func(r chi.Router) {
			r.Use(a.authLimit.middleware)
		})
		r.Get("/foods", a.handleListFoods)
		r.Get("/foods/barcode/{barcode}", a.handleGetFoodByBarcode)
		r.Get("/foods/{foodID}", a.handleGetFood)
		r.Group(func(r chi.Router) {
			r.Use(a.requireAdmin)
			r.Get("/admin/me", a.handleAdminMe)
			r.Get("/admin/overview", a.handleAdminOverview)
			r.Get("/admin/users", a.handleAdminUsers)
			r.Get("/admin/users/{userID}", a.handleAdminUser)
			r.Patch("/admin/users/{userID}", a.handleAdminUpdateUserProfile)
			r.Post("/admin/users/{userID}/verify", a.handleAdminVerifyUser)
			r.Post("/admin/users/{userID}/suspend", a.handleAdminSuspendUser)
			r.Post("/admin/users/{userID}/unsuspend", a.handleAdminUnsuspendUser)
			r.Delete("/admin/users/{userID}", a.handleAdminDeleteUser)
			r.Delete("/admin/users/{userID}/sessions/{sessionID}", a.handleAdminRevokeUserSession)
			r.Get("/admin/logs", a.handleAdminLogs)
			r.Get("/admin/nutrients", a.handleAdminNutrients)
			r.Post("/admin/nutrients", a.handleAdminCreateNutrient)
			r.Patch("/admin/nutrients/{code}", a.handleAdminUpdateNutrient)
			r.Patch("/admin/nutrients/{code}/dri", a.handleAdminUpdateNutrientDRI)
			r.Get("/admin/foods", a.handleAdminFoods)
			r.Post("/admin/foods", a.handleAdminCreateFood)
			r.Patch("/admin/foods/{foodID}", a.handleAdminUpdateFood)
			r.Post("/admin/foods/{foodID}/image", a.handleAdminUploadFoodImage)
			r.Post("/admin/foods/{foodID}/verify", a.handleAdminVerifyFood)
			r.Delete("/admin/foods/{foodID}", a.handleAdminDeleteFood)
			r.Get("/admin/reminders", a.handleAdminReminders)
			r.Get("/admin/reminder-templates", a.handleAdminReminderTemplates)
			r.Post("/admin/reminder-templates", a.handleAdminCreateReminderTemplate)
			r.Patch("/admin/reminder-templates/{templateID}", a.handleAdminUpdateReminderTemplate)
			r.Get("/admin/ai/estimates", a.handleAdminAIEstimates)
			r.Get("/admin/ai/usage", a.handleAdminAIUsage)
			r.Patch("/admin/ai/estimates/{estimateID}/review", a.handleAdminReviewAIEstimate)
			r.Get("/admin/audit-log", a.handleAdminAuditLog)
		})
		r.Group(func(r chi.Router) {
			r.Use(a.requireAuth)
			r.Get("/me", a.handleMe)
			r.Patch("/me/profile", a.handleUpdateProfile)
			r.Post("/me/avatar", a.handleUpdateAvatar)
			r.Patch("/me/preferences", a.handleUpdatePreferences)
			r.Patch("/me/onboarding/complete", a.handleCompleteOnboarding)
			r.Get("/me/streak", a.handleStreak)
			r.Post("/foods", a.handleCreateFood)
			r.Get("/logs", a.handleListLogs)
			r.Post("/logs", a.handleCreateLog)
			r.Delete("/logs/{logID}", a.handleDeleteLog)
			r.Get("/logs/today/intake", a.handleTodayIntake)
			r.Get("/logs/week", a.handleWeekIntake)
			r.Get("/favorites", a.handleListFavorites)
			r.Put("/favorites/{foodID}", a.handleAddFavorite)
			r.Delete("/favorites/{foodID}", a.handleRemoveFavorite)
			r.Get("/reminders", a.handleListReminders)
			r.Post("/reminders", a.handleCreateReminder)
			r.Delete("/reminders/{reminderID}", a.handleDeleteReminder)
			r.Get("/recommendations/daily-plan", a.handleDailyMealPlan)
			r.Get("/recommendations", a.handleRecommendations)
			r.Post("/notifications/devices", a.handleRegisterPushDevice)
			r.Delete("/notifications/devices/{deviceID}", a.handleDisablePushDevice)
			r.Get("/notifications/preferences", a.handleGetNotificationPreferences)
			r.Patch("/notifications/preferences", a.handleUpdateNotificationPreferences)
			r.Group(func(r chi.Router) {
				r.Use(a.aiLimit.middleware)
				r.Post("/ai/meal-photo/analyze", a.handleAnalyzeMealPhoto)
				r.Patch("/ai/estimates/{estimateID}", a.handleUpdateAIEstimate)
				r.Post("/ai/estimates/{estimateID}/accept", a.handleAcceptAIEstimate)
				r.Post("/ai/chat", a.handleAIChat)
			})
		})
	})

	return r
}

func buildAIProvider(cfg config.Config, logger *slog.Logger) aipkg.Provider {
	if !cfg.AIEnabled {
		return nil
	}
	switch strings.ToLower(strings.TrimSpace(cfg.AIProvider)) {
	case "", "development", "mock", "local":
		return aipkg.NewDevelopmentProvider()
	case "gemini", "vertex", "vertex-gemini":
		provider, err := aipkg.NewGeminiProvider(context.Background(), aipkg.GeminiConfig{
			Project:  cfg.GoogleProject,
			Location: cfg.GoogleLocation,
			Model:    cfg.GeminiModelFast,
			Timeout:  45 * time.Second,
		})
		if err != nil {
			logger.Error("configure gemini provider", "error", err)
			return nil
		}
		return provider
	default:
		logger.Warn("unknown ai provider, using development provider", "provider", cfg.AIProvider)
		return aipkg.NewDevelopmentProvider()
	}
}

func (a *App) handleMe(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	if claims == nil {
		httpx.WriteError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	me, err := a.store.GetMe(r.Context(), claims.UserID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			httpx.WriteError(w, http.StatusNotFound, "user not found")
			return
		}
		a.logger.Error("get me", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not load profile")
		return
	}

	httpx.WriteJSON(w, http.StatusOK, me)
}

func (a *App) readAndValidate(w http.ResponseWriter, r *http.Request, target any) bool {
	if err := httpx.ReadJSON(r, target); err != nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid json")
		return false
	}
	if err := a.validate.Struct(target); err != nil {
		httpx.WriteError(w, http.StatusUnprocessableEntity, "invalid request")
		return false
	}
	return true
}

type authContextKey struct{}

type authContext struct {
	UserID    uuid.UUID
	SessionID uuid.UUID
}

func (a *App) requireAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		header := r.Header.Get("Authorization")
		if !strings.HasPrefix(header, "Bearer ") {
			httpx.WriteError(w, http.StatusUnauthorized, "unauthorized")
			return
		}

		if a.firebaseAuth == nil {
			httpx.WriteError(w, http.StatusInternalServerError, "firebase auth not configured")
			return
		}

		idToken := strings.TrimPrefix(header, "Bearer ")
		token, err := a.firebaseAuth.VerifyIDToken(r.Context(), idToken)
		if err != nil {
			httpx.WriteError(w, http.StatusUnauthorized, "unauthorized")
			return
		}

		user, err := a.ensureUserFromFirebase(r.Context(), token)
		if err != nil {
			a.logger.Error("ensure firebase user", "error", err)
			httpx.WriteError(w, http.StatusInternalServerError, "internal server error")
			return
		}

		ctx := context.WithValue(r.Context(), authContextKey{}, &authContext{
			UserID:    user.ID,
			SessionID: uuid.Nil,
		})
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func (a *App) ensureUserFromFirebase(ctx context.Context, token *firebaseauth.Token) (db.User, error) {
	// Try to find user by firebase UID
	user, err := a.store.GetUserByFirebaseUID(ctx, token.UID)
	if err == nil {
		return user, nil
	}

	if !errors.Is(err, pgx.ErrNoRows) {
		return db.User{}, err
	}

	email := ""
	if emailClaim, ok := token.Claims["email"].(string); ok {
		email = strings.ToLower(strings.TrimSpace(emailClaim))
	}
	emailVerified := false
	if ev, ok := token.Claims["email_verified"].(bool); ok {
		emailVerified = ev
	}

	var emailVerifiedAt *time.Time
	if emailVerified {
		now := a.now()
		emailVerifiedAt = &now
	}

	if email != "" {
		existing, err := a.store.GetUserByEmail(ctx, email)
		if err == nil {
			return a.store.LinkFirebaseUser(ctx, db.LinkFirebaseUserParams{
				ID:              existing.ID,
				FirebaseUID:     token.UID,
				EmailVerifiedAt: emailVerifiedAt,
			})
		}
	}

	userID, err := uuid.NewV7()
	if err != nil {
		return db.User{}, err
	}

	user, err = a.store.CreateFirebaseUser(ctx, db.CreateFirebaseUserParams{
		ID:              userID,
		Email:           email,
		FirebaseUID:     token.UID,
		EmailVerifiedAt: emailVerifiedAt,
	})
	if err != nil {
		return db.User{}, err
	}

	name := email
	if nameClaim, ok := token.Claims["name"].(string); ok && nameClaim != "" {
		name = nameClaim
	}
	_, err = a.store.CreateUserProfile(ctx, db.CreateUserProfileParams{
		UserID:      userID,
		DisplayName: name,
	})

	return user, err
}

func authFromContext(ctx context.Context) *authContext {
	claims, _ := ctx.Value(authContextKey{}).(*authContext)
	return claims
}

func clientIP(r *http.Request) string {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err == nil {
		return host
	}
	return r.RemoteAddr
}

func isUniqueViolation(err error) bool {
	return strings.Contains(err.Error(), "SQLSTATE 23505")
}

type loginLockouts struct {
	mu       sync.Mutex
	limit    int
	duration time.Duration
	attempts map[string]loginAttempt
}

type loginAttempt struct {
	count    int
	lockedAt time.Time
}

func newLoginLockouts(limit int, duration time.Duration) *loginLockouts {
	return &loginLockouts{limit: limit, duration: duration, attempts: map[string]loginAttempt{}}
}

func (l *loginLockouts) recordFailure(email string, now time.Time) {
	l.mu.Lock()
	defer l.mu.Unlock()
	attempt := l.attempts[email]
	attempt.count++
	if attempt.count >= l.limit && attempt.lockedAt.IsZero() {
		attempt.lockedAt = now
	}
	l.attempts[email] = attempt
}

func (l *loginLockouts) isLocked(email string, now time.Time) (time.Time, bool) {
	l.mu.Lock()
	defer l.mu.Unlock()
	attempt := l.attempts[email]
	if attempt.lockedAt.IsZero() {
		return time.Time{}, false
	}
	retryAt := attempt.lockedAt.Add(l.duration)
	if now.After(retryAt) {
		delete(l.attempts, email)
		return time.Time{}, false
	}
	return retryAt, true
}

func (l *loginLockouts) clear(email string) {
	l.mu.Lock()
	defer l.mu.Unlock()
	delete(l.attempts, email)
}
