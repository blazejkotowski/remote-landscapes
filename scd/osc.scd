/* Every 3 seconds receives a weather information in the format of the following array:
   [temperature, pressure, humidity, wind_speed, wind_deg, visibility, clouds, rain, snow] */

var weatherUpdateCallback, availableParams, oscListenerKey, oscEndpointPath;

availableParams = [\temperature, \pressure, \humidity, \wind_speed, \wind_deg, \visibility, \clouds, \rain, \snow];
~paramBuses = availableParams.inject(Dictionary.new(n=availableParams.size), {
	|dict, elem|

	dict.put(elem, Bus.control(s, 1))
});
~getParamBus = { |param| ~paramBuses.at(param); };


thisProcess.openUDPPort(55555);

oscListenerKey = \callback;
oscEndpointPath = '/weather';

weatherUpdateCallback = { |msg, time, addr, recvPort|
	availableParams.collect({
		|param, index|

		~getParamBus.value(param).set(msg.at(index+1));
	});
};

OSCdef(oscListenerKey).clear;
OSCdef(oscListenerKey, weatherUpdateCallback, oscEndpointPath);