// CreepyBell
// variation of weird bell code example from the SuperCollider book:
//  -> http://ecmc.rochester.edu/ecmc/docs/supercollider/scbook/
// opening hand triggers a glitchy bell. closing and opening again triggers another
// first finger x position messes with the delay


///////////////////////////////////
/////  1) SETUP BUSSES
(
~h1x = Bus.control(s, 1);   // leap motion, first finger x position
~h1y = Bus.control(s, 1);   // leap motion, first finger y position
~h1z = Bus.control(s, 1);   // leap motion, first finger z position
~h1thresh = Bus.control(s, 1); // leap motion, hand opening threshold
)


///////////////////////////////////
/////  2) SETUP SYNTH
(
SynthDef(\creepyBell, {
	arg outBus = 0, gate = 1, atk = 5.0;
	var env, burst, burstEnv, bell, delay, dry, burstFreq = 500, freqs, amps, rings;
	env = EnvGen.kr(Env.adsr(atk, 1, 1), gate, doneAction: 2);
	burstEnv = EnvGen.kr(Env.perc(0, 0.05), In.kr(~h1thresh), 0.4);
	burst = SinOsc.ar(freq: burstFreq, mul: burstEnv);
	amps = Array.fill(10, {rrand(0.01, 0.1)});
	rings = Array.fill(10, {rrand(1.0, 6.0)});
	if ([true,false].choose, freqs = [100, 200, 800, 400, 1600, 3200, 6400], freqs = Array.fill(10, {exprand(100, 1100)}) );
	bell = Pan2.ar(
		Klank.ar(`[freqs, amps, rings], burst),
		rrand(-1.0, 1.0));
	delay = AllpassN.ar(bell, 2.5,
		[LFNoise1.kr(10*In.kr(~h1x), 1.5, 1.6), LFNoise1.kr(10*In.kr(~h1x), 1.5, 1.6)], 1, mul: 0.8);
	Out.ar(outBus, env * (bell + delay));
}).add;
)

///////////////////////////////////
/////  3) LAUNCH SYNTH

~creepybell = Synth(\creepyBell);


///////////////////////////////////
/////  4) SETUP OSC CONTROL

// first finger position and hand opening thresholds for triggering
(
OSCFunc({
	|msg|
	~h1x.set(msg[1]);
	~h1y.set(msg[2]);
},  '/h1/', nil);

OSCFunc({
	|msg| ~h1thresh.set(1);
}, '/h1thresh1/', nil);

OSCFunc({
	|msg| ~h1thresh.set(0);
}, '/h1thresh0/', nil);

)