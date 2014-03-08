package shaders
{

	public function mergeLayers_fragment():String
	{
		var shader:Array = [
			'tex ft0, v0.xy, fs1<ignoresampler>', // color from old layer - source
			'tex ft1, v0.xy, fs0<ignoresampler>', // color from new layers - destination

			'sub ft2.w, fc0.x, ft0.w', // 1 - srcA
			'mul ft2.w, ft1.w, ft2.w', // dstA * (1 - srcA)

			'add ft3.w, ft0.w, ft2.w', // srcA + dstA * (1 - srcA)

			'mul ft3.xyz, ft1.xyz, ft2.w', // dstRGB * dstA * (1 - srcA)
			'mul ft2.xyz, ft0.xyz, ft0.w', // srcRGB * srcA
			'add ft3.xyz, ft2.xyz, ft3.xyz', // srcRGB * srcA + dstRGB * dstA * (1 - srcA)
			'div ft3.xyz, ft3.xyz, ft3.w', // (srcRGB * srcA + dstRGB * dstA * (1 - srcA)) / outA

			'sge ft2.w, ft3.w, fc0.y', // outA >= treshold
			'mul oc, ft3, ft2.w' // outA >= treshold ? outRGB : 0
		];

		return shader.join( '\n' );
	}
}
