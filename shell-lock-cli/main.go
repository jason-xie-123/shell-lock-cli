package main

import (
	"fmt"
	"os"
	"os/exec"
	"runtime"

	packageVersion "shell-lock-cli/version"

	"github.com/gofrs/flock"
	"github.com/urfave/cli/v2"
)

func main() {
	AppName := "shell-lock-cli"

	bashPath := ""
	if runtime.GOOS == "windows" {
		bashPath = "C:\\Program Files\\Git\\bin\\bash.exe"
	} else {
		bashPath = "/bin/bash"
	}

	app := &cli.App{
		Name:    AppName,
		Usage:   "CLI Tool to run shell-lock operations",
		Version: packageVersion.Version,
		Flags: []cli.Flag{
			&cli.StringFlag{
				Name:  "command",
				Usage: "The shell command to execute",
			},
			&cli.StringFlag{
				Name:  "lock-file",
				Usage: "The mutex lock file",
			},
			&cli.BoolFlag{
				Name:  "try-lock",
				Usage: "try to acquire the lock without waiting",
			},
			&cli.StringFlag{
				Name:        "bash-path",
				Usage:       "path to bash executable, the default is /bin/bash or C:\\Program Files\\Git\\bin\\bash.exe on Windows",
				DefaultText: bashPath,
			},
		},
		Action: func(c *cli.Context) error {
			command := c.String("command")
			lockFile := c.String("lock-file")
			tryLock := c.Bool("try-lock")
			bashPath := c.String("bash-path")

			if command == "" {
				return fmt.Errorf("command is required")
			}
			if lockFile == "" {
				return fmt.Errorf("lock-file is required")
			}

			var fileLock *flock.Flock
			var lockTrySuccess bool = false
			var err error
			if tryLock {
				fileLock = flock.New(lockFile)

				lockTrySuccess, err = fileLock.TryLock()
				if err != nil {
					fmt.Printf("Error while locking try lock %s: %+v\n", lockFile, err)
					os.Exit(2)
				}
			} else {
				fileLock = flock.New(lockFile)

				err = fileLock.Lock()
				if err != nil {
					fmt.Printf("Error while locking %s: %+v\n", lockFile, err)
					os.Exit(2)
				}
			}

			cmd := exec.Command(bashPath, "-c", command)
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr

			if err := cmd.Run(); err != nil {
				fmt.Println("Error while executing command: ", err)

				if (tryLock && lockTrySuccess) || !tryLock {
					if fileLock != nil {
						fileLock.Unlock()
					}
				}

				if cmd.ProcessState != nil {
					os.Exit(cmd.ProcessState.ExitCode())
				}

				os.Exit(3)
			}

			if (tryLock && lockTrySuccess) || !tryLock {
				if fileLock != nil {
					fileLock.Unlock()
				}
			}

			return nil
		},
	}

	err := app.Run(os.Args)
	if err != nil {
		fmt.Print(err.Error())
		os.Exit(1)
	}
}
