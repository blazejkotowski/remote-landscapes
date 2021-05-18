var requirementsPath, require;

requirementsPath = thisProcess.nowExecutingPath.dirname ++ "/scd/";
require = { |path| (requirementsPath ++ path).load; };
require.value('synthDefs.scd');


s.waitForBoot({
	var samplesPath, samplePath, spinupSynths, loadSamples, spinupEffects, setupBuses, mapParameters;

	require.value('osc.scd');

	samplesPath = thisProcess.nowExecutingPath.dirname ++ "/samples/";
	~loadSample = { |sample| Buffer.readChannel(s, samplesPath ++ sample, channels: [0]); };

	Pdef.removeAll;


	~getParamMapping = {
		|param, method|

		var methodBus, paramBus;

		methodBus = Bus.control(s, 1);
		paramBus = ~getParamBus.value(param);
		{ Out.kr(methodBus, method.value(paramBus.kr)); }.play;
		methodBus;
	};

	~getMapping = {
		|method|

		var methodBus;

		methodBus = Bus.control(s, 1);
		{ Out.kr(methodBus, method.value); }.play;
		methodBus;
	};


	loadSamples = {
		~samples = Dictionary.newFrom([
			\insects, ~loadSample.value('moving-ladder-chain.wav'),
			\rain, ~loadSample.value('rain-moderate.wav'),
			\breath, ~loadSample.value('dont-remember-what-but-pleasant-asmr.wav'),
			\birds1, ~loadSample.value('parrots1.wav'),
			\birds2, ~loadSample.value('parrots2.aiff'),
			\birds3, ~loadSample.value('parrots3.wav'),
			\snow, ~loadSample.value('walking-on-snow.wav'),
			\branches, ~loadSample.value('branches1.wav')
		]);
	};
	loadSamples.value;

	setupBuses = {
		~reverbBus = Bus.audio(s, 1);
		~delayBus = Bus.audio(s, 1);
		~granularBus = Bus.audio(s, 1);
		~outBus = Bus.audio(s, 1)
	};
	setupBuses.value;

	spinupEffects = {

	};
	spinupEffects.value;

	spinupSynths = {
		~air = Synth(\air, [\out, ~outBus]);
		~water = Synth(\water, [\out, ~outBus]);
		// ~fire = Synth(\fire, [\out, ~outBus, \amp, 0.05, \dur, 300]);
		~insects = Synth(\life, [\out, ~outBus, \buffer, ~samples.at(\insects), \dur, 1, \rate, 10, \pitch, 5]);
		~rain = Synth(\life, [\out, ~outBus, \buffer, ~samples.at(\rain), \dur, 10, \rate, 2, \pitch, 1]);

		~breath = Synth(\life, [\out, ~outBus, \buffer, ~samples.at(\breath), \dur, 5]);
		~snow = Synth(\life, [\out, ~outBus, \buffer, ~samples.at(\snow), \dur, 5, \rate, 0.2, \amp, 0.3]);
		~birds = Synth(\life, [\out, ~outBus, \buffer, ~samples.at(\birds1), \dur, 0.5, \rate, 1]);
		~crickets = Synth(\life, [\out, ~outBus, \buffer, ~samples.at(\cirickets), \dur, 0.5, \rate, 1/9]);
		~branches = Synth(\life, [\out, ~outBus, \buffer, ~samples.at(\branches), \dur, 0.1, \rate, 10]);

		~reverb = Synth(\schroederReverb, [\in, ~reverbBus, \out, 0, \reverbGain, 1], addAction: 'addToTail');
		~masterOut = Synth(\masterOut, [\masterBus, ~outBus], addAction: 'addToTail');
	};
	spinupSynths.value;

	mapParameters = {
/*		~fire.map(\freq, ~getParamMapping.value(\temperature, { |val| val.range(100, 1600); }));
		~fire.map(\amp, ~getMapping.value({
			var temperature, visibility;
			temperature = ~getParamBus.value(\temperature).kr;
			visibility = ~getParamBus.value(\visibility).kr;

			(temperature+visibility-0.5).clip(0, 0.01);
		}));*/

		~air.map(\wind, ~getParamMapping.value(\wind_speed, { |val| val*val * 60 } ));
		~air.map(\chaosRate, ~getParamMapping.value(\wind_deg, { |val| (val*360 / 180) + 0.1 } ));
		~air.map(\background, ~getMapping.value({
			var temperature, wind_deg, wind_speed;

			temperature = ~getParamBus.value(\temperature).kr;
			wind_deg = ~getParamBus.value(\wind_deg).kr;
			wind_speed = ~getParamBus.value(\wind_speed).kr;

			(1-temperature-0.5).range(0, 0.5);
		}));
		~air.map(\windBaseFreq, ~getParamMapping.value(\clouds, { |clouds| clouds.range(200, 600) }));

		~water.map(\amp, ~getParamMapping.value(\humidity, { |humidity| humidity.range(0.5, 2) }));
		~water.map(\rate, ~getMapping.value({
			var pressure, temperature;

			pressure = ~getParamBus.value(\pressure).kr;
			temperature = ~getParamBus.value(\temperature).kr;

			(temperature*pressure).range(5, 25);
		}));

		~insects.map(\amp, ~getMapping.value({
			var visibility, temperature, pressure;

			visibility = ~getParamBus.value(\visibility).kr;
			temperature = ~getParamBus.value(\temperature).kr;
			pressure = ~getParamBus.value(\pressure).kr;

			((visibility*2) * (temperature*1.5-(1-pressure)).clip(0,1)).range(0, 0.2);
		}));
		~insects.map(\pitch, ~getMapping.value({
			var clouds, visibility, lowerBound, upperBound;

			clouds = ~getParamBus.value(\clouds).kr;
			visibility = ~getParamBus.value(\visibility).kr;

			lowerBound = clouds*1.5;
			upperBound = clouds + visibility;

			LFNoise0.kr(0.5).range(lowerBound, upperBound);
		}));
		~insects.map(\rate, ~getParamMapping.value(\humidity, { |hum| hum.range(0.1, 10); }));


		~breath.map(\amp, ~getParamMapping.value(\pressure, { |pressure| pressure }));

		~snow.map(\amp, ~getParamMapping.value(\snow, { |snow| snow }));

		~birds.map(\amp, ~getMapping.value({
			var temperature, clouds, wind;

			temperature = ~getParamBus.value(\temperature).kr;
			clouds = ~getParamBus.value(\clouds).kr;
			wind = ~getParamBus.value(\wind_speed).kr;

			((temperature * (1-clouds).clip(0,1))*wind).range(0,0.2);
		}));
		~birds.map(\pitch, ~getParamMapping.value(\pressure, { |pressure| (pressure-1).range(0.05, 1) }));
		~birds.map(\rate, ~getParamMapping.value(\clouds, { |clouds| clouds.range(0.7, 2) }));

		~crickets.map(\amp, ~getMapping.value({
			var temperature, visibility, wind, humidity;

			temperature = ~getParamBus.value(\temperature).kr;
			humidity = ~getParamBus.value(\humidity).kr;
			wind = ~getParamBus.value(\wind_speed).kr;

			(((1-humidity)*temperature)/((wind+0.01)*10)).range(0, 0.2);
		}));
		~crickets.map(\rate, ~getParamMapping.value(\temperature, { |temp| temp.range(0.01, 1) }));
		~crickets.map(\dur, ~getParamMapping.value(\temperature, { |temp| temp.range(0.2, 3) }));
		~crickets.map(\pitch, ~getParamMapping.value(\pressure, { |pressure| pressure.range(0.3, 1) }));

		~branches.map(\amp, ~getParamMapping.value(\snow, { |snow| snow*5 }));
		~branches.map(\rate, ~getParamMapping.value(\wind_speed, { |wind| wind.range(0.1, 5) }));

		~rain.map(\amp, ~getParamMapping.value(\rain, { |rain| rain *2 }));

	};
	mapParameters.value;
});