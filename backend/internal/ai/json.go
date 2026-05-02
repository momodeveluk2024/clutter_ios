package ai

import "encoding/json"

func jsonMarshalNoError(value any) (string, error) {
	payload, err := json.Marshal(value)
	if err != nil {
		return "", err
	}
	return string(payload), nil
}
