package jobs

import (
	"context"
	"log/slog"
	"time"

	"github.com/google/uuid"
)

type ReminderJob struct {
	ID       uuid.UUID
	UserID   uuid.UUID
	Title    string
	Body     string
	RemindAt time.Time
	Timezone string
}

type ReminderScheduler interface {
	Start(ctx context.Context) error
	Schedule(ctx context.Context, job ReminderJob) error
	Cancel(ctx context.Context, reminderID uuid.UUID) error
}

type NoopReminderScheduler struct {
	logger *slog.Logger
}

func NewNoopReminderScheduler(logger *slog.Logger) *NoopReminderScheduler {
	return &NoopReminderScheduler{logger: logger}
}

func (s *NoopReminderScheduler) Start(ctx context.Context) error {
	s.logger.InfoContext(ctx, "local reminder scheduler started in no-op mode")
	return nil
}

func (s *NoopReminderScheduler) Schedule(ctx context.Context, job ReminderJob) error {
	s.logger.InfoContext(ctx, "local reminder scheduled", "reminder_id", job.ID, "user_id", job.UserID, "remind_at", job.RemindAt)
	return nil
}

func (s *NoopReminderScheduler) Cancel(ctx context.Context, reminderID uuid.UUID) error {
	s.logger.InfoContext(ctx, "local reminder cancelled", "reminder_id", reminderID)
	return nil
}
