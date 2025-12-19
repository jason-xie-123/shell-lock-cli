package main

import (
	"errors"
	"fmt"
	"os"
	"runtime"

	"shell-lock-cli/internal/lockrunner"
	packageVersion "shell-lock-cli/version"

	"github.com/urfave/cli/v2"
)

const appName = "shell-lock-cli"

func main() {
	app := newApp()

	if err := app.Run(os.Args); err != nil {
		if exitErr, ok := err.(cli.ExitCoder); ok {
			os.Exit(exitErr.ExitCode())
		}

		fmt.Fprintf(os.Stderr, "[ERROR] %s\n", err.Error())
		os.Exit(1)
	}
}

func newApp() *cli.App {
	defaultBash := defaultBashPath()

	return &cli.App{
		Name:    appName,
		Usage:   "CLI tool to run shell-lock operations",
		Version: packageVersion.Version,
		Flags: []cli.Flag{
			&cli.StringFlag{
				Name:     "command",
				Usage:    "The shell command to execute",
				Required: true,
			},
			&cli.StringFlag{
				Name:     "lock-file",
				Usage:    "The mutex lock file",
				Required: true,
			},
			&cli.BoolFlag{
				Name:  "try-lock",
				Usage: "Try to acquire the lock without waiting",
			},
			&cli.StringFlag{
				Name:  "bash-path",
				Usage: "Path to bash executable (defaults to platform-specific path)",
				Value: defaultBash,
			},
		},
		Action: func(c *cli.Context) error {
			err := lockrunner.Run(lockrunner.Options{
				Command:  c.String("command"),
				LockFile: c.String("lock-file"),
				TryLock:  c.Bool("try-lock"),
				BashPath: c.String("bash-path"),
				Stdout:   os.Stdout,
				Stderr:   os.Stderr,
			})

			var exitErr lockrunner.ExitCodeError
			if errors.As(err, &exitErr) {
				return cli.Exit("", exitErr.Code)
			}

			return err
		},
	}
}

func defaultBashPath() string {
	if runtime.GOOS == "windows" {
		return "C:\\Program Files\\Git\\bin\\bash.exe"
	}

	return "/bin/bash"
}
