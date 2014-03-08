package shaders
{

	public function writeDepth32_fragment():String
	{
		var shader:Array = [
			'tex ft0, v0.xy, fs0<ignoresampler>', // get depth from texture
			'dp4 ft0.x, ft0, fc0', // unpack it to float. fc0 = [1, 1 / 255, 1 / 65025, 1 / 160581375]

			'add ft0.x, ft0.x, fc1.x', // add epsilon. fc1.x = epsilon
			'sub ft0.x, v1.x, ft0.x', // currDepth - existingDepth. v1.x - current pixel depth

			'kil ft0.x', // if current pixel depth less or equal existing depth discard it

			// pack float depth to 4 bytes
			'mul ft0, fc2, v1', // fc2 = [1, 255, 65025, 160581375]. v1.xyzw - current pixel depth
			'frc ft0, ft0',
			'mul ft1, fc3, ft0.yzww', // fc3 = [1 / 255, 1 / 255, 1 / 255, 0]
			'sub ft0, ft0, ft1',
			'mov oc, ft0'
		];

		return shader.join( '\n' );
	}
}
