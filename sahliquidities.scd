// Variation on sample and hold liquidities from SuperCollider book, run through Comb filter.
//  -> http://ecmc.rochester.edu/ecmc/docs/supercollider/scexamples.1.html
// finger x and y position controls the pitch and clock rate respectively.


///////////////////////////////////
/////  1) SETUP BUSSES
(
~h1x = Bus.control(s, 1);   // leap motion, first finger x position
~h1y = Bus.control(s, 1);   // leap motion, first finger y position
)


///////////////////////////////////
/////  2) SETUP SYNTH
(
SynthDef(\sahliquid, {
	arg out = 0, gate = 1, atk = 5.0;
	var env, clockRate, clockTime, clock, centerFreq, freq, panPos, patch;
	env = EnvGen.kr(Env.adsr(atk, 1, 1), gate, doneAction: 2);
	centerFreq = 8000 * 2.asWarp.map(In.kr(~h1x)) + 100;
	clockRate = 300 * In.kr(~h1y) + 1;
	clockTime = 2.0*clockRate.reciprocal;
	clock = Impulse.kr(clockRate, 0.4);
	freq = Latch.kr(WhiteNoise.kr(centerFreq * 0.5, centerFreq), clock);
	panPos = Latch.kr(WhiteNoise.kr, clock);
	patch = CombN.ar(
		Pan2.ar(
			SinOsc.ar(freq, 0, Decay2.kr(clock, 0.1 * clockTime, 0.9 * clockTime)),
			panPos
		), 0.3, 0.3, 2);
	Out.ar(out, env * patch);
}).add;
)

///////////////////////////////////
/////  3) LAUNCH SYNTH

~sahliquid = Synth(\sahliquid);


///////////////////////////////////
/////  4) SETUP OSC CONTROL

// first finger position
(
OSCFunc({
	|msg|
	~h1x.set(msg[1]);
	~h1y.set(msg[2]);
},  '/h1/', nil);
)