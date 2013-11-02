// Three voice organ-like sounding instrument using DynKlank
// Move hand around and each of the x, y, and z postiion affect the pitch
// of one of the three voices


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
SynthDef(\organ, {
	arg outBus = 0, gate = 1, atk = 5.0;
	var env, klank1, klank2, klank3, n, harm, amp, ring, pitches, freq1, freq2, freq3, cnoiseMul;
	env = EnvGen.kr(Env.adsr(atk, 1, 1), gate, doneAction: 2);
	//pitches = [0, 3, 5, 7, 10, 12, 17, 22];
	pitches = [0, 3, 5, 7, 10, 12, 17, 22, 24, 29, 34];
	n = pitches.size;
	cnoiseMul = 0.006;	//-44, -20, 4
	freq1 = Select.kr(In.kr(~h1x)*n, 55+pitches).midicps;
	freq2 = Select.kr(In.kr(~h1y)*n, 31+pitches).midicps;
	freq3 = Select.kr(In.kr(~h1z)*n,  7+pitches).midicps;
	harm = Control.names(\harm).kr(Array.series(4,1,1));
	amp = Control.names(\amp).kr(Array.fill(4,0.05));
	ring = Control.names(\ring).kr(Array.fill(4,1));
	klank1 = DynKlank.ar(`[harm,amp,ring], {ClipNoise.ar(cnoiseMul)}.dup, freq1);
	klank2 = DynKlank.ar(`[harm,amp,ring], {ClipNoise.ar(cnoiseMul)}.dup, freq2);
	klank3 = DynKlank.ar(`[harm,amp,ring], {ClipNoise.ar(cnoiseMul)}.dup, freq3);
	Out.ar(outBus, env * (klank1 + klank2 + klank3));
}).add;
)

///////////////////////////////////
/////  3) LAUNCH SYNTH

~organ = Synth(\organ);


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