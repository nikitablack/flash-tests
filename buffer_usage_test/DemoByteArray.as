package
{

	import com.adobe.utils.AGALMiniAssembler;

	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBufferUsage;
	import flash.display3D.Context3DProfile;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	[SWF(frameRate=60, width=800, height=600, backgroundColor=0x000000)]
	public class DemoByteArray extends Sprite
	{
		private var _numQuads:uint;
		private var _numUploads:uint;
		private var _bufferUsage:String;

		private var _context3D:Context3D;
		private var _vertexBuffer:VertexBuffer3D;
		private var _colorBuffer:VertexBuffer3D;
		private var _indexBuffer:IndexBuffer3D;

		private var _vertices:ByteArray;

		function DemoByteArray(numQuads:uint, numUploads:uint, bufferUsage:String)
		{
			_numQuads = numQuads;
			_numUploads = numUploads;
			_bufferUsage = bufferUsage;

			stage.stage3Ds[0].addEventListener( Event.CONTEXT3D_CREATE, contextCreateHandler );
			stage.stage3Ds[0].requestContext3DMatchingProfiles( Vector.<String>( [Context3DProfile.BASELINE_EXTENDED, Context3DProfile.BASELINE, Context3DProfile.BASELINE_CONSTRAINED] ) );
		}

		private function contextCreateHandler( event:Event ):void
		{
			_context3D = (event.target as Stage3D).context3D;
			trace( _context3D.profile );
			_context3D.configureBackBuffer( 800, 600, 1, true );
			_context3D.enableErrorChecking = false;

			_vertices = new ByteArray();
			_vertices.endian = Endian.LITTLE_ENDIAN;

			var colors:Vector.<Number> = new Vector.<Number>();
			var indices:Vector.<uint> = new Vector.<uint>();
			var pos:Vector3D = new Vector3D();
			var size:Number;

			for (var i:uint = 0; i < _numQuads; i++)
			{
				pos.x = -1 + 2 * Math.random();
				pos.y = -1 + 2 * Math.random();
				size = Math.random() * 0.1;

				_vertices.writeFloat( pos.x - size );
				_vertices.writeFloat( pos.y + size );
				_vertices.writeFloat( 0.5 );
				_vertices.writeFloat( pos.x + size );
				_vertices.writeFloat( pos.y + size );
				_vertices.writeFloat( 0.5 );
				_vertices.writeFloat( pos.x + size );
				_vertices.writeFloat( pos.y - size );
				_vertices.writeFloat( 0.5 );
				_vertices.writeFloat( pos.x - size );
				_vertices.writeFloat( pos.y - size );
				_vertices.writeFloat( 0.5 );

				colors.push( Math.random(), Math.random(), Math.random() );
				colors.push( Math.random(), Math.random(), Math.random() );
				colors.push( Math.random(), Math.random(), Math.random() );
				colors.push( Math.random(), Math.random(), Math.random() );

				indices.push( i * 4 + 0, i * 4 + 1, i * 4 + 3 );
				indices.push( i * 4 + 1, i * 4 + 2, i * 4 + 3 );
			}

			_vertexBuffer = _context3D.createVertexBuffer( 4 * _numQuads, 3, _bufferUsage );
			_context3D.setVertexBufferAt( 0, _vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3 );

			_colorBuffer = _context3D.createVertexBuffer( 4 * _numQuads, 3 );
			_colorBuffer.uploadFromVector( colors, 0, 4 * _numQuads );

			_indexBuffer = _context3D.createIndexBuffer( 6 * _numQuads )
			_indexBuffer.uploadFromVector( indices, 0, indices.length );

			var vs:String = 'mov op, va0\n' +
					'mov v0, va1';

			var fs:String = 'mov oc, v0';

			var assembler:AGALMiniAssembler = new AGALMiniAssembler( true );
			var program:Program3D = _context3D.createProgram();
			program.upload( assembler.assemble( Context3DProgramType.VERTEX, vs ), assembler.assemble( Context3DProgramType.FRAGMENT, fs ) );

			_context3D.setVertexBufferAt( 1, _colorBuffer, 0, Context3DVertexBufferFormat.FLOAT_3 );
			_context3D.setProgram( program );

			addEventListener( Event.ENTER_FRAME, enterFrameHandler );
		}

		private function enterFrameHandler( event:Event ):void
		{
			_context3D.clear( 0.5, 0.5, 0.5 );

			for (var i:uint = 0; i < _numUploads; i++)
			{
				_vertexBuffer.uploadFromByteArray( _vertices, 0, 0, 4 * _numQuads );
				_context3D.drawTriangles( _indexBuffer );
			}

			_context3D.present();
		}
	}
}
