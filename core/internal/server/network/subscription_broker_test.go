package network

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestPromptEndedWithoutShellReplyIsAnnouncedClosed(t *testing.T) {
	tests := []struct {
		name       string
		end        func(b PromptBroker, token string, cancel context.CancelFunc)
		wantClosed bool
	}{
		{"request context ends", func(_ PromptBroker, _ string, cancel context.CancelFunc) { cancel() }, true},
		{"NetworkManager cancels", func(b PromptBroker, _ string, _ context.CancelFunc) { _ = b.Cancel("/c/1", "vpn") }, true},
		{"shell cancels", func(b PromptBroker, token string, _ context.CancelFunc) {
			_ = b.Resolve(token, PromptReply{Cancel: true})
		}, false},
		{"shell submits", func(b PromptBroker, token string, _ context.CancelFunc) { _ = b.Resolve(token, PromptReply{}) }, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var sent []CredentialPrompt
			var closed []CredentialClosed
			broker := NewSubscriptionBroker(
				func(p CredentialPrompt) { sent = append(sent, p) },
				func(c CredentialClosed) { closed = append(closed, c) },
			)
			ctx, cancel := context.WithCancel(t.Context())
			defer cancel()
			token, err := broker.Ask(ctx, PromptRequest{ConnectionPath: "/c/1", SettingName: "vpn"})
			assert.NoError(t, err)

			tt.end(broker, token, cancel)
			_, _ = broker.Wait(ctx, token)

			assert.Equal(t, []CredentialPrompt{{Token: token, Setting: "vpn"}}, sent)
			if tt.wantClosed {
				assert.Equal(t, []CredentialClosed{{Token: token}}, closed)
			} else {
				assert.Empty(t, closed)
			}
		})
	}
}
