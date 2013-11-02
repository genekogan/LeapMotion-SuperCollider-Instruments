// Filtered Ring Modulator
// a ring modulator going through an allpass filter with variable delay time
// first setup busses, synths, and osc control.
// then, using the Processing leap OSC sketch, the x, y, and z position of
// your first finger control the carrier freq, modulator freq, and allpass delay
// time respectively. be careful, can get loud


///////////////////////////////////
/////  1) SETUP BUSSES
(
~h1x = Bus.control(s, 1);   // leap motion, first finger x position
~h1y = Bus.control(s, 1);   // leap motion, first finger y position
~h1z = Bus.control(s, 1);   // leap motion, first finger z position
)


///////////////////////////////////
/////  2) SETUP SYNTH
(
SynthDef(\ringMod, {
	arg outBus = 0, gate = 1, atk = 5.0;
	var env, freq, ratio, modulator, carrier, sig;
	env = EnvGen.kr(Env.adsr(atk, 1, 1), gate, doneAction: 2);
	freq = LFNoise0.kr(65*In.kr(~h1x)+5, 80, 60).round(24).midicps;
	ratio = -2.0+14.0*In.kr(~h1z);
	modulator = SinOsc.ar(freq * ratio, 0, 4.0);
	carrier = SinOsc.ar(freq, modulator, 0.5);
	sig = carrier!2;
	//8.do({ out = AllpassC.ar(out, 0.5, { Rand(0.001, 0.03) }.dup, 8)});
	2.do({ sig = AllpassC.ar(sig, 0.5, DC.kr(Rand()).range(0.001, 0.5*(3.asWarp.map(In.kr(~h1y)+0.001))), 8)});
	Out.ar(outBus, 0.2 * env * sig);
}).add;
)

///////////////////////////////////
/////  3) LAUNCH SYNTH

~ringmod = Synth(\ringMod);


///////////////////////////////////
/////  4) SETUP OSC CONTROL

// first finger position
(
OSCFunc({
	|msg|
	~h1x.set(msg[1]);
	~h1y.set(msg[2]);
	~h1z.set(msg[3]);
},  '/h1/', nil);
)