/*
                  FEMME IN CONTRE-JOUR
                    by Fèlix Pastor
               felixpastor.wordpress.com

    Piece for cello, accordion, dance and electronics
      performed at the Mies van der Rohe Pavillion
   in Barcelona on June 8th through 10th @ 20:30, 2017.
*/

// Author: Enric Guaus
// Web: enricguaus.wordpress.com
// Date: 26/10/2017
// Description: The role of live electronics is to explain the subconscious of the femme.
//              As soon as the first contradictions emerge, the noises and effects transform
//              the two driving voices (represented by the cello and the accordion). In some cases,
//              these transformations are subtile but, in other cases, they fill both the sonic
//              and physical spaces. She can not control it. The only way to escape just keep
//              walking in her own way.

// HW Required: AKAI LPD8 (USB MIDI Pad controller)

// Audio files: mingling.wav (also available in freesound: http://freesound.org/people/eguaus/sounds/218990/)
//              FC2-Sustain_stereoV2.aiff (created by Felix Pastor)

// Feel free to reuse and improve this code. If you have any suggestion, please, contact me.



// Variables storing buffers   : a b c d
// Variables storing Synthdefs : r (s) t u v w x y z
// The server                  : s
// Variable for OSCResponder   : o
// Variable storing OSC value  : q
// MIDI and OSC                : m n

(
// -----------------------------------
// ----  PREPARE OSC CONNECTION   ----
// ---- Run this before SynthDefs ----
// -----------------------------------
m = NetAddr("127.0.0.1", 57120); // <---- Put your IP address and port here.
MIDIIn.connectAll;

MIDIdef.noteOn (\padOn , { |vel, note, chan, port|
	var te, ve;
	postf("Sending OSC: ");
	te=postf("/0/push%",note-35);
	postf(" %\n",vel/127);
	ve=vel/127;
	m.sendMsg(te,ve.asString)
	});
MIDIdef.noteOff(\padOff, { |vel, note, chan, port|
	var te, ve;
	postf("Sending OSC: ");
	te=postf("/0/push%",note-35);
	postf(" %\n",0);
	ve=0;
	m.sendMsg(te,ve.asString)
	});
MIDIdef.cc(\radio , { |vel, note, chan, port|
	var te, ve;
	postf("Sending OSC: ");
	te=postf("/0/knob%",note);
	postf(" %\n",vel/127);
	ve=vel/127;
	m.sendMsg(te,(ve.round(0.001)+0.0001).asString)
	});
)

(
// --------------------------------------------
// ----             SYNTHDEFs              ----
// ---- Run this after MIDI/OSC conversion ----
// --------------------------------------------
Server.default = Server.internal;
s = Server.default;
s.waitForBoot({
	// ---- LOAD AUDIO BUFFERS ----
	a = Buffer.read(s, "sounds/mingling.wav");
	b = Buffer.read(s, "sounds/FC2-Sustain_stereoV2.aiff");
	c = Buffer.alloc(s, 4096, 1); // for 1st input, mixed in the Behringer mixer
	d = Buffer.alloc(s, 4096, 1); // for 2nd input, mixed in the Behringer mixer
	// ---- PAD5: Drone made by Sines ----
	SynthDef(\drone_sin, {arg amp = 1, freq = 200, gate = 0, pan_period = 0.5, fade_time = 5, feedback = 1, vol = 0;
		var env = EnvGen.kr(Env.asr(2*fade_time, 0.06, fade_time), gate, doneAction: 0); // 0.059 és 1/17
		var osc = SinOscFB.ar(freq, feedback, 0.3);
		var pan = Pan2.ar(5*vol * amp * osc, pos: FSinOsc.kr(pan_period), level: env);
		Out.ar(0, pan);
	}).add;
	// ---- PAD1: Drone in the mist ----
	SynthDef(\drone_mist, {arg amp = 1, freq1 = 0, freq2 = 0, freq3 = 0, freq4 = 0, gate = 0, pan_period = 0.5, fade_time = 5, vol = 0;
		var env   = EnvGen.kr(Env.asr(2*fade_time, 0.06, fade_time), gate, doneAction: 0); // 0.059 és 1/17
		var freqs = [freq1, freq2, freq3, freq4];
		var osc   = DynKlank.ar(`[freqs, nil, [1, 1, 1, 1]], PinkNoise.ar([0.007,0.007]));
		var pan   = Pan2.ar(10*vol * amp * osc, pos: FSinOsc.kr(pan_period), level: env);
		Out.ar(0, pan);
	}).add;
	// ---- PAD6: Granular listening ----
	SynthDef(\in_granu,{arg bufnum, amp = 0, pitch_depth = 0, time_depth = 0, grain_size = 1;
		var p_disp, t_disp, in, osc, pan;
		in     = SoundIn.ar(0);
		p_disp = pitch_depth * LFNoise2.kr(0.2).linlin(-1,1,0.5,4) + 0.001;
		t_disp = time_depth  * LFNoise2.kr(0.2).linlin(-1,1,0,10) + 0.001;
		osc    = PitchShift.ar(in, grain_size, 0.5, p_disp, t_disp);
		3.do{arg i;
			osc = DelayL.ar(osc,1,Rand(0,1),1/(2**i),osc);
			osc = PitchShift.ar(osc, grain_size, 0.5, p_disp, t_disp, 1,  osc);
		};
		pan    = Pan2.ar(amp * osc, pos: LFNoise2.kr(2));
		Out.ar(0, pan);
	}).add;
	// ---- PAD2: Pitch listening ----
	SynthDef(\in_pitch, {arg bufnum, vol = 0, threshold = 0;
		var freq, hasFreq, pan, osc;
		var myLag      = 0.3;
		var in         = SoundIn.ar(0);
		var amp        = 1; //Amplitude.ar(in, 0.05, 0.05,3);
		#freq, hasFreq = Pitch.kr(in*threshold, ampThreshold: 0.03, clar: 1, median: 4, peakThreshold: 0.8, maxFreq: 880);
		osc            = GVerb.ar(
			    LFNoise2.kr(2).linlin(-1,1,1.0,2)* Resonz.ar(WhiteNoise.ar(0.5), 0.75*Lag.kr(freq,myLag),LFNoise2.kr(2).linlin(-1,1,0.001,0.005))+
			    LFNoise2.kr(2).linlin(-1,1,1.0,2)* Resonz.ar(WhiteNoise.ar(0.5), 1.50*Lag.kr(freq,myLag),LFNoise2.kr(2).linlin(-1,1,0.001,0.005))+
			    LFNoise2.kr(2).linlin(-1,1,0.5,1)* Resonz.ar(WhiteNoise.ar(0.5), 3.00*Lag.kr(freq,myLag),LFNoise2.kr(2).linlin(-1,1,0.001,0.005))+
			    LFNoise2.kr(2).linlin(-1,1,0.5,1)* Resonz.ar(WhiteNoise.ar(0.5), 4.50*Lag.kr(freq,myLag),LFNoise2.kr(2).linlin(-1,1,0.001,0.005)),
			34, 10, 0.2, spread:30);
		pan            = Pan2.ar( 2* vol * amp * osc, pos: LFNoise2.kr(2));
		Out.ar(0, pan);
	}).add;
	// ---- PAD7: Reverb listening (just in case. Not in the score) ----
	SynthDef(\in_reve, {arg bufnum, amp = 0, wet = 0;
		var in  = SoundIn.ar(0);
		var del = DelayN.ar(in, 0.1, 0.1); // max 100 ms predelay
		var osc = GVerb.ar(del, 50, 10*wet, 0.8, spread:30, drylevel: 0.1);
		var pan = Pan2.ar(amp * osc, pos: LFNoise2.kr(2));
		Out.ar(0, pan);
	}).add;
	// ---- PAD3: Gaussian noise ----
	SynthDef(\dust, {arg amp = 0, density=0;
		var osc = LPF.ar(Dust.ar(100*density,amp),3000);
		var pan = Pan2.ar(amp * osc, pos: LFNoise2.kr(2));
		Out.ar(0, pan);
	}).add;
	// ---- PAD8: Play Mingling file ----
	SynthDef(\read_file, {arg bufnum, amp = 0, gate = 1, rate=1;
		var env = EnvGen.kr(Env.asr(10, 1, 3), gate, doneAction: 2) ;
		var snd = PlayBuf.ar(2, bufnum, rate, loop: 1, doneAction: 2);
		Out.ar(0, env * amp * snd);
	}).add;
	// ---- PAD4: Play Cello file ----
	SynthDef(\read_cello, {arg bufnum, amp = 0, gate = 1, rate=0;
		var env  = EnvGen.kr(Env.asr(10, 1, 3), gate, doneAction: 2) ;
		var snd  = PlayBuf.ar(2, bufnum, rate: 1, loop: 1, doneAction: 2);
		var tre = (0.5*(1-rate))+(0.5*rate*SinOsc.ar(Rand(10,20)));
		Out.ar(0, 8 * env * amp * tre * snd);
	}).add;
});
)

(
// ---------------------------------------------
// ----              OSC CONTROL            ----
// ---- Third, run this after the SynthDefs ----
// ---------------------------------------------
n = NetAddr.new("127.0.0.1", 57120);

// ---- PAD5 and PAD1: Drone made by Sines and Mistery ----
o = OSCresponderNode(nil, '/0/push5', {|pt, pr, pmsg|
	q = pmsg[1].asFloat;
	if(q>0,{
		r=[
			Synth.new(\drone_sin, [\amp, rrand(30,100)/100, \freq, 28.midicps, \pan_period, rrand(0.03,0.06), \feedback, rrand(0,3)]),
			Synth.new(\drone_sin, [\amp, rrand(30,100)/100, \freq, 31.midicps, \pan_period, rrand(0.03,0.06), \feedback, rrand(0,3)]),
			Synth.new(\drone_sin, [\amp, rrand(30,100)/100, \freq, 35.midicps, \pan_period, rrand(0.03,0.06), \feedback, rrand(0,3)]),
			Synth.new(\drone_sin, [\amp, rrand(30,100)/100, \freq, 38.midicps, \pan_period, rrand(0.03,0.06), \feedback, rrand(0,3)]),
			Synth.new(\drone_sin, [\amp, rrand(30,100)/100, \freq, 40.midicps, \pan_period, rrand(0.03,0.06), \feedback, rrand(0,3)]),
			Synth.new(\drone_sin, [\amp, rrand(30,100)/100, \freq, 43.midicps, \pan_period, rrand(0.03,0.06), \feedback, rrand(0,3)]),
			Synth.new(\drone_sin, [\amp, rrand(30,100)/100, \freq, 47.midicps, \pan_period, rrand(0.03,0.06), \feedback, rrand(0,3)]),
			Synth.new(\drone_sin, [\amp, rrand(30,100)/100, \freq, 50.midicps, \pan_period, rrand(0.03,0.06), \feedback, rrand(0,3)]),
			Synth.new(\drone_sin, [\amp, rrand(30,100)/100, \freq, 52.midicps, \pan_period, rrand(0.03,0.06), \feedback, rrand(0,3)]),
			Synth.new(\drone_sin, [\amp, rrand(30,100)/100, \freq, 55.midicps, \pan_period, rrand(0.03,0.06), \feedback, rrand(0,3)]),
			Synth.new(\drone_sin, [\amp, rrand(30,100)/100, \freq, 59.midicps, \pan_period, rrand(0.03,0.06), \feedback, rrand(0,3)]),
			Synth.new(\drone_sin, [\amp, rrand(30,100)/100, \freq, 62.midicps, \pan_period, rrand(0.03,0.06), \feedback, rrand(0,3)]),
			Synth.new(\drone_sin, [\amp, rrand(30,100)/100, \freq, 64.midicps, \pan_period, rrand(0.03,0.06), \feedback, rrand(0,3)]),
			Synth.new(\drone_sin, [\amp, rrand(30,100)/100, \freq, 67.midicps, \pan_period, rrand(0.03,0.06), \feedback, rrand(0,3)]),
			Synth.new(\drone_sin, [\amp, rrand(30,100)/100, \freq, 71.midicps, \pan_period, rrand(0.03,0.06), \feedback, rrand(0,3)]),
			Synth.new(\drone_sin, [\amp, rrand(30,100)/100, \freq, 74.midicps, \pan_period, rrand(0.03,0.06), \feedback, rrand(0,3)]),
			Synth.new(\drone_sin, [\amp, rrand(30,100)/100, \freq, 76.midicps, \pan_period, rrand(0.03,0.06), \feedback, rrand(0,3)])
		].scramble;
		17.do{arg cnt; r[cnt].run; r[cnt].register;};
	},{
		17.do{arg cnt; r[cnt].release(0.001);};
		17.do{arg cnt; r[cnt].free;}; // Maybe not useful at all?
	})
}).add;

o = OSCresponderNode(nil, '/0/push1', {|pt, pr, pmsg|
	q = pmsg[1].asFloat;
	if(q>0,{
		t=Array.fill(17,{Synth.new(\drone_mist, [\amp, rrand(30,100)/100, \freq1, rrand(125,250), \freq2, rrand(600,800), \freq3, rrand(1000,1300), \freq4, rrand(1500,1900), \pan_period, rrand(0,10)]);});
		17.do{arg cnt; t[cnt].run; t[cnt].register;};
	},{
		17.do{arg cnt; t[cnt].release(0.001);};
		17.do{arg cnt; t[cnt].free;}; // Maybe not useful at all?
	})
}).add;

o = OSCresponderNode(nil, '/0/knob1', {|pt, pr, pmsg|
	q = pmsg[1].asFloat;
	17.do{arg cnt; if(r[cnt].isPlaying,{r[cnt].set(\vol, q);})};
	17.do{arg cnt; if(t[cnt].isPlaying,{t[cnt].set(\vol, q);})};
}).add;

o = OSCresponderNode(nil, '/0/knob5', {|pt, pr, pmsg|
	var n_close=0;
	var n_open =0;
	n_open  = pmsg[1].asFloat.linlin(0,1,0,17);
	n_close = 17 - n_open;
	n_open.do{arg cnt; if(r[cnt].isPlaying,{r[cnt].set(\gate, 1);})};
	n_open.do{arg cnt; if(t[cnt].isPlaying,{t[cnt].set(\gate, 1);})};
	n_close.do{arg cnt; if(r[cnt].isPlaying,{r[17-cnt-1].set(\gate, 0);})};
	n_close.do{arg cnt; if(t[cnt].isPlaying,{t[17-cnt-1].set(\gate, 0);})};
}).add;

// ---- PAD6 and PAD2: Granular and Pitch listening  ----
o = OSCresponderNode(nil, '/0/push6', {|pt, pr, pmsg|
	q = pmsg[1].asFloat;
	if(q>0,{
		u = Synth.new(\in_granu, [\bufnum, c]);
		u.register;
	},{
		u.free;
	});
}).add;

o = OSCresponderNode(nil, '/0/push2', {|pt, pr, pmsg|
	q = pmsg[1].asFloat;
	if(q>0,{
		v = Synth.new(\in_pitch, [\bufnum, d, \vol, q]);
		v.register;
	},{
		v.free;
	});
}).add;

o = OSCresponderNode(nil, '/0/knob2', {|pt, pr, pmsg|
	q = pmsg[1].asFloat;
	if(u.isPlaying, {u.set(\amp, q)});
	if(v.isPlaying, {v.set(\vol, q)});
}).add;

o = OSCresponderNode(nil, '/0/knob6', {|pt, pr, pmsg|
	q = pmsg[1].asFloat;
	if(u.isPlaying, {u.set(\pitch_depth, q)});
	if(u.isPlaying, {u.set(\time_depth , q)});
	if(v.isPlaying, {v.set(\threshold, q)});
}).add;

// ---- PAD7 and PAD3: Reverb and Dust synths  ----
o = OSCresponderNode(nil, '/0/push7', {|pt, pr, pmsg|
	q = pmsg[1].asFloat;
	if(q>0,{
		w = Synth.new(\in_reve, [\bufnum, c]);
		w.register;
	},{
		w.free;
	});
}).add;

o = OSCresponderNode(nil, '/0/push3', {|pt, pr, pmsg|
	q = pmsg[1].asFloat;
	if(q>0,{
		x = Synth.new(\dust);
		x.register;
	},{
		x.free;
	});
}).add;

o = OSCresponderNode(nil, '/0/knob3', {|pt, pr, pmsg|
	q = pmsg[1].asFloat;
	if(w.isPlaying, {w.set(\amp, q)});
	if(x.isPlaying, {x.set(\amp, q)});
}).add;

o = OSCresponderNode(nil, '/0/knob7', {|pt, pr, pmsg|
	q = pmsg[1].asFloat;
	if(w.isPlaying, {w.set(\wet, q)});
	if(x.isPlaying, {x.set(\density,q)});
}).add;

// ---- PAD8 and PAD4: Play two audio files ----
o = OSCresponderNode(nil, '/0/push8', {|pt, pr, pmsg|
	q = pmsg[1].asFloat;
	if(q>0,{
		y = Synth.new(\read_file, [\bufnum, a]);
		y.register;
	},{
		y.set(\gate, 0);
	});
}).add;

o = OSCresponderNode(nil, '/0/push4', {|pt, pr, pmsg|
	q = pmsg[1].asFloat;
	if(q>0,{
		z = Synth.new(\read_cello, [\bufnum, b]);
		z.register;
	},{
		z.set(\gate, 0);
	});
}).add;

o = OSCresponderNode(nil, '/0/knob4', {|pt, pr, pmsg|
	q = pmsg[1].asFloat;
	if(y.isPlaying, {y.set(\amp, q)});
	if(z.isPlaying, {z.set(\amp, q)});
}).add;

o = OSCresponderNode(nil, '/0/knob8', {|pt, pr, pmsg|
	q = pmsg[1].asFloat;
	if(z.isPlaying, {z.set(\rate, q)});
}).add;
)

(
// --------------------
// ----    EXIT    ----
// ---- At the end ----
// --------------------
a.free;                            // Audio buffers
b.free;
c.free;

o.remove;                          // OSC Messages
n.disconnect;

m.disconnect;                      // MIDI send to OSC
MIDIdef.freeAll;

17.do{arg cnt; r[cnt].free;};      // Synths
17.do{arg cnt; t[cnt].free;};
u.free;
v.free;
w.free;
x.free;
y.free;
z.free;

s.quit;
)
