using nri.sampleFramework.SDL;
using System;
using System.IO;
using StbImageBeef;
using System.Collections;
using System.Diagnostics;
using nri.Helpers;
using nri;
using Detex;
namespace nri.sampleTriangle;

internal static
{
	public static SPIRVBindingOffsets SPIRV_BINDING_OFFSETS = .()
		{
			samplerOffset = 100,
			textureOffset = 200,
			constantBufferOffset = 300,
			storageTextureAndBufferOffset = 400
		};
	public const bool D3D11_COMMANDBUFFER_EMULATION = false;
	public const uint32 DEFAULT_MEMORY_ALIGNMENT = 16;
	public const uint32 BUFFERED_FRAME_MAX_NUM = 2;
	public const uint32 SWAP_CHAIN_TEXTURE_NUM = BUFFERED_FRAME_MAX_NUM;

	public static Color<float> COLOR_0 = .() { r = 1.0f, g = 1.0f, b = 0.0f, a = 1.0f };
	public static Color<float> COLOR_1 = .() { r = 0.46f, g = 0.72f, b = 0.0f, a = 1.0f };


	public static Vertex[] g_VertexData =
		new .(
		.()
		{
			position = .(-0.71f, -0.50f),
			uv = .(0.0f, 0.0f)
		},
			.()
		{
			position = .(0.00f,  0.71f),
			uv = .(1.0f, 1.0f)
		},
			.()
		{
			position = .(0.71f, -0.50f),
			uv = .(0.0f, 1.0f)
		}) ~ delete _;

	public static uint16[?] g_IndexData = .(0, 1, 2);

	public static Result<void> LoadTexture(StringView path, ref TextureResource texture)
	{
		FileStream fs = scope FileStream();
		fs.Open(path, .Open, .Read);
		ImageResult image = ImageResult.FromStream(fs, ColorComponents.RedGreenBlueAlpha);

		Format format = .UNKNOWN;
		switch (image.Comp) {
		case .Default:
			break;
		case .Grey:
			format = .R8_UNORM;
			break;
		case .GreyAlpha:
			format = .RG8_UNORM;
			break;
		case .RedGreenBlue:
			format = .RGBA8_UNORM;
			break;
		case .RedGreenBlueAlpha:
			format = .RGBA8_UNORM;
			break;
		}

		texture.image = image;
		texture.data = image.Data;
		texture.avgColor = .();
		texture.hash = 100;
		texture.alphaMode = .OPAQUE;
		texture.format = format;
		texture.width = (.)image.Width;
		texture.height = (.)image.Height;
		texture.depth = 1;
		texture.mipNum = 1;
		texture.arraySize = 1;

		return .();
	}

	public static uint64 ComputeHash(void* key, uint32 len)
	{
		var len;
		/*readonly*/ uint8* p = (uint8*)key;
		uint64 result = 14695981039346656037uL;
		while (len-- > 0)
			result = (result ^ (*p++)) * 1099511628211uL;

		return result;
	}

	struct FormatMapping : this(uint32 detexFormat, Format nriFormat);

	private const FormatMapping[?] formatTable = .( // Uncompressed formats.
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_RGB8, Format.UNKNOWN),
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_RGBA8, Format.RGBA8_UNORM),
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_R8, Format.R8_UNORM),
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_SIGNED_R8, Format.R8_SNORM),
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_RG8, Format.RG8_UNORM),
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_SIGNED_RG8, Format.RG8_SNORM),
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_R16, Format.R16_UNORM),
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_SIGNED_R16, Format.R16_SNORM),
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_RG16, Format.RG16_UNORM),
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_SIGNED_RG16, Format.RG16_SNORM),
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_RGB16, Format.UNKNOWN),
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_RGBA16, Format.RGBA16_UNORM),
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_FLOAT_R16, Format.R16_SFLOAT),
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_FLOAT_RG16, Format.RG16_SFLOAT),
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_FLOAT_RGB16, Format.UNKNOWN),
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_FLOAT_RGBA16, Format.RGBA16_SFLOAT),
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_FLOAT_R32, Format.R32_SFLOAT),
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_FLOAT_RG32, Format.RG32_SFLOAT),
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_FLOAT_RGB32, Format.RGB32_SFLOAT),
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_FLOAT_RGBA32, Format.RGBA32_SFLOAT),
		.((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_A8, Format.UNKNOWN), // Compressed formats.
		.((.)DETEX_TEXTURE_FORMAT.DETEX_TEXTURE_FORMAT_BC1, Format.BC1_RGBA_UNORM),
		.((.)DETEX_TEXTURE_FORMAT.DETEX_TEXTURE_FORMAT_BC1A, Format.UNKNOWN),
		.((.)DETEX_TEXTURE_FORMAT.DETEX_TEXTURE_FORMAT_BC2, Format.BC2_RGBA_UNORM),
		.((.)DETEX_TEXTURE_FORMAT.DETEX_TEXTURE_FORMAT_BC3, Format.BC3_RGBA_UNORM),
		.((.)DETEX_TEXTURE_FORMAT.DETEX_TEXTURE_FORMAT_RGTC1, Format.BC4_R_UNORM),
		.((.)DETEX_TEXTURE_FORMAT.DETEX_TEXTURE_FORMAT_SIGNED_RGTC1, Format.BC4_R_SNORM),
		.((.)DETEX_TEXTURE_FORMAT.DETEX_TEXTURE_FORMAT_RGTC2, Format.BC5_RG_UNORM),
		.((.)DETEX_TEXTURE_FORMAT.DETEX_TEXTURE_FORMAT_SIGNED_RGTC2, Format.BC5_RG_SNORM),
		.((.)DETEX_TEXTURE_FORMAT.DETEX_TEXTURE_FORMAT_BPTC_FLOAT, Format.BC6H_RGB_UFLOAT),
		.((.)DETEX_TEXTURE_FORMAT.DETEX_TEXTURE_FORMAT_BPTC_SIGNED_FLOAT, Format.BC6H_RGB_SFLOAT),
		.((.)DETEX_TEXTURE_FORMAT.DETEX_TEXTURE_FORMAT_BPTC, Format.BC7_RGBA_UNORM),
		.((.)DETEX_TEXTURE_FORMAT.DETEX_TEXTURE_FORMAT_ETC1, Format.UNKNOWN),
		.((.)DETEX_TEXTURE_FORMAT.DETEX_TEXTURE_FORMAT_ETC2, Format.UNKNOWN),
		.((.)DETEX_TEXTURE_FORMAT.DETEX_TEXTURE_FORMAT_ETC2_PUNCHTHROUGH, Format.UNKNOWN),
		.((.)DETEX_TEXTURE_FORMAT.DETEX_TEXTURE_FORMAT_ETC2_EAC, Format.UNKNOWN),
		.((.)DETEX_TEXTURE_FORMAT.DETEX_TEXTURE_FORMAT_EAC_R11, Format.UNKNOWN),
		.((.)DETEX_TEXTURE_FORMAT.DETEX_TEXTURE_FORMAT_EAC_SIGNED_R11, Format.UNKNOWN),
		.((.)DETEX_TEXTURE_FORMAT.DETEX_TEXTURE_FORMAT_EAC_RG11, Format.UNKNOWN),
		.((.)DETEX_TEXTURE_FORMAT.DETEX_TEXTURE_FORMAT_EAC_SIGNED_RG11, Format.UNKNOWN)
		);

	public static Format GetFormatNRI(uint32 detexFormat)
	{
		for (var entry in ref formatTable)
		{
			if (entry.detexFormat == detexFormat)
				return entry.nriFormat;
		}

		return Format.UNKNOWN;
	}

	public static Result<void> LoadTexture(StringView path, DetexTextureResource texture, bool computeAvgColorAndAlphaMode = false)
	{
		detexTexture** dTexture = null;
		int32 mipNum = 0;

		if (!Detex.detexLoadTextureFileWithMipmaps(path.ToScopeCStr!(), 32, &dTexture, &mipNum))
		{
			Debug.WriteLine("ERROR: Can't load texture '{}'", path);

			return .Err;
		}

		texture.texture = dTexture;
		texture.name.Set(path);
		texture.hash = ComputeHash(path.ToScopeCStr!(), (uint32)path.Length);
		texture.format = GetFormatNRI(dTexture[0].format);
		texture.width = (uint16)dTexture[0].width;
		texture.height = (uint16)dTexture[0].height;
		texture.mipNum = (uint16)mipNum;

		// TODO: detex doesn't support cubemaps and 3D textures
		texture.arraySize = 1;
		texture.depth = 1;

		texture.alphaMode = AlphaMode.OPAQUE;
		if (computeAvgColorAndAlphaMode)
		{
			// Alpha mode
			if (texture.format == nri.Format.BC1_RGBA_UNORM || texture.format == nri.Format.BC1_RGBA_SRGB)
			{
				bool hasTransparency = false;
				for (int i = mipNum - 1; i >= 0 && !hasTransparency; i--)
				{
					readonly uint size = Detex.detexTextureSize((.)dTexture[i].width_in_blocks, (.)dTexture[i].height_in_blocks, dTexture[i].format);
					/*readonly*/ uint8* bc1 = dTexture[i].data;

					for (uint j = 0; j < size && !hasTransparency; j += 8)
					{
						readonly uint16* c = (uint16*)bc1;
						if (c[0] <= c[1])
						{
							readonly uint32 bits = *(uint32*)(bc1 + 4);
							for (uint32 k = 0; k < 32 && !hasTransparency; k += 2)
								hasTransparency = ((bits >> k) & 0x3) == 0x3;
						}
						bc1 += 8;
					}
				}

				if (hasTransparency)
					texture.alphaMode = AlphaMode.PREMULTIPLIED;
			}

			// Decompress last mip
			List<uint8> image = scope .();
			detexTexture* lastMip = dTexture[mipNum - 1];
			uint8* rgba8 = lastMip.data;
			if (lastMip.format != (.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_RGBA8)
			{
				image.Resize(lastMip.width * lastMip.height * (.)Detex.detexGetPixelSize((.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_RGBA8));
				// Converts to RGBA8 if the texture is not compressed
				Detex.detexDecompressTextureLinear(lastMip, image.Ptr, (.)DETEX_PIXEL_FORMAT.DETEX_PIXEL_FORMAT_RGBA8);
				rgba8 = image.Ptr;
			}

			// Average color
			ColorRGBA avgColor = .();
			readonly int pixelNum = lastMip.width * lastMip.height;
			for (int i = 0; i < pixelNum; i++)
				avgColor = avgColor + ColorRGBA.FromRgba(*(uint32*)(rgba8 + i * 4));

			avgColor = (avgColor / (float)pixelNum);
			texture.avgColor = avgColor;

			if (texture.alphaMode != AlphaMode.PREMULTIPLIED && avgColor.r < 254.5f / 255.0f)
				texture.alphaMode = avgColor.r == 0.0f ? AlphaMode.OFF : AlphaMode.TRANSPARENT;

			// Useful to find a texture which is TRANSPARENT but needs to be OPAQUE or PREMULTIPLIED
			/*if (texture.alphaMode == AlphaMode.TRANSPARENT || texture.alphaMode == AlphaMode.OFF)
			{
				char s[1024];
				sprintf(s, "%s: %s\n", texture.alphaMode == AlphaMode.OFF ? "OFF" : "TRANSPARENT", path.c_str());
				OutputDebugStringA(s);
			}*/
		}

		return .Ok;
	}
}

struct BackBuffer
{
	public FrameBuffer frameBuffer;
	public Descriptor colorAttachment;
	public Texture texture;
}

struct Frame
{
	public DeviceSemaphore deviceSemaphore;
	public CommandAllocator commandAllocator;
	public CommandBuffer commandBuffer;
	public Descriptor constantBufferView;
	public DescriptorSet constantBufferDescriptorSet;
	public uint64 constantBufferViewOffset;
}

[CRepr]
struct ConstantBufferLayout
{
	public float[3] color;
	public float scale;
}

[CRepr]
struct Vertex
{
	public float[2] position;
	public float[2] uv;
}

class TriangleApplication : SDLApplication
{
	private const GraphicsAPI GraphicsAPI = .VULKAN;

	private Device mDevice = null;

	private SwapChain mSwapChain = null;
	private CommandQueue mCommandQueue = null;
	private QueueSemaphore mAcquireSemaphore = null;
	private QueueSemaphore mReleaseSemaphore = null;

	private DescriptorPool m_DescriptorPool = null;
	private PipelineLayout m_PipelineLayout = null;
	private Pipeline m_Pipeline = null;
	private DescriptorSet m_TextureDescriptorSet = null;
	private Descriptor m_TextureShaderResource = null;
	private Descriptor m_Sampler = null;
	private Buffer m_ConstantBuffer = null;
	private Buffer m_GeometryBuffer = null;
	private Texture m_Texture = null;

	private Frame[BUFFERED_FRAME_MAX_NUM] mFrames = .();
	private List<BackBuffer> mSwapChainBuffers = new .() ~ delete _;

	private List<Memory> m_MemoryAllocations = new .() ~ delete _;

	private uint64 m_GeometryOffset = 0;
	private float m_Transparency = 1.0f;
	private float m_Scale = 1.0f;

	private uint32 mSwapInterval = 0;

	private uint32 mFrameNum = uint32.MaxValue;

	public this(System.String windowTitle, uint windowWidth, uint windowHeight) : base(windowTitle, windowWidth, windowHeight)
	{
	}

	protected override Result<void> OnStartup()
	{
		if (base.OnStartup() case .Err)
			return .Err;

		DeviceCreationDesc deviceDesc = .()
			{
				graphicsAPI = GraphicsAPI,
				enableAPIValidation = true,
				enableNRIValidation = false,
				D3D11CommandBufferEmulation = D3D11_COMMANDBUFFER_EMULATION,
				spirvBindingOffsets = SPIRV_BINDING_OFFSETS
			};

		Result result = .SUCCESS;

		if (GraphicsAPI == .VULKAN)
		{
			result = nri.vulkan.CreateDeviceVK(deviceDesc, out mDevice);
		} else if (GraphicsAPI == .D3D12)
		{
			result = nri.d3d12.CreateDeviceD3D12(deviceDesc, out mDevice);
		} else
		{
			Runtime.FatalError(scope $"GraphicsAPI {GraphicsAPI} is not supported.");
		}

		if (result != .SUCCESS)
		{
			Debug.WriteLine("Failed to create Device");
			return .Err;
		}

		return .Ok;
	}

	protected override void OnShutdown()
	{
		if (mDevice != null)
		{
			if (GraphicsAPI == .VULKAN)
			{
				nri.vulkan.DestroyDeviceVK(mDevice);
			} else if (GraphicsAPI == .D3D12)
			{
				nri.d3d12.DestroyDeviceD3D12(mDevice);
			} else
			{
				Runtime.FatalError(scope $"GraphicsAPI {GraphicsAPI} is not supported.");
			}
			mDevice = null;
		}

		base.OnShutdown();
	}

	protected override Result<void> OnInitialize()
	{
		if (base.OnInitialize() case .Err)
			return .Err;

		var result = mDevice.GetCommandQueue(.GRAPHICS, out mCommandQueue);
		if (result != .SUCCESS)
			return .Err;

		ShaderCompiler compiler = scope .();

		List<uint8> fragmentShaderByteCode = scope .();

		ShaderCompilerOutputType outputType = GraphicsAPI == .VULKAN ? .SPIRV : .DXIL;

		Result<void> compileResult = compiler.CompileShader(.()
			{
				shaderPath = "shaders/Triangle.fs.hlsl",
				shaderStage = .FRAGMENT,
				shaderModel = "6_5",
				entryPoint = "main",
				outputType = outputType,
				spirvBindingOffsets = SPIRV_BINDING_OFFSETS
			}, fragmentShaderByteCode);

		if (compileResult case .Err)
		{
			return .Err;
		}

		List<uint8> vertexShaderByteCode = scope .();

		compileResult = compiler.CompileShader(.()
			{
				shaderPath = "shaders/Triangle.vs.hlsl",
				shaderStage = .VERTEX,
				shaderModel = "6_5",
				entryPoint = "main",
				outputType = outputType,
				spirvBindingOffsets = SPIRV_BINDING_OFFSETS
			}, vertexShaderByteCode);

		if (compileResult case .Err)
		{
			return .Err;
		}

		// Swap chain
		Format swapChainFormat = default;
		{
			SwapChainDesc swapChainDesc = .();
			swapChainDesc.windowSystemType = .WINDOWS;
			swapChainDesc.window = .()
				{
					windows = WindowsWindow()
						{
							hwnd = Window.SurfaceInfo.windows.hwnd
						}
				};
			swapChainDesc.commandQueue = mCommandQueue;
			swapChainDesc.format = SwapChainFormat.BT709_G22_8BIT;
			swapChainDesc.verticalSyncInterval = mSwapInterval;
			swapChainDesc.width = (.)Window.Width;
			swapChainDesc.height = (.)Window.Height;
			swapChainDesc.textureNum = SWAP_CHAIN_TEXTURE_NUM;
			result = mDevice.CreateSwapChain(swapChainDesc, out mSwapChain);
			if (result != .SUCCESS)
				return .Err;

			uint32 swapChainTextureNum = 0;
			Texture* swapChainTextures = mSwapChain.GetTextures(ref swapChainTextureNum, ref swapChainFormat);

			for (uint32 i = 0; i < swapChainTextureNum; i++)
			{
				Texture2DViewDesc textureViewDesc = .() { texture = swapChainTextures[i], viewType = Texture2DViewType.COLOR_ATTACHMENT, format = swapChainFormat };

				Descriptor colorAttachment = null;
				result = mDevice.CreateTexture2DView(textureViewDesc, out colorAttachment);

				ClearValueDesc clearColor = .();
				clearColor.rgba32f = COLOR_0;

				FrameBufferDesc frameBufferDesc = .()
					{
						colorAttachmentNum = 1,
						colorAttachments = &colorAttachment,
						colorClearValues = &clearColor
					};
				FrameBuffer frameBuffer = null;
				result = mDevice.CreateFrameBuffer(frameBufferDesc, out frameBuffer);

				readonly BackBuffer backBuffer = .() { frameBuffer = frameBuffer, colorAttachment =  colorAttachment, texture = swapChainTextures[i] };
				mSwapChainBuffers.Add(backBuffer);
			}
		}

		result = mDevice.CreateQueueSemaphore(out mAcquireSemaphore);
		if (result != .SUCCESS)
			return .Err;
		result = mDevice.CreateQueueSemaphore(out mReleaseSemaphore);
		if (result != .SUCCESS)
			return .Err;

		// Buffered resources
		for (ref Frame frame in ref mFrames)
		{
			result = mDevice.CreateDeviceSemaphore(true, out frame.deviceSemaphore);
			result = mDevice.CreateCommandAllocator(mCommandQueue, WHOLE_DEVICE_GROUP, out frame.commandAllocator);
			result = frame.commandAllocator.CreateCommandBuffer(out frame.commandBuffer);
		}

		// Pipeline
		readonly ref DeviceDesc deviceDesc = ref mDevice.GetDesc();
		{
			DescriptorRangeDesc[1] descriptorRangeConstant = .();
			descriptorRangeConstant[0] = .() { baseRegisterIndex = 0, descriptorNum = 1, descriptorType = DescriptorType.CONSTANT_BUFFER, visibility = ShaderStage.ALL };

			DescriptorRangeDesc[2] descriptorRangeTexture = .();
			descriptorRangeTexture[0] = .() { baseRegisterIndex = 0, descriptorNum = 1, descriptorType = DescriptorType.TEXTURE, visibility = ShaderStage.FRAGMENT };
			descriptorRangeTexture[1] = .() { baseRegisterIndex = 0, descriptorNum = 1, descriptorType = DescriptorType.SAMPLER, visibility = ShaderStage.FRAGMENT };

			DescriptorSetDesc[] descriptorSetDescs = scope:: .
				(
				.() { ranges = &descriptorRangeConstant, rangeNum = descriptorRangeConstant.Count },
				.() { ranges = &descriptorRangeTexture, rangeNum = descriptorRangeTexture.Count }
				);

			PushConstantDesc pushConstant = .() { registerIndex = 1, size = sizeof(float), visibility = ShaderStage.FRAGMENT };

			PipelineLayoutDesc pipelineLayoutDesc = .();
			pipelineLayoutDesc.descriptorSetNum = (.)descriptorSetDescs.Count;
			pipelineLayoutDesc.descriptorSets = descriptorSetDescs.Ptr;
			pipelineLayoutDesc.pushConstantNum = 1;
			pipelineLayoutDesc.pushConstants = &pushConstant;
			pipelineLayoutDesc.stageMask = PipelineLayoutShaderStageBits.VERTEX | PipelineLayoutShaderStageBits.FRAGMENT;

			result = mDevice.CreatePipelineLayout(pipelineLayoutDesc, out m_PipelineLayout);
			if (result != .SUCCESS)
				return .Err;

			VertexStreamDesc vertexStreamDesc = .();
			vertexStreamDesc.bindingSlot = 0;
			vertexStreamDesc.stride = sizeof(Vertex);

			VertexAttributeDesc[2] vertexAttributeDesc = .();
			{
				vertexAttributeDesc[0].format = Format.RG32_SFLOAT;
				vertexAttributeDesc[0].streamIndex = 0;
				vertexAttributeDesc[0].offset = offsetof(Vertex, position);
				vertexAttributeDesc[0].d3d = .() { semanticName = "POSITION", semanticIndex = 0 };
				vertexAttributeDesc[0].vk.location = 0;

				vertexAttributeDesc[1].format = Format.RG32_SFLOAT;
				vertexAttributeDesc[1].streamIndex = 0;
				vertexAttributeDesc[1].offset = offsetof(Vertex, uv);
				vertexAttributeDesc[1].d3d = .() { semanticName = "TEXCOORD", semanticIndex = 0 };
				vertexAttributeDesc[1].vk.location = 1;
			}

			InputAssemblyDesc inputAssemblyDesc = .();
			inputAssemblyDesc.topology = Topology.TRIANGLE_LIST;
			inputAssemblyDesc.attributes = &vertexAttributeDesc;
			inputAssemblyDesc.attributeNum = (uint8)vertexAttributeDesc.Count;
			inputAssemblyDesc.streams = &vertexStreamDesc;
			inputAssemblyDesc.streamNum = 1;

			RasterizationDesc rasterizationDesc = .();
			rasterizationDesc.viewportNum = 1;
			rasterizationDesc.fillMode = FillMode.SOLID;
			rasterizationDesc.cullMode = CullMode.NONE;
			rasterizationDesc.sampleNum = 1;
			rasterizationDesc.sampleMask = 0xFFFF;

			ColorAttachmentDesc colorAttachmentDesc = .();
			colorAttachmentDesc.format = swapChainFormat;
			colorAttachmentDesc.colorWriteMask = ColorWriteBits.RGBA;
			colorAttachmentDesc.blendEnabled = true;
			colorAttachmentDesc.colorBlend = .() { srcFactor = BlendFactor.SRC_ALPHA, dstFactor = BlendFactor.ONE_MINUS_SRC_ALPHA, func = BlendFunc.ADD };

			OutputMergerDesc outputMergerDesc = .();
			outputMergerDesc.colorNum = 1;
			outputMergerDesc.color = &colorAttachmentDesc;



			ShaderDesc[] shaderStages = scope:: .(
				.()
				{
					stage = .VERTEX,
					bytecode = vertexShaderByteCode.Ptr,
					size = (.)vertexShaderByteCode.Count,
					entryPointName = null
				},
					.()
				{
					stage = .FRAGMENT,
					bytecode = fragmentShaderByteCode.Ptr,
					size = (.)fragmentShaderByteCode.Count,
					entryPointName = null
				}
					);

			GraphicsPipelineDesc graphicsPipelineDesc = .();
			graphicsPipelineDesc.pipelineLayout = m_PipelineLayout;
			graphicsPipelineDesc.inputAssembly = &inputAssemblyDesc;
			graphicsPipelineDesc.rasterization = &rasterizationDesc;
			graphicsPipelineDesc.outputMerger = &outputMergerDesc;
			graphicsPipelineDesc.shaderStages = shaderStages.Ptr;
			graphicsPipelineDesc.shaderStageNum = (.)shaderStages.Count;

			result = mDevice.CreateGraphicsPipeline(graphicsPipelineDesc, out m_Pipeline);
			if (result != .SUCCESS)
				return .Err;
		}

		// Descriptor pool
		{
			DescriptorPoolDesc descriptorPoolDesc = .();
			descriptorPoolDesc.descriptorSetMaxNum = BUFFERED_FRAME_MAX_NUM + 1;
			descriptorPoolDesc.constantBufferMaxNum = BUFFERED_FRAME_MAX_NUM;
			descriptorPoolDesc.textureMaxNum = 1;
			descriptorPoolDesc.samplerMaxNum = 1;

			result =  mDevice.CreateDescriptorPool(descriptorPoolDesc, out m_DescriptorPool);
			if (result != .SUCCESS)
				return .Err;
		}

		// Load texture
		DetexTextureResource texture = new .();
		if (LoadTexture("images/wood.dds", texture) case .Err)
			return .Err;

		defer delete texture;

		// Resources
		readonly uint32 constantBufferSize = (.)Math.Align((uint32)sizeof(ConstantBufferLayout), deviceDesc.constantBufferOffsetAlignment);
		readonly uint64 indexDataSize = sizeof(decltype(g_IndexData[0])) * g_IndexData.Count;
		readonly uint64 indexDataAlignedSize = (.)Math.Align((.)indexDataSize, 16);
		readonly uint64 vertexDataSize = (.)sizeof(decltype(g_VertexData[0])) * (.)g_VertexData.Count;
		{
			// Texture
			TextureDesc textureDesc = CTextureDesc.Texture2D(texture.GetFormat(),
				texture.GetWidth(), texture.GetHeight(), texture.GetMipNum());
			result = mDevice.CreateTexture(textureDesc, out m_Texture);

			// Constant buffer
			{
				BufferDesc bufferDesc = .();
				bufferDesc.size = constantBufferSize * BUFFERED_FRAME_MAX_NUM;
				bufferDesc.usageMask = BufferUsageBits.CONSTANT_BUFFER;
				result =  mDevice.CreateBuffer(bufferDesc, out m_ConstantBuffer);
				if (result != .SUCCESS)
					return .Err;
			}

			// Geometry buffer
			{
				BufferDesc bufferDesc = .();
				bufferDesc.size = indexDataAlignedSize + vertexDataSize;
				bufferDesc.usageMask = BufferUsageBits.VERTEX_BUFFER | BufferUsageBits.INDEX_BUFFER;
				result = mDevice.CreateBuffer(bufferDesc, out m_GeometryBuffer);
				if (result != .SUCCESS)
					return .Err;
			}
			m_GeometryOffset = indexDataAlignedSize;
		}

		ResourceGroupDesc resourceGroupDesc = .();
		resourceGroupDesc.memoryLocation = MemoryLocation.HOST_UPLOAD;
		resourceGroupDesc.bufferNum = 1;
		resourceGroupDesc.buffers = &m_ConstantBuffer;

		m_MemoryAllocations.Resize(1, null);
		result = mDevice.AllocateAndBindMemory(resourceGroupDesc, m_MemoryAllocations.Ptr);
		if (result != .SUCCESS)
			return .Err;

		resourceGroupDesc.memoryLocation = MemoryLocation.DEVICE;
		resourceGroupDesc.bufferNum = 1;
		resourceGroupDesc.buffers = &m_GeometryBuffer;
		resourceGroupDesc.textureNum = 1;
		resourceGroupDesc.textures = &m_Texture;

		m_MemoryAllocations.Resize(1 + mDevice.CalculateAllocationNumber(resourceGroupDesc), null);
		result = mDevice.AllocateAndBindMemory(resourceGroupDesc, m_MemoryAllocations.Ptr + 1);
		if (result != .SUCCESS)
			return .Err;

		// Descriptors
		{
			// Texture
			Texture2DViewDesc texture2DViewDesc = .() { texture = m_Texture, viewType = Texture2DViewType.SHADER_RESOURCE_2D, format = texture.GetFormat() };
			result = mDevice.CreateTexture2DView(texture2DViewDesc, out m_TextureShaderResource);

			// Sampler
			SamplerDesc samplerDesc = .();
			samplerDesc.anisotropy = 4;
			samplerDesc.addressModes = .() { u = AddressMode.MIRRORED_REPEAT, v = AddressMode.MIRRORED_REPEAT };
			samplerDesc.minification = Filter.LINEAR;
			samplerDesc.magnification = Filter.LINEAR;
			samplerDesc.mip = Filter.LINEAR;
			samplerDesc.mipMax = 16.0f;
			result = mDevice.CreateSampler(samplerDesc, out m_Sampler);
			if (result != .SUCCESS)
				return .Err;

			// Constant buffer
			for (uint32 i = 0; i < BUFFERED_FRAME_MAX_NUM; i++)
			{
				BufferViewDesc bufferViewDesc = .();
				bufferViewDesc.buffer = m_ConstantBuffer;
				bufferViewDesc.viewType = BufferViewType.CONSTANT;
				bufferViewDesc.offset = i * constantBufferSize;
				bufferViewDesc.size = constantBufferSize;
				result = mDevice.CreateBufferView(bufferViewDesc, out mFrames[i].constantBufferView);
				if (result != .SUCCESS)
					return .Err;

				mFrames[i].constantBufferViewOffset = bufferViewDesc.offset;
			}
		}

		// Descriptor sets
		{

			// Texture
			result = m_DescriptorPool.AllocateDescriptorSets(m_PipelineLayout, 1, &m_TextureDescriptorSet, 1, WHOLE_DEVICE_GROUP, 0);
			if (result != .SUCCESS)
				return .Err;

			DescriptorRangeUpdateDesc[2] descriptorRangeUpdateDescs = .();
			descriptorRangeUpdateDescs[0].descriptorNum = 1;
			descriptorRangeUpdateDescs[0].descriptors = &m_TextureShaderResource;

			descriptorRangeUpdateDescs[1].descriptorNum = 1;
			descriptorRangeUpdateDescs[1].descriptors = &m_Sampler;
			m_TextureDescriptorSet.UpdateDescriptorRanges(WHOLE_DEVICE_GROUP, 0, descriptorRangeUpdateDescs.Count, &descriptorRangeUpdateDescs);

			// Constant buffer
			for (ref Frame frame in ref mFrames)
			{
				m_DescriptorPool.AllocateDescriptorSets(m_PipelineLayout, 0, &frame.constantBufferDescriptorSet, 1, WHOLE_DEVICE_GROUP, 0);
				if (result != .SUCCESS)
					return .Err;

				DescriptorRangeUpdateDesc descriptorRangeUpdateDesc = .() { descriptors = &frame.constantBufferView, descriptorNum = 1 };
				frame.constantBufferDescriptorSet.UpdateDescriptorRanges(WHOLE_DEVICE_GROUP, 0, 1, &descriptorRangeUpdateDesc);
			}
		}

		// Upload data
		{
			List<uint8> geometryBufferData = scope .() { Count = (.)(indexDataAlignedSize + vertexDataSize) };
			Internal.MemCpy(geometryBufferData.Ptr, &g_IndexData, (.)indexDataSize);
			Internal.MemCpy(&geometryBufferData[(.)indexDataAlignedSize], g_VertexData.Ptr, (.)vertexDataSize);

			TextureSubresourceUploadDesc[16] subresources = .();
			for (uint32 mip = 0; mip < texture.GetMipNum(); mip++)
				texture.GetSubresource(ref subresources[mip], mip);

			TextureUploadDesc textureData = .();
			textureData.subresources = &subresources;
			textureData.mipNum = texture.GetMipNum();
			textureData.arraySize = 1;
			textureData.texture = m_Texture;
			textureData.nextLayout = TextureLayout.SHADER_RESOURCE;
			textureData.nextAccess = AccessBits.SHADER_RESOURCE;

			BufferUploadDesc bufferData = .();
			bufferData.buffer = m_GeometryBuffer;
			bufferData.data = geometryBufferData.Ptr;
			bufferData.dataSize = (.)geometryBufferData.Count;
			bufferData.nextAccess = AccessBits.INDEX_BUFFER | AccessBits.VERTEX_BUFFER;

			result = mCommandQueue.UploadData(&textureData, 1, &bufferData, 1);
			if (result != .SUCCESS)
				return .Err;
		}

		return .Ok;
	}

	protected override void OnFinalize()
	{
		mCommandQueue.WaitForIdle();

		for (ref Frame frame in ref mFrames)
		{
			mDevice.DestroyCommandBuffer(frame.commandBuffer);
			mDevice.DestroyCommandAllocator(frame.commandAllocator);
			mDevice.DestroyDeviceSemaphore(frame.deviceSemaphore);
			mDevice.DestroyDescriptor(frame.constantBufferView);
		}

		for (ref BackBuffer backBuffer in ref mSwapChainBuffers)
		{
			mDevice.DestroyFrameBuffer(backBuffer.frameBuffer);
			mDevice.DestroyDescriptor(backBuffer.colorAttachment);
		}
		mDevice.DestroyPipeline(m_Pipeline);
		mDevice.DestroyPipelineLayout(m_PipelineLayout);
		mDevice.DestroyDescriptor(m_TextureShaderResource);
		mDevice.DestroyDescriptor(m_Sampler);
		mDevice.DestroyBuffer(m_ConstantBuffer);
		mDevice.DestroyBuffer(m_GeometryBuffer);
		mDevice.DestroyTexture(m_Texture);
		mDevice.DestroyDescriptorPool(m_DescriptorPool);
		mDevice.DestroyQueueSemaphore(mAcquireSemaphore);
		mDevice.DestroyQueueSemaphore(mReleaseSemaphore);
		mDevice.DestroySwapChain(mSwapChain);

		for (Memory memory in m_MemoryAllocations)
			mDevice.FreeMemory(memory);

		base.OnFinalize();
	}

	private void PrepareFrame(uint32 frameIndex)
	{
	}

	private void RenderFrame(uint32 frameIndex)
	{
		readonly uint32 windowWidth = Window.Width;
		readonly uint32 windowHeight = Window.Height;
		readonly uint32 bufferedFrameIndex = frameIndex % BUFFERED_FRAME_MAX_NUM;
		readonly ref Frame frame = ref mFrames[bufferedFrameIndex];

		readonly uint32 backBufferIndex = mSwapChain.AcquireNextTexture(ref mAcquireSemaphore);
		readonly ref BackBuffer backBuffer = ref mSwapChainBuffers[backBufferIndex];

		mCommandQueue.WaitForSemaphore(frame.deviceSemaphore);
		frame.commandAllocator.Reset();

		ConstantBufferLayout* commonConstants = (ConstantBufferLayout*)m_ConstantBuffer.Map(frame.constantBufferViewOffset, sizeof(ConstantBufferLayout));
		if (commonConstants != null)
		{
			commonConstants.color[0] = 0.8f;
			commonConstants.color[1] = 0.5f;
			commonConstants.color[2] = 0.1f;
			commonConstants.scale = m_Scale;

			m_ConstantBuffer.Unmap();
		}

		TextureTransitionBarrierDesc textureTransitionBarrierDesc = .();
		textureTransitionBarrierDesc.texture = backBuffer.texture;
		textureTransitionBarrierDesc.prevAccess = AccessBits.UNKNOWN;
		textureTransitionBarrierDesc.nextAccess = AccessBits.COLOR_ATTACHMENT;
		textureTransitionBarrierDesc.prevLayout = TextureLayout.UNKNOWN;
		textureTransitionBarrierDesc.nextLayout = TextureLayout.COLOR_ATTACHMENT;
		textureTransitionBarrierDesc.arraySize = 1;
		textureTransitionBarrierDesc.mipNum = 1;

		CommandBuffer commandBuffer = frame.commandBuffer;
		commandBuffer.Begin(m_DescriptorPool, 0);
		{
			TransitionBarrierDesc transitionBarriers = .();
			transitionBarriers.textureNum = 1;
			transitionBarriers.textures = &textureTransitionBarrierDesc;
			commandBuffer.PipelineBarrier(&transitionBarriers, null, BarrierDependency.ALL_STAGES);

			commandBuffer.BeginRenderPass(backBuffer.frameBuffer, RenderPassBeginFlag.NONE);
			{
				{
					commandBuffer.BeginAnnotation("Clear");

					uint32 halfWidth = windowWidth / 2;
					uint32 halfHeight = windowHeight / 2;

					ClearDesc clearDesc = .();
					clearDesc.colorAttachmentIndex = 0;
					clearDesc.value.rgba32f = COLOR_1;
					Rect[2] rects = .();
					rects[0] = .() { left =  0, top = 0, width = halfWidth, height = halfHeight };
					rects[1] = .() { left = (int32)halfWidth, top = (int32)halfHeight, width = halfWidth, height = halfHeight };
					commandBuffer.ClearAttachments(&clearDesc, 1, &rects, rects.Count);

					commandBuffer.EndAnnotation();
				}
				{
					commandBuffer.BeginAnnotation("Triangle");

					Viewport viewport = .()
						{
							offset = .(0.0f, 0.0f),
							size = .((float)windowWidth, (float)windowHeight),
							depthRangeMin = 0.0f,
							depthRangeMax = 1.0f
						};
					commandBuffer.SetViewports(&viewport, 1);

					commandBuffer.SetPipelineLayout(m_PipelineLayout);
					commandBuffer.SetPipeline(m_Pipeline);
					commandBuffer.SetConstants(0, &m_Transparency, 4);
					commandBuffer.SetIndexBuffer(m_GeometryBuffer, 0, IndexType.UINT16);
					commandBuffer.SetVertexBuffers(0, 1, &m_GeometryBuffer, &m_GeometryOffset);

					DescriptorSet[2] sets = .(frame.constantBufferDescriptorSet, m_TextureDescriptorSet);
					commandBuffer.SetDescriptorSets(0, sets.Count, &sets, null);

					Rect scissor = .() { left = 0, top = 0, width = windowWidth / 2, height = windowHeight };
					commandBuffer.SetScissors(&scissor, 1);
					commandBuffer.DrawIndexed(3, 1, 0, 0, 0);

					scissor = .() { left = (int32)windowWidth / 2, top = (int32)windowHeight / 2, width = windowWidth / 2, height = windowHeight / 2 };
					commandBuffer.SetScissors(&scissor, 1);
					commandBuffer.Draw(3, 1, 0, 0);

					commandBuffer.EndAnnotation();
				}
			}
			commandBuffer.EndRenderPass();

			textureTransitionBarrierDesc.prevAccess = textureTransitionBarrierDesc.nextAccess;
			textureTransitionBarrierDesc.nextAccess = AccessBits.UNKNOWN;
			textureTransitionBarrierDesc.prevLayout = textureTransitionBarrierDesc.nextLayout;
			textureTransitionBarrierDesc.nextLayout = TextureLayout.PRESENT;

			commandBuffer.PipelineBarrier(&transitionBarriers, null, BarrierDependency.ALL_STAGES);
		}
		commandBuffer.End();

		readonly CommandBuffer[] commandBuffers = scope .(commandBuffer);

		WorkSubmissionDesc workSubmissionDesc = .()
			{
				commandBufferNum = (.)commandBuffers.Count,
				commandBuffers = commandBuffers.Ptr,
				wait = &mAcquireSemaphore,
				waitNum = 1,
				signal = &mReleaseSemaphore,
				signalNum = 1
			};

		mCommandQueue.SubmitWork(workSubmissionDesc, frame.deviceSemaphore);
		mSwapChain.Present(ref mReleaseSemaphore);
	}

	protected override void OnFrameEnd()
	{
		PrepareFrame(mFrameNum);
		RenderFrame(mFrameNum);
		mFrameNum++;
	}
}