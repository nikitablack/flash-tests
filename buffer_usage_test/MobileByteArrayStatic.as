package
{

	import flash.display3D.Context3DBufferUsage;

	[SWF(frameRate=60, width=800, height=600, backgroundColor=0x000000)]
	public class MobileByteArrayStatic extends DemoByteArray
	{
		public function MobileByteArrayStatic()
		{
			super( 1000, 4, Context3DBufferUsage.STATIC_DRAW );
		}
	}
}
