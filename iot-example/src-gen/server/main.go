package main

import (
	"fmt"
	"net/http"
	"strconv"
	"time"
	
	mqtt "github.com/eclipse/paho.mqtt.golang"
	"github.com/gorilla/mux"
)

type server struct {
	client mqtt.Client
	b1 *board_b1
	b2 *board_b2
}

func (s *server) send_message(topic string, payload interface{}) {
	token := s.client.Publish(topic, 0, false, payload)
	token.Wait()
}

func (s *server) loop0() {
	for _ = range time.Tick(1 * time.Minute) {
		light_level := int_average([]int64{s.b1.lightsensor.lightlevel, s.b2.lightsensor.lightlevel, })
		if light_level > 500 {
			s.b1.led.intensity = 0.0
			s.send_message("b1/led/intensity", fmt.Sprintf("%v", 0.0))
			s.b2.led.intensity = 0.0
			s.send_message("b2/led/intensity", fmt.Sprintf("%v", 0.0))
		} else if light_level > 250 {
			s.b1.led.intensity = 0.5
			s.send_message("b1/led/intensity", fmt.Sprintf("%v", 0.5))
			s.b2.led.intensity = 0.5
			s.send_message("b2/led/intensity", fmt.Sprintf("%v", 0.5))
		} else {
			s.b1.led.intensity = 1.0
			s.send_message("b1/led/intensity", fmt.Sprintf("%v", 1.0))
			s.b2.led.intensity = 1.0
			s.send_message("b2/led/intensity", fmt.Sprintf("%v", 1.0))
			s.b1.led.intensity = 0.5
			s.send_message("b1/led/intensity", fmt.Sprintf("%v", 0.5))
		}
	}
}

func (s *server) turn_on(w http.ResponseWriter, r *http.Request) {
	s.b1.led.status = "ON"
	s.send_message("b1/led/status", fmt.Sprintf("%v", "ON"))
	s.b2.led.status = "ON"
	s.send_message("b2/led/status", fmt.Sprintf("%v", "ON"))
}
func (s *server) turn_off(w http.ResponseWriter, r *http.Request) {
	s.b1.led.status = "OFF"
	s.send_message("b1/led/status", fmt.Sprintf("%v", "OFF"))
	s.b2.led.status = "OFF"
	s.send_message("b2/led/status", fmt.Sprintf("%v", "OFF"))
}

type board_b1 struct {
	lightsensor *pycom_lightsensor
	led *led
}
type board_b2 struct {
	thermometer *thermometer
	lightsensor *pycom_lightsensor
	led *led
}

type pycom_lightsensor struct {
	lightlevel int64
}
type led struct {
	intensity float64
	status string
}
type thermometer struct {
	temp float64
}

func main() {
	opts := mqtt.NewClientOptions()
	opts.AddBroker("mndkk.dk:1883")
	opts.SetClientID("server")
	opts.SetUsername("iot")
	opts.SetPassword("3Y5s6JrX")
	
	mqtt_client := mqtt.NewClient(opts)
	if token := mqtt_client.Connect(); token.Wait() && token.Error() != nil {
		panic(token.Error())
	}
	
	server := server{
		mqtt_client,
		&board_b1{&pycom_lightsensor{},&led{},},
		&board_b2{&thermometer{},&pycom_lightsensor{},&led{},},
	}
	
	mqtt_client.Subscribe("b1/lightsensor/lightlevel", 0, func(client mqtt.Client, msg mqtt.Message) {
		value, err := strconv.ParseInt(string(msg.Payload()), 10, 64)
		if err != nil {
			fmt.Println(fmt.Errorf("Error on topic %v: %v", msg.Topic(), err))
		} else {
			server.b1.lightsensor.lightlevel = value
		}
		
	})
	mqtt_client.Subscribe("b2/thermometer/temp", 0, func(client mqtt.Client, msg mqtt.Message) {
		value, err := strconv.ParseFloat(string(msg.Payload()), 64)
		if err != nil {
			fmt.Println(fmt.Errorf("Error on topic %v: %v", msg.Topic(), err))
		} else {
			server.b2.thermometer.temp = value
		}
		
	})
	mqtt_client.Subscribe("b2/lightsensor/lightlevel", 0, func(client mqtt.Client, msg mqtt.Message) {
		value, err := strconv.ParseInt(string(msg.Payload()), 10, 64)
		if err != nil {
			fmt.Println(fmt.Errorf("Error on topic %v: %v", msg.Topic(), err))
		} else {
			server.b2.lightsensor.lightlevel = value
		}
		
	})
	
	r := mux.NewRouter()
	r.HandleFunc("/turn_on", server.turn_on)
	r.HandleFunc("/turn_off", server.turn_off)
	
	go server.loop0()
	
	http.ListenAndServe(":12341412", r)
}

func float_average(xs []float64) float64 {
	total := float64(0)
	for _, x := range xs {
		total += x
	}
	return total / float64(len(xs))
}

func int_average(xs []int64) int64 {
	total := int64(0)
	for _, x := range xs {
		total += x
	}
	return total / int64(len(xs))
}
