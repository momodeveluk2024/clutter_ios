package notifications

import (
	"context"
	"log/slog"
	"strings"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"github.com/google/uuid"
	"google.golang.org/api/option"
)

type PushMessage struct {
	UserID   uuid.UUID
	Title    string
	Body     string
	ImageURL *string
	Data     map[string]string
}

type PushRecipient struct {
	DeviceID uuid.UUID
	Token    string
	Platform string
}

type PushSender interface {
	Send(ctx context.Context, recipient PushRecipient, message PushMessage) error
}

type RecommendationPushContent struct {
	UserID       uuid.UUID
	NutrientName string
	FoodID       uuid.UUID
	FoodName     string
	FoodImageURL string
}

func BuildRecommendationPushMessage(content RecommendationPushContent) PushMessage {
	data := map[string]string{
		"type":    "recommendation",
		"food_id": content.FoodID.String(),
		"route":   "/app/food/" + content.FoodID.String(),
	}
	if content.FoodImageURL != "" {
		data["image_url"] = content.FoodImageURL
	}

	var imageURL *string
	if strings.TrimSpace(content.FoodImageURL) != "" {
		value := strings.TrimSpace(content.FoodImageURL)
		imageURL = &value
	}

	return PushMessage{
		UserID:   content.UserID,
		Title:    "Try " + content.FoodName + " today",
		Body:     "You are below target for " + content.NutrientName + ". " + content.FoodName + " can help close the gap.",
		ImageURL: imageURL,
		Data:     data,
	}
}

func BuildWeeklySummaryPushMessage(userID uuid.UUID) PushMessage {
	return PushMessage{
		UserID: userID,
		Title:  "Your weekly nutrient report is ready",
		Body:   "See how well you covered your nutrient goals this week.",
		Data: map[string]string{
			"type":  "weekly_summary",
			"route": "/app?tab=track",
		},
	}
}

func BuildAIInsightPushMessage(userID uuid.UUID) PushMessage {
	return PushMessage{
		UserID: userID,
		Title:  "Try AI meal photo analysis",
		Body:   "Snap your meal and let Nutrimate estimate nutrients from the photo.",
		Data: map[string]string{
			"type":  "ai_insight",
			"route": "/app/ai/chat",
		},
	}
}

type DevLoggerSender struct {
	logger *slog.Logger
}

func NewDevLoggerSender(logger *slog.Logger) *DevLoggerSender {
	return &DevLoggerSender{logger: logger}
}

func (s *DevLoggerSender) Send(ctx context.Context, recipient PushRecipient, message PushMessage) error {
	s.logger.InfoContext(ctx, "dev push notification", "user_id", message.UserID, "device_id", recipient.DeviceID, "platform", recipient.Platform, "title", message.Title, "body", message.Body, "image_url", message.ImageURL, "data", message.Data)
	return nil
}

type FCMSender struct {
	client *messaging.Client
}

func NewFCMSender(ctx context.Context, credentialsFile string) (*FCMSender, error) {
	app, err := firebase.NewApp(ctx, nil, option.WithCredentialsFile(credentialsFile))
	if err != nil {
		return nil, err
	}
	client, err := app.Messaging(ctx)
	if err != nil {
		return nil, err
	}
	return &FCMSender{client: client}, nil
}

func (s *FCMSender) Send(ctx context.Context, recipient PushRecipient, message PushMessage) error {
	fcm := &messaging.Message{
		Token: recipient.Token,
		Data:  message.Data,
		Notification: &messaging.Notification{
			Title: message.Title,
			Body:  message.Body,
		},
	}
	if message.ImageURL != nil {
		fcm.Notification.ImageURL = *message.ImageURL
		fcm.Android = &messaging.AndroidConfig{
			Notification: &messaging.AndroidNotification{
				ImageURL: *message.ImageURL,
			},
		}
	}
	_, err := s.client.Send(ctx, fcm)
	return err
}
