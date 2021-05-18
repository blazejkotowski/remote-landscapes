CITIES = ['linz']
CYCLES_PER_CITY = 30

POLLING_INTERVAL = 10
API_ID = 'yourApiKey'
BASE_URL = "http://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={api_id}&units=metric"
OSC_PORT = 55555

COORDINATES = {
  'linz': [48.3069, 14.2858],
}

from pythonosc import udp_client
client = udp_client.SimpleUDPClient('127.0.0.1', OSC_PORT)

import requests
import logging
import time
import json
import numpy as np


def api_url(latitude, longitude):
  return BASE_URL.format(lat=latitude, lon=longitude, api_id=API_ID)

def weather_for(location):
  try:
    url = api_url(*COORDINATES[location])
    res = requests.get(url)
    return res.json()
  except KeyError:
    logging.error("No location {} available.".format(location))

class ParameterMapping:
  def __init__(self, default, method, input_min=0, input_max=1, norm_function='lin'):
    self.method = method
    self.default = default
    self.input_min = input_min
    self.input_max = input_max
    self.norm_function = norm_function

  def fetch(self, weather):
    try:
      value = self.method(weather)
    except KeyError:
      value = self.default

    return self.__normalize(value)

  def __normalize(self, value):
    if self.norm_function == 'log':
      value = self.__log_normalize(value)
    else:
      value = self.__lin_normalize(value)
    if value < 0:
      return 0
    elif value > 1:
      return 1
    return value

  def __lin_normalize(self, value):
    return float(value-self.input_min)/float(self.input_max-self.input_min)

  def __log_normalize(self, value):
    return np.log(value-self.input_min+1)/np.log(self.input_max-self.input_min+1)

class CurrentWeather:
  def __resolve_pressure(weather):
    if 'main' in weather and 'grnd_level' in weather['main']:
      return weather['main']['grnd_level']
    elif 'main' in weather and 'sea_level' in weather['main']:
      return weather['main']['sea_level']
    return weather['main']['pressure']

  MAPPINGS = {
    'temperature': ParameterMapping(0, lambda w: w['main']['feels_like'], -20, 35),               # •C, min expected: -20C (extreme), max expected: 35C (extreme)
    'pressure': ParameterMapping(1013.25, __resolve_pressure, 870, 1085.7),                       # hPa, lowest ever: 870, highest ever: 1085.7
    'humidity': ParameterMapping(50, lambda w: w['main']['humidity'], 0, 100),                    # %, min: 0, max: 100
    'wind_speed': ParameterMapping(0, lambda w: w['wind']['speed'], 0, 35),                       # m/s, light_breeze: <= 3.5m/s, high wind: <= 15m/s, storm: <= 32.5 m/s, hurricane >= 32.5 m/s
    'wind_deg': ParameterMapping(0, lambda w: w['wind']['deg'], 0, 360),                          # • min: 0, max: 360
    'visibility': ParameterMapping(10000, lambda w: w['visibility'], 0, 296000, 'log'),           # m, very low < 100m, fog <= 1000m, mist <= 2000m, haze <= 5000m, max: 296000
    'clouds': ParameterMapping(0, lambda w: w['clouds']['all'], 0, 100),                          # %, min: 0, max: 100
    'rain': ParameterMapping(0, lambda w: w['rain']['1h'], 0, 60, 'log'),                         # mm / h, light rain: <= 2.5mm, moderate: <= 7.6, heavy: <= 50 mm, violent > 50mm
    'snow': ParameterMapping(0, lambda w: w['snow']['1h'], 0, 10, 'log'),                         # mm / h, light rain: <= 1mm, moderate <= 5mm, heavy > 5mm
  }

  def __init__(self, weather):
    self.weather = weather

  def values_list(self):
    return list(map(lambda m: m.fetch(self.weather), self.MAPPINGS.values()))

  def fetch(self, param):
    return self.MAPPINGS[param].fetch(self.weather)


def loop():
  city_index = 0
  cycles = 0
  while True:
    try:
      weather = CurrentWeather(weather_for(CITIES[city_index]))
      client.send_message('/weather', weather.values_list())
      cycles = (cycles+1) % CYCLES_PER_CITY
      if cycles == 0:
        city_index = (city_index+1) % len(CITIES)

    except requests.exceptions.ConnectionError:
      logging.error('Connection problem.')
    finally:
      time.sleep(POLLING_INTERVAL)

if __name__ == '__main__':
  loop()
