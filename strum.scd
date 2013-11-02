// variation on classic plucked string model, adapted
// from Nick Collins's examples
//  -> http://www.sussex.ac.uk/Users/nc81/modules/cm1/scfiles/4.1 Interaction 1.html
// swipe your finger from left to right to pluck the strings


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
SynthDef(\strum, {
	arg outBus = 0, gate = 1, atk = 5.0, z = 1;
	var env, pitch1, pitch2, strum, sig, decayTime, cDecayTime;
	env = EnvGen.kr(Env.adsr(atk, 1, 1), gate, doneAction: 2);
	pitch1 = [ 52, 57, 62, 67, 71, 76, 81, 86 ];
	pitch2 = pitch1 + 12;

	strum = In.kr(~h1x);

	decayTime = 5.asWarp.map(In.kr(~h1x));
	cDecayTime = 10.0 * In.kr(~h1z);

	sig = Mix.arFill(pitch1.size, { arg i;
		var trigger, pluck1, pluck2, period1, period2, string1, string2, pitchHop;
		// place trigger points from 0.25 to 0.75
		pitchHop = 0.5 / pitch1.size;
		trigger = HPZ1.kr(strum > (0.25 + (i * pitchHop)));

		pluck1 = PinkNoise.ar(Decay.kr(trigger.max(0), decayTime));
		period1 = pitch1.at(i).midicps.reciprocal;
		string1 = CombL.ar(pluck1, period1, period1, cDecayTime);

		pluck2 = BrownNoise.ar(Decay.kr(trigger.neg.max(0), decayTime));
		period2 = pitch2.at(i).midicps.reciprocal;
		string2 = CombL.ar(pluck2, period2, period2, -1*cDecayTime);

		Pan2.ar(string1 + string2, i * 0.2 - 0.5);
	});
	sig = LeakDC.ar(LPF.ar(sig, 12000));
	Out.ar(outBus, env * sig);
}).add;
)

///////////////////////////////////
/////  3) LAUNCH SYNTH

~strum = Synth(\strum);


///////////////////////////////////
/////  4) SETUP OSC CONTROL

// first finger position
(
OSCFunc({
	|msg|
	~h1x.set(msg[1]);
	~h1y.set(msg[2]);
	~h1z.set(msg[2]);
},  '/h1/', nil);
)