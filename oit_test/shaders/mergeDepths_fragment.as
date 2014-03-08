package shaders
{

	public function mergeDepths_fragment():String
	{
		var shader:Array = [
			'tex ft0, v0, fs0<ignoresampler>', // depth in old depth buffer
			'tex ft1, v0, fs1<ignoresampler>', // depth in new depth buffer

			'dp4 ft2.x, ft0, fc0', // unpack old depth to float. fc0 = [1, 1 / 255, 1 / 65025, 1 / 160581375]
			'dp4 ft2.y, ft1, fc0', // unpack new depth to float.

			'add ft2.x, ft2.x, fc1.x', // fc1.x = epsilon

			'slt ft2.z, ft2.x, ft2.y', // if old depth id smaller than new, ft2.z = 1
			'mul ft1, ft1, ft2.z', // if ft2.z == 1, use new depth
			'sub ft2.z, fc0.x, ft2.z', // if ft2.z == 1 it becomes 0.
			'mul ft0, ft0, ft2.z',

			'add oc, ft0, ft1'
		];

		return shader.join( '\n' );
	}
}
