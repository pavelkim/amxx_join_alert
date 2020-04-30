package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"os/signal"
	"plugin"
	"strings"
	"syscall"
)

type Handler struct {
	Command  string `json:command`
	Filename string `json:filename`
}

type CommandPlugin struct {
	Command  string
	Filename string
	Symbol   plugin.Symbol
}

type Configuration struct {
	Handlers          []Handler `json:handlers`
	SupportedCommands map[string]*CommandPlugin
}

func handleConnection(connection net.Conn, handlers map[string]*CommandPlugin) {

	log.Printf("Serving %s\n", connection.RemoteAddr().String())

	for {

		data, err := bufio.NewReader(connection).ReadString('\n')
		if err != nil {
			if err == io.EOF {
				log.Printf("Client closed %s\n", connection.RemoteAddr().String())
			} else {
				log.Print("Error while reading from connection: ", err)
			}

			return
		}

		log.Printf("[%s] %s\n", connection.RemoteAddr().String(), strings.TrimRight(data, "\n"))

		data_parts := strings.Split(data, "\t")
		command := data_parts[0]

		if handler, ok := handlers[command]; ok {
			log.Print("Found handler for command ", command)

			response, err := handler.Symbol.(func(string) (string, error))(data)
			if err != nil {
				log.Print("Error while processing command: ", err)
				break
			}
			connection.Write([]byte(response))
			break
		}
	}

	log.Printf("Closing %s\n", connection.RemoteAddr().String())
	connection.Close()
}

func handleSignal() {
	signalChannel := make(chan os.Signal)
	signal.Notify(signalChannel, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-signalChannel
		log.Print("SIGINT")
		os.Exit(0)
	}()
}

func main() {

	var listenAddress strings.Builder

	addressPtr := flag.String("address", "127.0.0.1", "Address to listen")
	portPtr := flag.String("port", "28000", "Port to listen")
	configPtr := flag.String("config", "server.conf", "Path to configuration file")
	logfilePtr := flag.String("logfile", "server.log", "Path to log file")

	flag.Parse()

	logFile, err := os.OpenFile(*logfilePtr, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal("Error while initialising logger:", err)
	}

	defer logFile.Close()

	log.SetOutput(logFile)

	configFile, _ := os.Open(*configPtr)
	defer configFile.Close()

	JSONDecoder := json.NewDecoder(configFile)

	configuration := Configuration{}
	err = JSONDecoder.Decode(&configuration)
	if err != nil {
		log.Fatal("Error while reading config file:", err)
	}

	for item := range configuration.Handlers {
		command := configuration.Handlers[item].Command
		filename := configuration.Handlers[item].Filename

		log.Printf("Supported command: '%s'\n", command)

		pluginHandler, err := plugin.Open(filename)
		if err != nil {
			log.Fatal("Error while opening plugin file:", err)
		}

		symbol, err := pluginHandler.Lookup("CommandHandlerFunction")
		if err != nil {
			log.Fatal("Error while looking up a symbol:", err)
		}

		configuration.SupportedCommands = make(map[string]*CommandPlugin)
		configuration.SupportedCommands[command] = &CommandPlugin{}

		configuration.SupportedCommands[command].Command = command
		configuration.SupportedCommands[command].Filename = filename
		configuration.SupportedCommands[command].Symbol = symbol

	}

	listenAddress.WriteString(*addressPtr)
	listenAddress.WriteString(":")
	listenAddress.WriteString(*portPtr)

	log.Print("Listening on ", listenAddress.String())

	listening, err := net.Listen("tcp4", listenAddress.String())
	if err != nil {
		log.Fatal("Error while opening socket:", err)
	}
	defer listening.Close()

	for {
		accepted, err := listening.Accept()
		if err != nil {
			log.Print("Error while accepting a connection: ", err)
			return
		}
		go handleConnection(accepted, configuration.SupportedCommands)
	}
}
