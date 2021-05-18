SynthDef(\schroederReverb, {
	arg in, out = 0, amp = 0.2;
	var input, predelay, earlyRef, lateRef, sig;

	// Mono - can't modulate numChannels so would need separate UGen for stereo
	input = In.ar(in, 1);

	// Adding predelay can help create a more realistic reverberance
	predelay = DelayN.ar(input, 0.048);

	// Early reflection comb filtering which 8 parallel comb filters
	// Mix adds all the signals together
	earlyRef = Mix.fill(7, {CombL.ar(predelay, 0.1, LFNoise1.kr(0.1.rand, 0.04, 0.05), 3)});

	// Create a series of 4 AllPass Filters for late reflections
	lateRef = earlyRef;
	4.do({lateRef = AllpassN.ar(lateRef, 0.050, [0.050.rand, 0.050.rand], 0.7)}); // Now Stereo

	sig = Mix.ar(lateRef);
	Out.ar(out, (amp * sig));
}).add;

SynthDef(\water, {
	|out=0, amp=1, rate=10|

	var sig;

	sig = Saw.ar(
		freq: 1,
		mul: LFPulse.kr(LFNoise0.kr(1).range(0.1, 10), width: 0.1)
	);
	sig = BPF.ar(sig, freq: LFNoise0.kr(rate).range(100, 2500), rq: 0.01, mul: amp);

	sig = Mix.ar(sig);
	Out.ar(out, sig);
}).add;

SynthDef(\air, {
	|out=0, background=0.1, wind=0, chaosRate=0.1, windBaseFreq=200|

	var bg, fg, sig, fgModulator;

	bg = WhiteNoise.ar;
	bg = LeakDC.ar(LeakDC.ar(LPF.ar(bg, 30) * 50).clip2(0.9)) * background;

	fg = WhiteNoise.ar(wind);
	fg = HPF.ar(fg, 60);
	fgModulator = LFNoise1.kr(chaosRate).range(windBaseFreq, windBaseFreq*1.5);
	fg = BPF.ar(fg, fgModulator, 0.01);

	sig = Mix.ar([bg, fg]);
	Out.ar(out, sig);
}).add;

SynthDef(\fire, #{ |out=0, freq=440, dur=20, direction=1, amp=0.2|
	var partialCount = 4;
	var octRange = 2 ** (partialCount / 2);
	var cycle = 1 / (partialCount * dur);
	var width = if(direction >= 0, 1, 0);
	var sig = partialCount.collect { |n|
		var offset = n / partialCount;
		var phase = (3 * pi / 2) + (2 * pi * offset);
		var vol = SinOsc.kr(cycle, phase).range(0, 1);
		var ratio = VarSaw.kr(cycle, offset, width).exprange(1/octRange, octRange);
		SinOsc.ar(freq * ratio) * vol;
	}.sum;
	var low = SinOsc.ar(80) * 8;
	sig = Mix.ar([low,sig]*amp);
	Out.ar(out, sig);
}).add;

SynthDef(\life, {
	|out=0, rate=1, amp=0.3, buffer, dur=0.01, variation=0.5, pitch=1|

	var sig;

	sig = TGrains.ar(
		numChannels: 1,
		trigger: Dust.kr(Lag.kr(rate, 5)),
		dur: Lag.kr(dur, 5),
		bufnum: buffer,
		centerPos: BrownNoise.kr(variation).range(0, 1) * BufDur.kr(buffer),
		amp: amp,
		rate: pitch
	);
	sig = HPF.ar(sig, 400);
	sig = Mix.ar(sig);
	Out.ar(out, sig);
}).add;


SynthDef(\masterOut, {
	|amp=1, masterBus|

	var sig;
	sig = In.ar(masterBus)*Lag.kr(amp, 1);

	Out.ar(0, Splay.ar(sig)!2);
}).add;