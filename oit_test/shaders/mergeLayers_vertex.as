package shaders
{

	public function mergeLayers_vertex():String
	{
		var shader:Array = [
			'mov op, va0',
			'mov v0, va1'
		];

		return shader.join( '\n' );
	}
}
