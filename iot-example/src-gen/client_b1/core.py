from mqtt import MQTTClient
import machine
from machine import Timer
import time

class Core:
	def __init__(self, lightsensor,led):
		self.lightsensor = lightsensor
		self.led = led
		self.client = MQTTClient("b1", "mndkk.dk", user="iot", password="3Y5s6JrX", port=1883)
		
	def sub_cb(self, topic, msg):
		topic_str = topic.decode("utf-8")
		msg_str = msg.decode("utf-8")
		if topic_str == "b1/led/intensity":
			self.led.intensity(msg_str)
		if topic_str == "b1/led/status":
			self.led.status(msg_str)
		
	def run(self):
		self.client.set_callback(self.sub_cb)
		self.client.connect()
		self.client.subscribe("b1/led/intensity")
		self.client.subscribe("b1/led/status")
		
		def _lightsensor_handler(self, alarm):
		   self.client.publish(topic="b1/lightsensor/lightlevel", msg=self.lightsensor.lightlevel())
		
		alarm = Timer.Alarm(handler=_lightsensor_handler, s=1, periodic=True)	
		try:
			while True:
				self.client.wait_msg()
				machine.idle()
		finally:
			alarm.cancel()
			self.client.disconnect()	
