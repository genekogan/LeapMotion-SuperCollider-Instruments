// Marimba clusters
// a variation from code by eli.fieldsteel found: http://sccode.org/1-4SB
// first setup busses, synths, and osc control.
// opening your hand (fingers spread apart) fires a single cluster,
// and swiping your hand will silence all active clusters.


///////////////////////////////////
/////  1) SETUP BUSSES
(
~h1y = Bus.control(s, 1);   // leap motion, first finger y position
~h1d = Bus.control(s, 1);   // used to measure "openness" of hand
~busMarimba = Bus.audio(s,2);
)


///////////////////////////////////
/////  2) SETUP SYNTHS

(
// last step: add reverb to clusters
SynthDef(\reverb_ef, {
	arg		amp=1, mix=0.085, revTime=1.8, preDel=0.1, lpfFreq=4500, outBus=0;
	var		sig, verbSig, totalSig, outSig;
	mix = In.kr(~h1y).clip(0, 1);
	sig = In.ar(~busMarimba, 2);
	preDel = 0.5;
	verbSig = DelayN.ar(sig, preDel, preDel);  //pre-delay
	totalSig = 0;
	12.do{
		verbSig = AllpassN.ar(verbSig, 0.06, {Rand(0.001,0.06)}!2, revTime);
		verbSig = LPF.ar(verbSig, lpfFreq);
		totalSig = totalSig + verbSig;
	};
	totalSig = XFade2.ar(sig, totalSig, mix.linlin(0,1,-1,1));  //dry/wet mix
	outSig = totalSig * amp;
	Out.ar(outBus, outSig);
}).add;

// a single note
SynthDef(\filtSaw, {
	arg	freq=440, detune=3.0, atk=6, rel=6, curve1=1, curve2=(-1),
		minCf=30, maxCf=6000, minRq=0.005, maxRq=0.04,
		minBpfHz=0.02, maxBpfHz=0.25,
		lowShelf=220, rs=0.85, db=6,
		gate=1, amp=1, spread=1.0, out;
	var sig, env;
	env = EnvGen.kr(Env.adsr(atk, rel, amp), gate, doneAction: 2);
	sig = Saw.ar(freq +
		LFNoise1.kr({LFNoise1.kr(0.5).range(0.15,0.4)}!8).range(detune.neg,detune));
	sig = BPF.ar(sig,
		LFNoise1.kr({LFNoise1.kr(0.13).exprange(minBpfHz,maxBpfHz)}!8).exprange(minCf, maxCf),
		LFNoise1.kr({LFNoise1.kr(0.08).exprange(0.08,0.35)}!8).range(minRq, maxRq));
	sig = BLowShelf.ar(sig, lowShelf, rs, db);
	sig = SplayAz.ar(4, sig, spread);
	sig = sig * env * 8;
	Out.ar(~busMarimba, sig);
}).add;

// generate a cluster of notes
~cluster = {
	var trnsp;
	trnsp = rrand(-7,7);
	Array.fill(exprand(4,14).round, {[1,2,3,4,6,8,12,16].wchoose([7,6,5,4,3,3,1].normalizeSum)}).do{
		arg i;
		var cfLo = (([23,35,47,50,52,59,61,63,64,76,78].choose) + trnsp).midicps * ((1..8).choose);
		Synth(\filtSaw, [
			\freq, i,
			\detune, 0,
			\minBpfHz, 0.01,
			\maxBpfHz,i.expexp(1.0,16.0,0.1,16.0),
			\minRq, 0.003,
			\maxRq, exprand(0.008,0.08),
			\minCf, cfLo,
			\maxCf, cfLo * [1,1.1,1.5].wchoose([0.87,0.1,0.03]),
			\amp, exprand(0.15,0.25),
			\atk, exprand(0.2,0.5),
			\rel, 0.8,
			\spread, exprand(1.5,8.0),
			\out, ~busMarimba,
		], ~clusters
)}};
)


///////////////////////////////////
/////  3) LAUNCH SYNTHS

~synth = Synth(\reverb_ef);        // this sets up the final reverb synth
~clusters = Group.before(~synth);  // a group of clusters that go to the reverb

// how to playback:
~cluster.value;                    // this launchs a single cluster. try running several times
~clusters.set(\gate, -5);          // this silences all the clusters with a 5 second fadeout


///////////////////////////////////
/////  4) SETUP OSC CONTROL

// sending an OSC message to /h1thresh1/ (open hand) will start a cluster
// sending an OSC message to /h1swipe/ (swipe) will silence all clusters
(
OSCFunc({
	|msg| ~h1y.set(msg[2]);
},  '/h1/', nil);

OSCFunc({
	|msg|
	~cluster.value;
	"cluster start".postln;
}, '/h1thresh1/', nil);

OSCFunc({
	|msg|
	~clusters.set(\gate, -5);
	"silence".postln;
}, '/h1swipe/', nil);
)

