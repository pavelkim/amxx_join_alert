package main

import "fmt"

func CommandHandlerFunction(payload string) (string, error) {
	fmt.Printf("Enter: Got payload: %s\n", payload)
	return "OK", nil
}
