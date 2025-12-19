package lockrunner

import (
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"runtime"

	"github.com/gofrs/flock"
)

// Options defines how the shell command should be executed with a lock.
type Options struct {
	Command  string
	LockFile string
	TryLock  bool
	BashPath string
	Stdout   io.Writer
	Stderr   io.Writer
}

// ExitCodeError carries the exit code of a failed command so callers can exit with the same code.
type ExitCodeError struct {
	Code int
	Err  error
}

func (e ExitCodeError) Error() string {
	return fmt.Sprintf("command exited with code %d: %v", e.Code, e.Err)
}

func (e ExitCodeError) Unwrap() error {
	return e.Err
}

// Run executes the provided command under a file lock.
func Run(opts Options) error {
	if opts.Command == "" {
		return errors.New("command is required")
	}
	if opts.LockFile == "" {
		return errors.New("lock-file is required")
	}

	bashPath, err := FindBashPath(opts.BashPath)
	if err != nil {
		return err
	}

	stdout := opts.Stdout
	stderr := opts.Stderr
	if stdout == nil {
		stdout = os.Stdout
	}
	if stderr == nil {
		stderr = os.Stderr
	}

	fileLock := flock.New(opts.LockFile)

	if opts.TryLock {
		acquired, err := fileLock.TryLock()
		if err != nil {
			return fmt.Errorf("failed to acquire lock: %w", err)
		}

		if !acquired {
			fmt.Fprintln(stdout, "[WARN] failed to acquire lock, another process is holding the lock...")
			return nil
		}

		defer fileLock.Unlock()
	} else {
		if err := fileLock.Lock(); err != nil {
			return fmt.Errorf("failed to acquire lock: %w", err)
		}

		defer fileLock.Unlock()
	}

	cmd := exec.Command(bashPath, "-c", opts.Command)
	cmd.Stdout = stdout
	cmd.Stderr = stderr

	if err := cmd.Run(); err != nil {
		if cmd.ProcessState != nil {
			return ExitCodeError{Code: cmd.ProcessState.ExitCode(), Err: err}
		}

		return fmt.Errorf("failed to run command: %w", err)
	}

	return nil
}

// FindBashPath resolves the path to a usable bash executable.
// If a path is provided, it is validated; otherwise common locations and PATH are searched.
func FindBashPath(provided string) (string, error) {
	if provided != "" {
		if isExecutableFile(provided) {
			return provided, nil
		}
		return "", fmt.Errorf("bash executable not found at %q", provided)
	}

	candidates := make([]string, 0, 5)
	if lp, err := exec.LookPath("bash"); err == nil {
		candidates = append(candidates, lp)
	}

	if runtime.GOOS == "windows" {
		candidates = append(candidates,
			`C:\\Program Files\\Git\\bin\\bash.exe`,
			`C:\\Program Files (x86)\\Git\\bin\\bash.exe`,
		)
	} else {
		candidates = append(candidates, "/bin/bash", "/usr/bin/bash")
	}

	seen := make(map[string]struct{}, len(candidates))
	for _, cand := range candidates {
		if cand == "" {
			continue
		}
		if _, dup := seen[cand]; dup {
			continue
		}
		seen[cand] = struct{}{}

		if isExecutableFile(cand) {
			return cand, nil
		}
	}

	return "", fmt.Errorf("bash executable not found; tried candidates: %v", candidates)
}

func isExecutableFile(path string) bool {
	info, err := os.Stat(path)
	if err != nil || info.IsDir() {
		return false
	}
	if runtime.GOOS == "windows" {
		return true
	}
	return info.Mode().Perm()&0o111 != 0
}
