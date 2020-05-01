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
	"structs"
	"syscall"
)

type CommandPluginStruct struct {
	Command  string `json:"command"`
	Filename string `json:"filename"`
}

type MessengerPluginStruct struct {
	Platform      string                                     `json:"platform"`
	Filename      string                                     `json:"filename"`
	Configuration structs.MessengerPluginConfigurationStruct `json:"configuration"`
}

type CommandPlugin struct {
	Command  string
	Filename string
	Symbol   plugin.Symbol
}

type ConfigurationStruct struct {
	CommandPlugins    []CommandPluginStruct `json:"handlers"`
	MessengerPlugin   MessengerPluginStruct `json:"messenger"`
	SupportedCommands map[string]CommandPlugin
	Messenger         plugin.Symbol
}

var Configuration = ConfigurationStruct{}

func handleConnection(connection net.Conn) {

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
		command := strings.TrimRight(data_parts[0], "\n")

		if handler, ok := Configuration.SupportedCommands[command]; ok {
			log.Print("Found handler for command ", command)

			response, err := handler.Symbol.(func(string) (string, error))(data)
			if err != nil {
				log.Print("Error while processing command: ", err)
				break
			}

			connection.Write([]byte(response))
			break

		} else {
			log.Printf("Warning: didn't find anything for command '%s'\n", command)
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

func ReadConfigurationFile(configPtr string, configuration *ConfigurationStruct) {

	configFile, _ := os.Open(configPtr)
	defer configFile.Close()

	JSONDecoder := json.NewDecoder(configFile)

	err := JSONDecoder.Decode(&configuration)
	if err != nil {
		log.Fatal("Error while reading config file: ", err)
	}

}

func SetupLogger(logfilePtr string) {
	logFile, err := os.OpenFile(logfilePtr, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal("Error while initialising logger: ", err)
	}

	defer logFile.Close()

	log.SetOutput(logFile)

}

func SetupMessenger(configuration *ConfigurationStruct) {

	messengerPluginSymbol, err := plugin.Open(configuration.MessengerPlugin.Filename)
	if err != nil {
		log.Fatal("Error while opening plugin file: ", err)
	}

	messengerSymbol, err := messengerPluginSymbol.Lookup("SendMessage")
	if err != nil {
		log.Fatal("Error while looking up a symbol: ", err)
	}

	messengerConfigurationSymbol, err := messengerPluginSymbol.Lookup("PluginConfiguration")
	if err != nil {
		log.Fatal("Error while looking up a symbol:", err)
	}

	configuration.Messenger = messengerSymbol.(func(string) (bool, error))
	*messengerConfigurationSymbol.(*structs.MessengerPluginConfigurationStruct) = configuration.MessengerPlugin.Configuration

}

func SetupCommandPlugins(configuration *ConfigurationStruct) {
	configuration.SupportedCommands = make(map[string]CommandPlugin)

	for item := range configuration.CommandPlugins {
		command := configuration.CommandPlugins[item].Command
		filename := configuration.CommandPlugins[item].Filename

		log.Printf("Supported command: '%s'\n", command)

		pluginHandler, err := plugin.Open(filename)
		if err != nil {
			log.Fatal("Error while opening plugin file:", err)
		}

		symbol, err := pluginHandler.Lookup("CommandHandlerFunction")
		if err != nil {
			log.Fatal("Error while looking up a symbol:", err)
		}

		configurationSymbol, err := pluginHandler.Lookup("PluginConfiguration")
		if err != nil {
			log.Fatal("Error while looking up a symbol:", err)
		}

		*configurationSymbol.(*structs.CommandPluginConfigurationStruct) = structs.CommandPluginConfigurationStruct{
			Messenger: configuration.Messenger,
		}

		configuration.SupportedCommands[command] = CommandPlugin{
			Command:  command,
			Filename: filename,
			Symbol:   symbol,
		}
	}

}

func main() {

	var listenAddress strings.Builder

	addressPtr := flag.String("address", "127.0.0.1", "Address to listen")
	portPtr := flag.String("port", "28000", "Port to listen")
	configPtr := flag.String("config", "server.conf", "Path to configuration file")
	logfilePtr := flag.String("logfile", "server.log", "Path to log file")

	flag.Parse()

	SetupLogger(*logfilePtr)
	ReadConfigurationFile(*configPtr, &Configuration)
	SetupMessenger(&Configuration)
	SetupCommandPlugins(&Configuration)

	listenAddress.WriteString(*addressPtr)
	listenAddress.WriteString(":")
	listenAddress.WriteString(*portPtr)

	log.Print("Listening on ", listenAddress.String())
	fmt.Println("Listening on", listenAddress.String())

	listening, err := net.Listen("tcp4", listenAddress.String())
	if err != nil {
		log.Fatal("Error while opening socket: ", err)
	}
	defer listening.Close()

	for {
		accepted, err := listening.Accept()
		if err != nil {
			log.Print("Error while accepting a connection: ", err)
			return
		}
		go handleConnection(accepted)
	}
}
