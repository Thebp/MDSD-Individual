from abc import ABC, abstractmethod
class pycom_lightsensor(ABC):

	def init_lightsensor(self):
		pass
	
	def lightlevel(self):
		pass
		
class led(ABC):

	def init_led(self):
		pass
	
	def intensity(self):
		pass
		
	def status(self):
		pass
		
