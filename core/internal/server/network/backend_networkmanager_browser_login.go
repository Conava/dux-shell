package network

import (
	"context"
	"errors"
	"fmt"
	"slices"
	"time"

	"github.com/duxlabs-dev/dux-shell/core/internal/errdefs"
	"github.com/duxlabs-dev/dux-shell/core/internal/log"
	"github.com/godbus/dbus/v5"
)

var errVPNBrowserLoginCancelled = fmt.Errorf("%w: browser login replaced or cancelled", errVPNLoginCancelled)

// A cancelled login can need up to 5 s to shut down its redirect server; one
// that never lets go must not block the next login forever.
const browserLoginReleaseTimeout = 10 * time.Second

// browserLoginOwner identifies who started a browser login. FromAgent marks
// logins the secret agent started.
type browserLoginOwner struct {
	UUID           string
	Name           string
	ConnectionPath dbus.ObjectPath
	FromAgent      bool
}

type browserLogin struct {
	owner  browserLoginOwner
	cancel context.CancelCauseFunc
	done   chan struct{}
}

// vpnConnectCancelled reports whether a connect attempt ended because the user
// or a newer attempt cancelled it, which is not a connection failure.
func vpnConnectCancelled(err error) bool {
	return errors.Is(err, errVPNLoginCancelled) || errors.Is(err, errVPNAuthDialogCancelled) ||
		errors.Is(err, errdefs.ErrSecretPromptCancelled)
}

// runBrowserLogin runs login as the only browser login. It cancels the login
// it replaces and waits for it to release its redirect port or helper process
// before starting.
func (b *NetworkManagerBackend) runBrowserLogin(
	ctx context.Context,
	owner browserLoginOwner,
	login func(context.Context) (*openConnectAuthResult, error),
) (*openConnectAuthResult, error) {
	loginCtx, cancel := context.WithCancelCause(ctx)
	defer cancel(nil)
	current := &browserLogin{owner: owner, cancel: cancel, done: make(chan struct{})}

	b.browserLoginMu.Lock()
	previous := b.lastBrowserLogin
	b.browserLogin = current
	b.lastBrowserLogin = current
	b.setBrowserLoginUUID(owner.UUID)
	b.browserLoginMu.Unlock()
	if b.onStateChange != nil {
		b.onStateChange()
	}

	// A login cancelled while it waits signals done only once the login it
	// replaced has released, or the next one could bind too early.
	released := make(chan struct{})
	if previous == nil {
		close(released)
	} else {
		previous.cancel(errVPNBrowserLoginCancelled)
		go func() {
			timer := time.NewTimer(browserLoginReleaseTimeout)
			defer timer.Stop()
			select {
			case <-previous.done:
			case <-timer.C:
				log.Warnf("[VPN] Previous browser login for %s did not stop in time, starting the new one anyway", previous.owner.UUID)
			}
			close(released)
		}()
	}

	defer func() {
		b.browserLoginMu.Lock()
		owned := b.browserLogin == current
		if owned {
			b.browserLogin = nil
			b.setBrowserLoginUUID("")
		}
		b.browserLoginMu.Unlock()
		if owned && b.onStateChange != nil {
			b.onStateChange()
		}
		go func() {
			<-released
			close(current.done)
		}()
	}()

	select {
	case <-released:
	case <-loginCtx.Done():
	}
	if err := context.Cause(loginCtx); err != nil {
		return nil, err
	}
	result, err := login(loginCtx)
	if errors.Is(context.Cause(loginCtx), errVPNBrowserLoginCancelled) {
		return nil, errVPNBrowserLoginCancelled
	}
	// A save is queued only here, so a login cancelled right after it
	// succeeded can't leave one for a later activation.
	if err == nil && result != nil && result.pendingSave != nil {
		b.pendingVPNSaveMu.Lock()
		b.pendingVPNSave = result.pendingSave
		b.pendingVPNSaveMu.Unlock()
	}
	return result, err
}

// cancelBrowserLogin cancels the current browser login if match accepts its
// owner, without waiting for it to end, and returns that owner. A disconnect
// drops the connecting state first so the ending activation isn't reported as
// a failure.
func (b *NetworkManagerBackend) cancelBrowserLogin(match func(browserLoginOwner) bool, disconnect bool) *browserLoginOwner {
	b.browserLoginMu.Lock()
	login := b.browserLogin
	b.browserLoginMu.Unlock()
	if login == nil || !match(login.owner) {
		return nil
	}
	if disconnect {
		b.stopConnectingVPN(login.owner.UUID)
	}
	log.Infof("[VPN] Cancelling the browser login for %s", login.owner.UUID)
	login.cancel(errVPNBrowserLoginCancelled)
	return &login.owner
}

// cancelBrowserLoginFor cancels the browser login of the VPN uuidOrName refers to.
func (b *NetworkManagerBackend) cancelBrowserLoginFor(uuidOrName string) *browserLoginOwner {
	if uuidOrName == "" {
		return nil
	}
	return b.cancelBrowserLogin(func(o browserLoginOwner) bool {
		// Names aren't unique, so a name that is another profile's UUID means that profile.
		return o.UUID == uuidOrName || (o.Name == uuidOrName && !b.isVPNProfileUUID(uuidOrName))
	}, true)
}

func (b *NetworkManagerBackend) setBrowserLoginUUID(uuid string) {
	b.stateMutex.Lock()
	b.state.VPNBrowserLoginUuid = uuid
	b.stateMutex.Unlock()
}

func (b *NetworkManagerBackend) isVPNProfileUUID(uuid string) bool {
	b.stateMutex.RLock()
	defer b.stateMutex.RUnlock()
	return slices.ContainsFunc(b.state.VPNProfiles, func(p VPNProfile) bool { return p.UUID == uuid })
}
