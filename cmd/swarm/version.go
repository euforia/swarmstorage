package main

import (
	"fmt"
	"github.com/euforia/swarmstorage/modules/swarm"
)

var cmdVersion = &Command{
	UsageLine: "version",
	Short:     "show version",
	Long: `
Show swarm version.
	`,
}

func init() {
	cmdVersion.Run = runVersion
}

func runVersion(cmd *Command, args []string) {
	fmt.Printf("swarm version %s\n", swarm.SWARM_VERSION)
}
