package lockrunner

import (
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"

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
	if opts.BashPath == "" {
		return errors.New("bash-path is required")
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

	cmd := exec.Command(opts.BashPath, "-c", opts.Command)
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
