package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"structs"
)

type SendMessageStruct struct {
	ChatID int    `json:"chat_id"`
	Text   string `json:"text"`
}

var PluginConfiguration structs.MessengerPluginConfigurationStruct

func SendMessage(message string) (bool, error) {

	var APIBaseURL = "https://api.telegram.org/bot" + PluginConfiguration.Token
	var SendMessageURL = APIBaseURL + "/sendMessage"

	sendMessagePackage := &SendMessageStruct{
		ChatID: PluginConfiguration.ChatID,
		Text:   message,
	}

	marshalledPackage, err := json.Marshal(sendMessagePackage)
	if err != nil {
		log.Fatal("Error while converting to JSON: ", err)
	}

	data := bytes.NewBuffer([]byte(marshalledPackage))

	request, err := http.NewRequest("POST", SendMessageURL, data)
	request.Header.Set("Content-Type", "application/json")

	client := &http.Client{}

	response, err := client.Do(request)
	if err != nil {
		log.Fatal("Error while making HTTP request: ", err)
	}

	defer response.Body.Close()

	log.Print("response Status: ", response.Status)
	fmt.Println("Telegram message: ", response.Status)
	log.Print("response Headers: ", response.Header)
	body, _ := ioutil.ReadAll(response.Body)
	log.Print("response Body: ", string(body))

	result := true
	return result, nil
}

func main() {
	ok, err := SendMessage("Hello")
	if err != nil && !ok {
		log.Fatal("Error while sending a message: ", err)
	}
}
