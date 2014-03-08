package shaders
{
	public function drawLayer_vertex():String
	{
		var shader:Array = [
			'm44 vt0, va0, vc1', // vc1 = model matrix

			'add vt1.x, vc0.x, vt0.x', // convert vertex.x to 0..2 range. vc0.x = 1
			'mul vt1.x, vt1.x, vc0.y', // convert vertex.x to 0..1 range. vc0.y = 0.5

			'sub vt1.y, vc0.x, vt0.y', // convert vertex.y to 0..2 range
			'mul vt1.y, vt1.y, vc0.y', // convert vertex.y to 0..1 range

			'mov v0.xyzw, vt1.xyyy', // need xy for texture coordinates
			'mov v1, vt0.z', // depth
			'mov op, vt0'
		];

		return shader.join( '\n' );
	}
}
