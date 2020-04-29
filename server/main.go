package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"net"
	"os"
	"os/signal"
	"strings"
	"syscall"
)

func handleConnection(connection net.Conn) {

	fmt.Printf("Serving %s\n", connection.RemoteAddr().String())

	for {

		data, err := bufio.NewReader(connection).ReadString('\n')
		if err != nil {
			if err == io.EOF {
				fmt.Printf("Client closed %s\n", connection.RemoteAddr().String())
			} else {
				fmt.Println("Error while reading from connection:", err)
			}

			return
		}

		fmt.Printf("[%s] %s\n", connection.RemoteAddr().String(), strings.TrimRight(data, "\n"))

		temp := strings.TrimSpace(string(data))
		if temp == "STOP" {
			break
		}
	}

	fmt.Printf("Closing %s\n", connection.RemoteAddr().String())
	connection.Close()
}

func handleSignal() {
	signalChannel := make(chan os.Signal)
	signal.Notify(signalChannel, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-signalChannel
		os.Exit(0)
	}()
}

func main() {

	var listenAddress strings.Builder

	addressPtr := flag.String("address", "127.0.0.1", "Address to listen")
	portPtr := flag.String("port", "28000", "Port to listen")

	flag.Parse()

	listenAddress.WriteString(*addressPtr)
	listenAddress.WriteString(":")
	listenAddress.WriteString(*portPtr)

	fmt.Println("Listening on", listenAddress.String())

	listening, err := net.Listen("tcp4", listenAddress.String())
	if err != nil {
		fmt.Println(err)
		return
	}
	defer listening.Close()

	for {
		accepted, err := listening.Accept()
		if err != nil {
			fmt.Println(err)
			return
		}
		go handleConnection(accepted)
	}
}
