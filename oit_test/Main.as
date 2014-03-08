package {
	
	import com.adobe.utils.AGALMiniAssembler;
	import com.bit101.components.Slider;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DBufferUsage;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DMipFilter;
	import flash.display3D.Context3DProfile;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFilter;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Context3DWrapMode;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.textures.RectangleTexture;
	import flash.display3D.textures.TextureBase;
	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import shaders.drawLayer_fragment;
	import shaders.drawLayer_vertex;
	import shaders.mergeDepths_fragment;
	import shaders.mergeDepths_vertex;
	import shaders.mergeLayers_fragment;
	import shaders.mergeLayers_vertex;
	import shaders.readLayer_fragment;
	import shaders.readLayer_vertex;
	import shaders.writeDepth32_fragment;
	import shaders.writeDepth32_vertex;
	
	
	[SWF(frameRate=60,width=500,height=500,backgroundColor=0x000000)]
	public class Main extends Sprite {
		private var _context3D:Context3D;
		private var _quadVertexBuffer:VertexBuffer3D;
		private var _quadUvBuffer:VertexBuffer3D;
		private var _indexBuffer:IndexBuffer3D;
		
		private var _programWriteDepth32:Program3D;
		private var _programMergeDepths:Program3D;
		private var _programDrawLayer:Program3D;
		private var _programMergeLayers:Program3D;
		private var _programReadLayer:Program3D;
		
		private var _matrix1:Matrix3D;
		private var _matrix2:Matrix3D;
		private var _matrix3:Matrix3D;
		private var _matrix4:Matrix3D;
		
		private var _aplha1:Number;
		private var _aplha2:Number;
		private var _aplha3:Number;
		private var _aplha4:Number;
		
		private var _depthTargetA:RectangleTexture;
		private var _depthTargetB:RectangleTexture;
		private var _depthTargetC:RectangleTexture;
		private var _layerTargetA:RectangleTexture;
		private var _layerTargetB:RectangleTexture;
		private var _layerTargetC:RectangleTexture;
		
		private var _matrixBySlider:Dictionary;
		private var _alphaBySliderIndex:Dictionary;
		private var _sliderIndexBySlider:Dictionary;
		private var _offsetByMatrix:Dictionary = new Dictionary();
		
		public function Main() {
			_matrix1 = new Matrix3D();
			_matrix2 = new Matrix3D();
			_matrix3 = new Matrix3D();
			_matrix4 = new Matrix3D();
			
			_matrixBySlider = new Dictionary();
			_alphaBySliderIndex = new Dictionary();
			_sliderIndexBySlider = new Dictionary();
			_offsetByMatrix = new Dictionary();
			
			_offsetByMatrix[_matrix1] = new Vector3D(-0.2, 0.0);
			_offsetByMatrix[_matrix2] = new Vector3D(-0.1, -0.1);
			_offsetByMatrix[_matrix3] = new Vector3D(0, -0.2);
			_offsetByMatrix[_matrix4] = new Vector3D(0.1, -0.3);
			
			initControls();
			
			stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, contextCreateHandler);
			stage.stage3Ds[0].requestContext3DMatchingProfiles(Vector.<String>([Context3DProfile.BASELINE_EXTENDED]));
		}
		
		private function initControls():void {
			setupSliders(10, 0.1, _matrix1, 1);
			setupSliders(30, 0.3, _matrix2, 2);
			setupSliders(50, 0.6, _matrix3, 3);
			setupSliders(70, 0.9, _matrix4, 4);
		}
		
		private function setupSliders(posY:Number, value:Number, matrix:Matrix3D, sliderIndex:uint):void {
			var sliderPosition:Slider = new Slider(Slider.HORIZONTAL, this, 10, posY, sliderHandlerZ);
			sliderPosition.minimum = 0;
			sliderPosition.maximum = 1;
			sliderPosition.width = 170
			sliderPosition.value = value;
			sliderPosition.tick = 0.0001;
			_matrixBySlider[sliderPosition] = matrix;
			
			updateMatrix(sliderPosition);
			
			var sliderAlpha:Slider = new Slider(Slider.HORIZONTAL, this, 200, posY, sliderHandlerAlpha);
			sliderAlpha.minimum = 0;
			sliderAlpha.maximum = 1;
			sliderAlpha.value = 0.5;
			sliderAlpha.tick = 0.1;
			_alphaBySliderIndex[sliderIndex] = sliderAlpha.value;
			_sliderIndexBySlider[sliderAlpha] = sliderIndex;
		}
		
		private function updateMatrix(slider:Slider):void {
			var matrix:Matrix3D = _matrixBySlider[slider];
			matrix.identity();
			matrix.appendScale(0.5, 0.5, 1);
			
			var offset:Vector3D = _offsetByMatrix[matrix];
			matrix.appendTranslation(offset.x, offset.y, slider.value);
		}
		
		private function sliderHandlerZ(event:Event):void {
			var slider:Slider = event.target as Slider;
			updateMatrix(slider);
		}
		
		private function sliderHandlerAlpha(event:Event):void {
			var slider:Slider = event.target as Slider;
			var sliderIndex:uint = _sliderIndexBySlider[slider];
			_alphaBySliderIndex[sliderIndex] = slider.value;
		}
		
		private function contextCreateHandler(event:Event):void {
			_context3D = (event.target as Stage3D).context3D;
			_context3D.configureBackBuffer(stage.stageWidth, stage.stageHeight, 1, true);
			_context3D.enableErrorChecking = true;
			_context3D.setCulling(Context3DTriangleFace.BACK);
			
			// will use single geometry for all objects.
			var screenQuadVertices:Vector.<Number> = new Vector.<Number>();
			screenQuadVertices.push(-1, 1, 0);
			screenQuadVertices.push(1, 1, 0);
			screenQuadVertices.push(1, -1, 0);
			screenQuadVertices.push(-1, -1, 0);
			_quadVertexBuffer = _context3D.createVertexBuffer(4, 3, Context3DBufferUsage.STATIC_DRAW);
			_quadVertexBuffer.uploadFromVector(screenQuadVertices, 0, 4);
			
			var screenQuadUvs:Vector.<Number> = new Vector.<Number>();
			screenQuadUvs.push(0, 0);
			screenQuadUvs.push(1, 0);
			screenQuadUvs.push(1, 1);
			screenQuadUvs.push(0, 1);
			_quadUvBuffer = _context3D.createVertexBuffer(4, 2, Context3DBufferUsage.STATIC_DRAW);
			_quadUvBuffer.uploadFromVector(screenQuadUvs, 0, 4);
			
			var indices:Vector.<uint> = new Vector.<uint>();
			indices.push(0, 1, 3);
			indices.push(1, 2, 3);
			_indexBuffer = _context3D.createIndexBuffer(6)
			_indexBuffer.uploadFromVector(indices, 0, 6);
			
			var assembler:AGALMiniAssembler = new AGALMiniAssembler(true);
			_programWriteDepth32 = _context3D.createProgram();
			_programWriteDepth32.upload(assembler.assemble(Context3DProgramType.VERTEX, writeDepth32_vertex()), assembler.assemble(Context3DProgramType.FRAGMENT, writeDepth32_fragment()));
			
			_programMergeDepths = _context3D.createProgram();
			_programMergeDepths.upload(assembler.assemble(Context3DProgramType.VERTEX, mergeDepths_vertex()), assembler.assemble(Context3DProgramType.FRAGMENT, mergeDepths_fragment()));
			
			_programDrawLayer = _context3D.createProgram();
			_programDrawLayer.upload(assembler.assemble(Context3DProgramType.VERTEX, drawLayer_vertex()), assembler.assemble(Context3DProgramType.FRAGMENT, drawLayer_fragment()));
			
			_programMergeLayers = _context3D.createProgram();
			_programMergeLayers.upload(assembler.assemble(Context3DProgramType.VERTEX, mergeLayers_vertex()), assembler.assemble(Context3DProgramType.FRAGMENT, mergeLayers_fragment()));
			
			_programReadLayer = _context3D.createProgram();
			_programReadLayer.upload(assembler.assemble(Context3DProgramType.VERTEX, readLayer_vertex()), assembler.assemble(Context3DProgramType.FRAGMENT, readLayer_fragment()));
			
			_depthTargetA = _context3D.createRectangleTexture(stage.stageWidth, stage.stageHeight, Context3DTextureFormat.BGRA, true);
			_depthTargetB = _context3D.createRectangleTexture(stage.stageWidth, stage.stageHeight, Context3DTextureFormat.BGRA, true);
			_depthTargetC = _context3D.createRectangleTexture(stage.stageWidth, stage.stageHeight, Context3DTextureFormat.BGRA, true);
			_layerTargetA = _context3D.createRectangleTexture(stage.stageWidth, stage.stageHeight, Context3DTextureFormat.BGRA, true);
			_layerTargetB = _context3D.createRectangleTexture(stage.stageWidth, stage.stageHeight, Context3DTextureFormat.BGRA, true);
			_layerTargetC = _context3D.createRectangleTexture(stage.stageWidth, stage.stageHeight, Context3DTextureFormat.BGRA, true);
			
			addEventListener(Event.ENTER_FRAME, enterFrameHandler);
		}
		
		private function enterFrameHandler(event:Event):void {
			_context3D.clear(0, 0, 0);
			
			// clear texture before first use
			_context3D.setRenderToTexture(_depthTargetB, true);
			_context3D.clear(0, 0, 0, 0);
			
			_context3D.setRenderToTexture(_layerTargetB, true);
			_context3D.clear(0, 0, 0, 0);
			
			var numPeels:uint = 4;
			for (var i:uint = 0; i < numPeels; i++) {
				writeDepth(_depthTargetA, _depthTargetB);
				mergeDepths(_depthTargetA, _depthTargetB, _depthTargetC);
				
				// swap textures
				var temp:RectangleTexture = _depthTargetB;
				_depthTargetB = _depthTargetC;
				_depthTargetC = temp;
				
				drawLayer(_depthTargetA, _layerTargetA);
				
				mergeLayers(_layerTargetA, _layerTargetB, _layerTargetC);
				
				temp = _layerTargetB;
				_layerTargetB = _layerTargetC;
				_layerTargetC = temp;
			}
			
			readLayer(_layerTargetB);
			
			_context3D.present();
		}
		
		/**
		 * Writes depth which is closest depth to current depth in buffer. First time depth is 0,
		 * so every fragment, closest to camera, will be written (Context3DCompareMode.LESS).
		 * Next time if fragment have depth less than current depth in buffer it will be discaded.
		 * @param	destDepthTexture
		 * @param	currDepthTexture
		 */
		private function writeDepth(destDepthTexture:TextureBase, currDepthTexture:TextureBase):void {
			_context3D.setRenderToTexture(destDepthTexture, true);
			_context3D.clear(0, 0, 0, 0);
			
			_context3D.setDepthTest(true, Context3DCompareMode.LESS);
			_context3D.setProgram(_programWriteDepth32);
			
			_context3D.setTextureAt(0, currDepthTexture);
			_context3D.setSamplerStateAt(0, Context3DWrapMode.CLAMP, Context3DTextureFilter.NEAREST, Context3DMipFilter.MIPNONE);
			_context3D.setTextureAt(1, null);
			
			_context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, Vector.<Number>([1, 0.5, 0, 0]));
			_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([1, 1 / 255, 1 / 65025, 1 / 160581375]));
			_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, Vector.<Number>([0.001, 0, 0, 0]));
			_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, Vector.<Number>([1, 255, 65025, 160581375]));
			_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 3, Vector.<Number>([1 / 255, 1 / 255, 1 / 255, 0]));
			
			_context3D.setVertexBufferAt(1, null);
			
			_context3D.setVertexBufferAt(0, _quadVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 1, _matrix1, true);
			_context3D.drawTriangles(_indexBuffer);
			
			_context3D.setVertexBufferAt(0, _quadVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 1, _matrix2, true);
			_context3D.drawTriangles(_indexBuffer);
			
			_context3D.setVertexBufferAt(0, _quadVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 1, _matrix3, true);
			_context3D.drawTriangles(_indexBuffer);
			
			_context3D.setVertexBufferAt(0, _quadVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 1, _matrix4, true);
			_context3D.drawTriangles(_indexBuffer);
		}
		
		/**
		 * Merges depths. Takes two textures with depths and leaves only fragment with greater depth.
		 * @param	newDepthTexture
		 * @param	oldDepthTexture
		 * @param	mergedDepthTexture
		 */
		private function mergeDepths(newDepthTexture:TextureBase, oldDepthTexture:TextureBase, mergedDepthTexture:TextureBase):void {
			_context3D.setRenderToTexture(mergedDepthTexture, true);
			_context3D.clear(0, 0, 0, 0);
			
			_context3D.setDepthTest(true, Context3DCompareMode.LESS);
			_context3D.setProgram(_programMergeDepths);
			
			_context3D.setTextureAt(0, oldDepthTexture);
			_context3D.setSamplerStateAt(0, Context3DWrapMode.CLAMP, Context3DTextureFilter.NEAREST, Context3DMipFilter.MIPNONE);
			
			_context3D.setTextureAt(1, newDepthTexture);
			_context3D.setSamplerStateAt(0, Context3DWrapMode.CLAMP, Context3DTextureFilter.NEAREST, Context3DMipFilter.MIPNONE);
			
			_context3D.setVertexBufferAt(0, _quadVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			_context3D.setVertexBufferAt(1, _quadUvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			
			_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([1, 1 / 255, 1 / 65025, 1 / 160581375]));
			_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, Vector.<Number>([0.001, 0, 0, 0]));
			
			_context3D.drawTriangles(_indexBuffer);
		}
		
		/**
		 * Renders geometry and compare depths - if depth is equal to the depth in depth buffer - draw it. Otherwise - discard.
		 * @param	depthTexture
		 * @param	layerTexture
		 */
		private function drawLayer(depthTexture:TextureBase, layerTexture:TextureBase):void {
			_context3D.setRenderToTexture(layerTexture, true);
			_context3D.clear(0, 0, 0, 0);
			
			_context3D.setDepthTest(false, Context3DCompareMode.ALWAYS);
			_context3D.setProgram(_programDrawLayer);
			
			_context3D.setTextureAt(0, depthTexture);
			_context3D.setSamplerStateAt(0, Context3DWrapMode.CLAMP, Context3DTextureFilter.NEAREST, Context3DMipFilter.MIPNONE);
			_context3D.setTextureAt(1, null);
			
			_context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, Vector.<Number>([1, 0.5, 0, 0]));
			_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([1, 1 / 255, 1 / 65025, 1 / 160581375]));
			_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, Vector.<Number>([0.001, 0, 0, 0]));
			
			_context3D.setVertexBufferAt(1, null);
			
			_context3D.setVertexBufferAt(0, _quadVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 1, _matrix1, true);
			_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, Vector.<Number>([1, 0, 0, _alphaBySliderIndex[1]]));
			_context3D.drawTriangles(_indexBuffer);
			
			_context3D.setVertexBufferAt(0, _quadVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 1, _matrix2, true);
			_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, Vector.<Number>([0, 1, 0, _alphaBySliderIndex[2]]));
			_context3D.drawTriangles(_indexBuffer);
			
			_context3D.setVertexBufferAt(0, _quadVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 1, _matrix3, true);
			_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, Vector.<Number>([0, 0, 1, _alphaBySliderIndex[3]]));
			_context3D.drawTriangles(_indexBuffer);
			
			_context3D.setVertexBufferAt(0, _quadVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 1, _matrix4, true);
			_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, Vector.<Number>([1, 1, 0, _alphaBySliderIndex[4]]));
			_context3D.drawTriangles(_indexBuffer);
		}
		
		/**
		 * Blends new layer (farthest layer) and existing layers.
		 * @param	newLayer
		 * @param	oldLayers
		 * @param	destination
		 */
		private function mergeLayers(newLayer:TextureBase, oldLayers:TextureBase, destination:TextureBase):void {
			_context3D.setRenderToTexture(destination, true);
			_context3D.clear(0, 0, 0, 0);
			
			_context3D.setDepthTest(false, Context3DCompareMode.ALWAYS);
			_context3D.setProgram(_programMergeLayers);
			
			_context3D.setTextureAt(0, newLayer);
			_context3D.setSamplerStateAt(0, Context3DWrapMode.CLAMP, Context3DTextureFilter.NEAREST, Context3DMipFilter.MIPNONE);
			_context3D.setTextureAt(1, oldLayers);
			_context3D.setSamplerStateAt(0, Context3DWrapMode.CLAMP, Context3DTextureFilter.NEAREST, Context3DMipFilter.MIPNONE);
			
			_context3D.setVertexBufferAt(0, _quadVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			_context3D.setVertexBufferAt(1, _quadUvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			
			_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([1, 0.05, 0, 0]));
			
			_context3D.drawTriangles(_indexBuffer);
		}
		
		/**
		 * Simply draws texture to screen.
		 * @param	layerTexture
		 */
		private function readLayer(layerTexture:TextureBase):void {
			_context3D.setRenderToBackBuffer();
			_context3D.clear(0, 0, 0);
			
			_context3D.setProgram(_programReadLayer);
			
			_context3D.setVertexBufferAt(0, _quadVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			_context3D.setVertexBufferAt(1, _quadUvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			_context3D.setTextureAt(0, layerTexture);
			_context3D.setSamplerStateAt(0, Context3DWrapMode.CLAMP, Context3DTextureFilter.NEAREST, Context3DMipFilter.MIPNONE);
			_context3D.setTextureAt(1, null);
			_context3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
			_context3D.drawTriangles(_indexBuffer);
			_context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
		}
	}
}