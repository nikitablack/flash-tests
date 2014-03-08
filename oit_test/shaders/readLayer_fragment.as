package shaders
{

	public function readLayer_fragment():String
	{
		var shader:Array = [
			'tex oc, v0.xy, fs0<ignoresampler>'
		];

		return shader.join( '\n' );
	}
}
