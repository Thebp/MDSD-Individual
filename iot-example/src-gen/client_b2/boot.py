from network import WLAN
import machine
import pycom
import time
wlan = WLAN(mode=WLAN.STA)

nets = wlan.scan()
for net in nets:
if net.ssid == 'MyOtherWifi':
    print('Network found!')
    wlan.connect(net.ssid, auth=(net.sec, '54321'), timeout=5000)
        while not wlan.isconnected():
            machine.idle() # save power while waiting
        print('WLAN connection succeeded!')
        pycom.heartbeat(False)
        pycom.rgbled(0x0000FF)
        time.sleep(5)
        pycom.rgbled(0x000000)
        machine.main("main.py")
        break

