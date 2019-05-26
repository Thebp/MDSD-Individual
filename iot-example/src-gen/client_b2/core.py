from mqtt import MQTTClient
import machine
from machine import Timer
import time

class Core:
	def __init__(self, thermometer,lightsensor,led):
		self.thermometer = thermometer
		self.lightsensor = lightsensor
		self.led = led
		self.client = MQTTClient("b2", "mndkk.dk", user="iot", password="3Y5s6JrX", port=1883)
		
	def sub_cb(self, topic, msg):
		topic_str = topic.decode("utf-8")
		msg_str = msg.decode("utf-8")
		if topic_str == "b2/led/intensity":
			self.led.intensity(msg_str)
		if topic_str == "b2/led/status":
			self.led.status(msg_str)
		
	def run(self):
		self.client.set_callback(self.sub_cb)
		self.client.connect()
		self.client.subscribe("b2/led/intensity")
		self.client.subscribe("b2/led/status")
		
		def _thermometer_handler(self, alarm):
		   self.client.publish(topic="b2/thermometer/temp", msg=self.thermometer.temp())
		
		alarm = Timer.Alarm(handler=_thermometer_handler, s=3600, periodic=True)	
		def _lightsensor_handler(self, alarm):
		   self.client.publish(topic="b2/lightsensor/lightlevel", msg=self.lightsensor.lightlevel())
		
		alarm = Timer.Alarm(handler=_lightsensor_handler, s=1, periodic=True)	
		try:
			while True:
				self.client.wait_msg()
				machine.idle()
		finally:
			alarm.cancel()
			self.client.disconnect()	
