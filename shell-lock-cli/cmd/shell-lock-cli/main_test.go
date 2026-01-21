package main

import (
	"bytes"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"shell-lock-cli/internal/lockrunner"

	"github.com/gofrs/flock"
	"github.com/urfave/cli/v2"
)

func withCapturedOutput(t *testing.T, fn func()) (string, string) {
	t.Helper()

	oldOut := os.Stdout
	oldErr := os.Stderr

	rOut, wOut, _ := os.Pipe()
	rErr, wErr, _ := os.Pipe()

	os.Stdout = wOut
	os.Stderr = wErr

	done := make(chan struct{})
	var outBuf, errBuf bytes.Buffer
	go func() {
		_, _ = io.Copy(&outBuf, rOut)
		close(done)
	}()
	var doneErr = make(chan struct{})
	go func() {
		_, _ = io.Copy(&errBuf, rErr)
		close(doneErr)
	}()

	fn()

	_ = wOut.Close()
	_ = wErr.Close()

	<-done
	<-doneErr

	os.Stdout = oldOut
	os.Stderr = oldErr

	return outBuf.String(), errBuf.String()
}

func bashPathForTests(t *testing.T) string {
	t.Helper()
	bp, err := lockrunner.FindBashPath("")
	if err != nil {
		t.Skipf("bash not available; skipping CLI exec tests: %v", err)
	}
	return bp
}

func TestCLI_RequiredFlags(t *testing.T) {
	app := newApp()
	// Missing --command
	err := app.Run([]string{"shell-lock-cli", "--lock-file", filepath.Join(t.TempDir(), "x.lock")})
	if err == nil {
		t.Fatalf("expected error for missing --command")
	}
	if !strings.Contains(strings.ToLower(err.Error()), "required") {
		t.Fatalf("expected required flag error, got: %v", err)
	}

	// Missing --lock-file
	err = app.Run([]string{"shell-lock-cli", "--command", "echo x"})
	if err == nil {
		t.Fatalf("expected error for missing --lock-file")
	}
	if !strings.Contains(strings.ToLower(err.Error()), "required") {
		t.Fatalf("expected required flag error, got: %v", err)
	}
}

func TestCLI_ExitCodePropagation(t *testing.T) {
	app := newApp()
	lock := filepath.Join(t.TempDir(), "x.lock")
	args := []string{"shell-lock-cli", "--command", "exit 9", "--lock-file", lock, "--bash-path", bashPathForTests(t)}
	orig := cli.OsExiter
	var got int = -1
	cli.OsExiter = func(code int) { got = code }
	defer func() { cli.OsExiter = orig }()

	_ = app.Run(args)
	if got != 9 {
		t.Fatalf("expected exit code 9 via OsExiter, got: %d", got)
	}
}

func TestCLI_TryLock_NotAcquired_PrintsWarning(t *testing.T) {
	app := newApp()
	dir := t.TempDir()
	lockPath := filepath.Join(dir, "x.lock")
	l := flock.New(lockPath)
	if err := l.Lock(); err != nil {
		t.Fatalf("pre-lock failed: %v", err)
	}
	t.Cleanup(func() { _ = l.Unlock() })

	args := []string{"shell-lock-cli", "--command", "echo hi", "--lock-file", lockPath, "--try-lock", "--bash-path", bashPathForTests(t)}
	out, _ := withCapturedOutput(t, func() {
		if err := app.Run(args); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
	})
	if !strings.Contains(out, "[WARN] failed to acquire lock") {
		t.Fatalf("expected warn output, got: %q", out)
	}
}

func TestCLI_Success_PrintsOutput(t *testing.T) {
	app := newApp()
	lock := filepath.Join(t.TempDir(), "x.lock")
	args := []string{"shell-lock-cli", "--command", "echo TOKEN", "--lock-file", lock, "--bash-path", bashPathForTests(t)}
	out, _ := withCapturedOutput(t, func() {
		if err := app.Run(args); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
	})
	if !strings.Contains(out, "TOKEN") {
		t.Fatalf("expected TOKEN in stdout, got: %q", out)
	}
}

func TestDefaultBashPath(t *testing.T) {
	resolved, err := lockrunner.FindBashPath("")
	if err != nil {
		t.Skipf("bash not available for default detection: %v", err)
	}
	if got := defaultBashPath(); got != resolved {
		t.Fatalf("default bash path mismatch, want %q got %q", resolved, got)
	}
}
