package main

import (
	"fmt"
	packageVersion "shell-lock-cli/version"
)

func main() {
	fmt.Printf("%v\n", packageVersion.Version)
}
