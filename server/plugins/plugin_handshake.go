package main

import (
	"fmt"
	"log"
)

/*
	Example:
	Hello
*/

func CommandHandlerFunction(payload string) (string, error) {

	log.Printf("HELLO: answering with Hi.\n")
	fmt.Printf("HELLO: answering with Hi.\n")

	response := "Hi"

	return response, nil
}
