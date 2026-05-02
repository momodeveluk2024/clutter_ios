package db

import (
	"reflect"
	"testing"
)

func TestAdminFoodContractsExposeEditableDatabaseFields(t *testing.T) {
	adminFood := reflect.TypeOf(AdminFood{})
	for _, field := range []string{"ImageURL", "Barcode", "Source", "Verified", "Nutrients"} {
		if _, ok := adminFood.FieldByName(field); !ok {
			t.Fatalf("AdminFood is missing %s", field)
		}
	}

	updateParams := reflect.TypeOf(UpdateAdminFoodParams{})
	for _, field := range []string{"ImageURL", "Barcode", "Source", "Verified", "Nutrients", "ReplaceNutrients"} {
		if _, ok := updateParams.FieldByName(field); !ok {
			t.Fatalf("UpdateAdminFoodParams is missing %s", field)
		}
	}
}

func TestAdminUserContractsExposeControlFields(t *testing.T) {
	adminUser := reflect.TypeOf(AdminUserSummary{})
	for _, field := range []string{"Status", "SuspendedAt", "DeletedAt"} {
		if _, ok := adminUser.FieldByName(field); !ok {
			t.Fatalf("AdminUserSummary is missing %s", field)
		}
	}
}

func TestAdminReminderTemplateContractExists(t *testing.T) {
	template := reflect.TypeOf(AdminReminderTemplate{})
	for _, field := range []string{"ID", "Title", "Body", "Trigger", "Audience", "Sent7d", "Active"} {
		if _, ok := template.FieldByName(field); !ok {
			t.Fatalf("AdminReminderTemplate is missing %s", field)
		}
	}
}
