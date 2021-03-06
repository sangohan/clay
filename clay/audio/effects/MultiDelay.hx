package clay.audio.effects;

import clay.audio.Sound;

// https://github.com/corbanbrook/dsp.js

class MultiDelay extends AudioEffect {

	public var delaySamples(default, set):Int;

	var delayBufferSamples:kha.arrays.Float32Array;

	var delayInputPointer:Int;
	var delayOutputPointer:Int;
	var delayVolume:Float;
	var masterVolume:Float;

	var sampleRate:Float;

	public function new(delaySamples:Int, masterVolume:Float, delayVolume:Float) {
		delayBufferSamples = new kha.arrays.Float32Array(delaySamples); // The maximum size of delay
		delayInputPointer  = delaySamples;
		delayOutputPointer = 0;
	 
		this.delaySamples = delaySamples;
		this.delayVolume = delayVolume;
		this.masterVolume = masterVolume;

		sampleRate = Clay.audio.sampleRate;
	}

	override function process(samples:Int, buffer:kha.arrays.Float32Array, sampleRate:Int) {
		for (i in 0...Std.int(samples/2)) {
			buffer[i*2] = getDelayed(buffer[i*2]) * masterVolume;
			buffer[i*2+1] = getDelayed(buffer[i*2+1]) * masterVolume;
		}
	}

	function getDelayed(input:Float) {
		var delaySample = delayBufferSamples.get(delayOutputPointer);

		// Mix normal audio data with delayed audio
		var sample = (delaySample * delayVolume) + input;

		// Add audio data with the delay in the delay buffer
		delayBufferSamples.set(delayInputPointer, sample);
		
		// Manage circulair delay buffer pointers
		delayInputPointer++;

		if (delayInputPointer >= delayBufferSamples.length-1) {
			delayInputPointer = 0;
		}
		 
		delayOutputPointer++;

		if (delayOutputPointer >= delayBufferSamples.length-1) {
			delayOutputPointer = 0; 
		} 

		return sample;
	}

	function set_delaySamples(v:Int):Int {
		delaySamples = v;
		delayInputPointer = delayOutputPointer + delaySamples;

		if (delayInputPointer >= delayBufferSamples.length-1) {
			delayInputPointer = delayInputPointer - delayBufferSamples.length; 
		}

		return delaySamples;
	}


}