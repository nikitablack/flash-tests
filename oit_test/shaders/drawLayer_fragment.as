package shaders
{

	public function drawLayer_fragment():String
	{
		var shader:Array = [
			'tex ft0, v0.xy, fs0<ignoresampler>', // get depth from texture
			'dp4 ft0.x, ft0, fc0', // unpack it to float. fc0 = [1, 1 / 255, 1 / 65025, 1 / 160581375]

			'sub ft0.x, ft0.x, v1.x', // get difference between current depth and depth from texture
			'abs ft0.x, ft0.x',
			'sub ft0.x, fc1.x, ft0.x', // if depths are the same - draw color. Instead - discard pixel. fc1.x = epsilon
			'kil ft0.x',

			'mov oc, fc2' // fc2 - color
		];

		return shader.join( '\n' );
	}
}
