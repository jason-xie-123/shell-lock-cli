package lockrunner

import (
	"bytes"
	"errors"
	"os"
	"path/filepath"
	"runtime"
	"testing"
	"time"

	"github.com/gofrs/flock"
)

func bashPathOrSkip(t *testing.T) string {
	t.Helper()
	if runtime.GOOS == "windows" {
		// Rely on default path; if absent, skip
		p := `C:\\Program Files\\Git\\bin\\bash.exe`
		if _, err := os.Stat(p); err != nil {
			t.Skip("Windows bash not available; skipping")
		}
		return p
	}
	p := "/bin/bash"
	if _, err := os.Stat(p); err != nil {
		t.Skip("/bin/bash not available; skipping")
	}
	return p
}

func TestRun_ValidationErrors(t *testing.T) {
	bp := bashPathOrSkip(t)
	lock := filepath.Join(t.TempDir(), "a.lock")

	if err := Run(Options{Command: "", LockFile: lock, BashPath: bp}); err == nil {
		t.Fatalf("expected error for missing command")
	}
	if err := Run(Options{Command: "echo ok", LockFile: "", BashPath: bp}); err == nil {
		t.Fatalf("expected error for missing lock-file")
	}
}

func TestRun_BashPathAutoDiscovery(t *testing.T) {
	bp := bashPathOrSkip(t)
	lock := filepath.Join(t.TempDir(), "auto.lock")
	// Ensure the directory containing bash is on PATH for discovery
	t.Setenv("PATH", filepath.Dir(bp)+string(os.PathListSeparator)+os.Getenv("PATH"))

	var out bytes.Buffer
	err := Run(Options{Command: "echo AUTO", LockFile: lock, BashPath: "", Stdout: &out})
	if err != nil {
		t.Fatalf("unexpected error during auto discovery: %v", err)
	}
	if !bytes.Contains(out.Bytes(), []byte("AUTO")) {
		t.Fatalf("expected AUTO output, got: %q", out.String())
	}
}

func TestRun_TryLock_NotAcquired_PrintsWarning(t *testing.T) {
	bp := bashPathOrSkip(t)
	dir := t.TempDir()
	lockPath := filepath.Join(dir, "lock")

	l := flock.New(lockPath)
	if err := l.Lock(); err != nil {
		t.Fatalf("pre-lock failed: %v", err)
	}
	t.Cleanup(func() { _ = l.Unlock() })

	var out, errBuf bytes.Buffer
	runErr := Run(Options{
		Command:  "echo should-not-run",
		LockFile: lockPath,
		TryLock:  true,
		BashPath: bp,
		Stdout:   &out,
		Stderr:   &errBuf,
	})
	if runErr != nil {
		t.Fatalf("expected nil error when try-lock not acquired, got %v", runErr)
	}
	if !bytes.Contains(out.Bytes(), []byte("[WARN] failed to acquire lock")) {
		t.Fatalf("expected warning on stdout, got: %q", out.String())
	}
}

func TestRun_TryLock_Acquired_Executes(t *testing.T) {
	bp := bashPathOrSkip(t)
	dir := t.TempDir()
	lockPath := filepath.Join(dir, "lock")

	var out, errBuf bytes.Buffer
	runErr := Run(Options{
		Command:  "echo OK",
		LockFile: lockPath,
		TryLock:  true,
		BashPath: bp,
		Stdout:   &out,
		Stderr:   &errBuf,
	})
	if runErr != nil {
		t.Fatalf("unexpected err: %v", runErr)
	}
	if !bytes.Contains(out.Bytes(), []byte("OK")) {
		t.Fatalf("expected output contains OK, got: %q", out.String())
	}

	// Lock should be released by defer in Run
	l2 := flock.New(lockPath)
	if ok, err := l2.TryLock(); err != nil {
		t.Fatalf("try lock after run failed: %v", err)
	} else if ok {
		_ = l2.Unlock()
	}
}

func TestRun_BlockingLock_ExecutesAfterRelease(t *testing.T) {
	bp := bashPathOrSkip(t)
	dir := t.TempDir()
	lockPath := filepath.Join(dir, "lock")

	l := flock.New(lockPath)
	if err := l.Lock(); err != nil {
		t.Fatalf("pre-lock failed: %v", err)
	}

	done := make(chan struct{})
	var out bytes.Buffer
	go func() {
		_ = Run(Options{
			Command:  "echo BLOCKED",
			LockFile: lockPath,
			TryLock:  false,
			BashPath: bp,
			Stdout:   &out,
		})
		close(done)
	}()

	time.Sleep(200 * time.Millisecond)
	_ = l.Unlock()

	select {
	case <-done:
		if !bytes.Contains(out.Bytes(), []byte("BLOCKED")) {
			t.Fatalf("expected output after release, got: %q", out.String())
		}
	case <-time.After(3 * time.Second):
		t.Fatal("timeout waiting for blocked execution")
	}
}

func TestRun_ExitCodePropagation(t *testing.T) {
	bp := bashPathOrSkip(t)
	lock := filepath.Join(t.TempDir(), "lock")

	err := Run(Options{
		Command:  "exit 7",
		LockFile: lock,
		BashPath: bp,
	})
	var ec ExitCodeError
	if !errors.As(err, &ec) {
		t.Fatalf("expected ExitCodeError, got %v", err)
	}
	if ec.Code != 7 {
		t.Fatalf("expected exit code 7, got %d", ec.Code)
	}
}

func TestRun_OutputRouting(t *testing.T) {
	bp := bashPathOrSkip(t)
	lock := filepath.Join(t.TempDir(), "lock")

	var out, errBuf bytes.Buffer
	err := Run(Options{
		Command:  "printf out; printf err 1>&2",
		LockFile: lock,
		BashPath: bp,
		Stdout:   &out,
		Stderr:   &errBuf,
	})
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if out.String() != "out" {
		t.Fatalf("unexpected stdout: %q", out.String())
	}
	if errBuf.String() != "err" {
		t.Fatalf("unexpected stderr: %q", errBuf.String())
	}
}

func TestRun_InvalidBashPath_Error(t *testing.T) {
	lock := filepath.Join(t.TempDir(), "lock")
	err := Run(Options{
		Command:  "echo x",
		LockFile: lock,
		BashPath: "/nonexistent/bash",
	})
	if err == nil {
		t.Fatalf("expected error for invalid bash path")
	}
}

func TestRun_LockPathError(t *testing.T) {
	dir := t.TempDir()
	noWrite := filepath.Join(dir, "ro")
	if err := os.Mkdir(noWrite, 0o555); err != nil {
		t.Fatalf("mkdir ro failed: %v", err)
	}
	lock := filepath.Join(noWrite, "cannot-create.lock")

	err := Run(Options{
		Command:  "echo x",
		LockFile: lock,
		BashPath: bashPathOrSkip(t),
	})
	if err == nil {
		t.Fatalf("expected error when lock file cannot be created")
	}
}
