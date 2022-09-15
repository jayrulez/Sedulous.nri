using nri.d3dcommon;
using Win32.Graphics.Direct3D12;
using System.Collections;
using Win32.Graphics.Dxgi;
using System.Threading;
using Win32.Graphics.Direct3D;
using Win32.Foundation;
namespace nri.d3d12;

typealias DescriptorPointerCPU = uint;
typealias DescriptorPointerGPU = uint64;
typealias HeapIndexType = uint16;
typealias HeapOffsetType = uint16;

struct DescriptorHandle
{
	public HeapIndexType heapIndex;
	public HeapOffsetType heapOffset;
}

struct DescriptorHeapDesc
{
	public ComPtr<ID3D12DescriptorHeap> descriptorHeap;
	public DescriptorPointerCPU descriptorPointerCPU;
	public DescriptorPointerGPU descriptorPointerGPU;
	public uint32 descriptorSize;
}

public static
{
	public const uint DESCRIPTOR_HEAP_TYPE_NUM = (.)D3D12_DESCRIPTOR_HEAP_TYPE.D3D12_DESCRIPTOR_HEAP_TYPE_NUM_TYPES;
	public const  uint32 DESCRIPTORS_BATCH_SIZE = 1024;
}

class DeviceD3D12 : Device
{
	private Vendor GetVendor(ID3D12Device* device)
	{
		ComPtr<IDXGIFactory4> DXGIFactory = null;
		CreateDXGIFactory(IDXGIFactory4.IID, (void**)(&DXGIFactory));

		DXGI_ADAPTER_DESC desc = .();
		if (DXGIFactory != null)
		{
			LUID luid = device.GetAdapterLuid();

			ComPtr<IDXGIAdapter> adapter = null;
			DXGIFactory.EnumAdapterByLuid(luid, IDXGIAdapter.IID, (void**)(&adapter));
			if (adapter != null)
				adapter.GetDesc(&desc);
		}

		return GetVendorFromID(desc.VendorId);
	}

	private void UpdateDeviceDesc(bool enableValidation)
	{
		D3D12_FEATURE_DATA_D3D12_OPTIONS options = .();
		m_Device.CheckFeatureSupport(.D3D12_FEATURE_D3D12_OPTIONS, &options, sizeof(decltype(options)));

		D3D12_FEATURE_DATA_D3D12_OPTIONS1 options1 = .();
		m_Device.CheckFeatureSupport(.D3D12_FEATURE_D3D12_OPTIONS1, &options1, sizeof(decltype(options)));

		D3D12_FEATURE_DATA_D3D12_OPTIONS2 options2 = .();
		m_Device.CheckFeatureSupport(.D3D12_FEATURE_D3D12_OPTIONS2, &options2, sizeof(decltype(options)));

		D3D12_FEATURE_DATA_D3D12_OPTIONS3 options3 = .();
		m_Device.CheckFeatureSupport(.D3D12_FEATURE_D3D12_OPTIONS3, &options3, sizeof(decltype(options)));

		D3D12_FEATURE_DATA_D3D12_OPTIONS4 options4 = .();
		m_Device.CheckFeatureSupport(.D3D12_FEATURE_D3D12_OPTIONS4, &options4, sizeof(decltype(options)));

		D3D12_FEATURE_DATA_D3D12_OPTIONS5 options5 = .();
		m_Device.CheckFeatureSupport(.D3D12_FEATURE_D3D12_OPTIONS5, &options5, sizeof(decltype(options)));

		D3D12_FEATURE_DATA_D3D12_OPTIONS7 options7 = .();
		m_Device.CheckFeatureSupport(.D3D12_FEATURE_D3D12_OPTIONS7, &options7, sizeof(decltype(options)));

		m_IsRaytracingSupported = options5.RaytracingTier >= .D3D12_RAYTRACING_TIER_1_0;
		m_IsMeshShaderSupported = options7.MeshShaderTier >= .D3D12_MESH_SHADER_TIER_1;

		D3D12_FEATURE_DATA_FEATURE_LEVELS levels = .();
		D3D_FEATURE_LEVEL[4] levelsList = .(
			.D3D_FEATURE_LEVEL_11_0,
			.D3D_FEATURE_LEVEL_11_1,
			.D3D_FEATURE_LEVEL_12_0,
			.D3D_FEATURE_LEVEL_12_1
			);
		levels.NumFeatureLevels = (uint32)levelsList.Count;
		levels.pFeatureLevelsRequested = &levelsList;
		m_Device.CheckFeatureSupport(.D3D12_FEATURE_FEATURE_LEVELS, &levels, sizeof(decltype(levels)));

		uint64 timestampFrequency = 0;

		CommandQueue commandQueue = null;
		readonly Result result = GetCommandQueue(CommandQueueType.GRAPHICS, out commandQueue);

		if (result == Result.SUCCESS)
		{
			ID3D12CommandQueue* commandQueueD3D12 = (CommandQueueD3D12)commandQueue;
			commandQueueD3D12.GetTimestampFrequency(&timestampFrequency);
		}
		else
		{
			REPORT_ERROR(GetLogger(), "Failed to get command queue to update device desc, result: %d.", (int32)result);
		}

		m_DeviceDesc.graphicsAPI = GraphicsAPI.D3D12;
		m_DeviceDesc.vendor = GetVendor(m_Device);
		m_DeviceDesc.nriVersionMajor = 1; //NRI_VERSION_MAJOR;
		m_DeviceDesc.nriVersionMinor = 0; //NRI_VERSION_MINOR;

		m_DeviceDesc.viewportMaxNum = D3D12_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE;
		m_DeviceDesc.viewportSubPixelBits = D3D12_SUBPIXEL_FRACTIONAL_BIT_COUNT;
		m_DeviceDesc.viewportBoundsRange[0] = D3D12_VIEWPORT_BOUNDS_MIN;
		m_DeviceDesc.viewportBoundsRange[1] = D3D12_VIEWPORT_BOUNDS_MAX;

		m_DeviceDesc.frameBufferMaxDim = D3D12_REQ_RENDER_TO_BUFFER_WINDOW_WIDTH;
		m_DeviceDesc.frameBufferLayerMaxNum = D3D12_REQ_TEXTURE2D_ARRAY_AXIS_DIMENSION;
		m_DeviceDesc.framebufferColorAttachmentMaxNum = D3D12_SIMULTANEOUS_RENDER_TARGET_COUNT;

		m_DeviceDesc.frameBufferColorSampleMaxNum = D3D12_MAX_MULTISAMPLE_SAMPLE_COUNT;
		m_DeviceDesc.frameBufferDepthSampleMaxNum = D3D12_MAX_MULTISAMPLE_SAMPLE_COUNT;
		m_DeviceDesc.frameBufferStencilSampleMaxNum = D3D12_MAX_MULTISAMPLE_SAMPLE_COUNT;
		m_DeviceDesc.frameBufferNoAttachmentsSampleMaxNum = D3D12_MAX_MULTISAMPLE_SAMPLE_COUNT;
		m_DeviceDesc.textureColorSampleMaxNum = D3D12_MAX_MULTISAMPLE_SAMPLE_COUNT;
		m_DeviceDesc.textureIntegerSampleMaxNum = 1;
		m_DeviceDesc.textureDepthSampleMaxNum = D3D12_MAX_MULTISAMPLE_SAMPLE_COUNT;
		m_DeviceDesc.textureStencilSampleMaxNum = D3D12_MAX_MULTISAMPLE_SAMPLE_COUNT;
		m_DeviceDesc.storageTextureSampleMaxNum = 1;

		m_DeviceDesc.texture1DMaxDim = D3D12_REQ_TEXTURE1D_U_DIMENSION;
		m_DeviceDesc.texture2DMaxDim = D3D12_REQ_TEXTURE2D_U_OR_V_DIMENSION;
		m_DeviceDesc.texture3DMaxDim = D3D12_REQ_TEXTURE3D_U_V_OR_W_DIMENSION;
		m_DeviceDesc.textureArrayMaxDim = D3D12_REQ_TEXTURE2D_ARRAY_AXIS_DIMENSION;
		m_DeviceDesc.texelBufferMaxDim = (1 << D3D12_REQ_BUFFER_RESOURCE_TEXEL_COUNT_2_TO_EXP) - 1;

		m_DeviceDesc.memoryAllocationMaxNum = 0xFFFFFFFF;
		m_DeviceDesc.samplerAllocationMaxNum = D3D12_REQ_SAMPLER_OBJECT_COUNT_PER_DEVICE;
		m_DeviceDesc.uploadBufferTextureRowAlignment = D3D12_TEXTURE_DATA_PITCH_ALIGNMENT;
		m_DeviceDesc.uploadBufferTextureSliceAlignment = D3D12_TEXTURE_DATA_PLACEMENT_ALIGNMENT;
		m_DeviceDesc.typedBufferOffsetAlignment = D3D12_RAW_UAV_SRV_BYTE_ALIGNMENT;
		m_DeviceDesc.constantBufferOffsetAlignment = D3D12_CONSTANT_BUFFER_DATA_PLACEMENT_ALIGNMENT;
		m_DeviceDesc.constantBufferMaxRange = D3D12_REQ_IMMEDIATE_CONSTANT_BUFFER_ELEMENT_COUNT * 16;
		m_DeviceDesc.storageBufferOffsetAlignment = D3D12_RAW_UAV_SRV_BYTE_ALIGNMENT;
		m_DeviceDesc.storageBufferMaxRange = (1 << D3D12_REQ_BUFFER_RESOURCE_TEXEL_COUNT_2_TO_EXP) - 1;
		m_DeviceDesc.bufferTextureGranularity = 1; // TODO: 64KB?
		m_DeviceDesc.bufferMaxSize = D3D12_REQ_RESOURCE_SIZE_IN_MEGABYTES_EXPRESSION_C_TERM * 1024uL * 1024uL;
		m_DeviceDesc.pushConstantsMaxSize = D3D12_REQ_IMMEDIATE_CONSTANT_BUFFER_ELEMENT_COUNT * 16;

		m_DeviceDesc.boundDescriptorSetMaxNum = D3D12_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT;
		m_DeviceDesc.perStageDescriptorSamplerMaxNum = D3D12_COMMONSHADER_SAMPLER_SLOT_COUNT;
		m_DeviceDesc.perStageDescriptorConstantBufferMaxNum = D3D12_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT;
		m_DeviceDesc.perStageDescriptorStorageBufferMaxNum = levels.MaxSupportedFeatureLevel >= .D3D_FEATURE_LEVEL_11_1 ? D3D12_UAV_SLOT_COUNT : D3D12_PS_CS_UAV_REGISTER_COUNT;
		m_DeviceDesc.perStageDescriptorTextureMaxNum = D3D12_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT;
		m_DeviceDesc.perStageDescriptorStorageTextureMaxNum = levels.MaxSupportedFeatureLevel >= .D3D_FEATURE_LEVEL_11_1 ? D3D12_UAV_SLOT_COUNT : D3D12_PS_CS_UAV_REGISTER_COUNT;
		m_DeviceDesc.perStageResourceMaxNum = D3D12_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT;

		m_DeviceDesc.descriptorSetSamplerMaxNum = m_DeviceDesc.perStageDescriptorSamplerMaxNum;
		m_DeviceDesc.descriptorSetConstantBufferMaxNum = m_DeviceDesc.perStageDescriptorConstantBufferMaxNum;
		m_DeviceDesc.descriptorSetStorageBufferMaxNum = m_DeviceDesc.perStageDescriptorStorageBufferMaxNum;
		m_DeviceDesc.descriptorSetTextureMaxNum = m_DeviceDesc.perStageDescriptorTextureMaxNum;
		m_DeviceDesc.descriptorSetStorageTextureMaxNum = m_DeviceDesc.perStageDescriptorStorageTextureMaxNum;

		m_DeviceDesc.vertexShaderAttributeMaxNum = D3D12_IA_VERTEX_INPUT_RESOURCE_SLOT_COUNT;
		m_DeviceDesc.vertexShaderStreamMaxNum = D3D12_IA_VERTEX_INPUT_RESOURCE_SLOT_COUNT;
		m_DeviceDesc.vertexShaderOutputComponentMaxNum = D3D12_IA_VERTEX_INPUT_RESOURCE_SLOT_COUNT * 4;

		m_DeviceDesc.tessControlShaderGenerationMaxLevel = D3D12_HS_MAXTESSFACTOR_UPPER_BOUND;
		m_DeviceDesc.tessControlShaderPatchPointMaxNum = D3D12_IA_PATCH_MAX_CONTROL_POINT_COUNT;
		m_DeviceDesc.tessControlShaderPerVertexInputComponentMaxNum = D3D12_HS_CONTROL_POINT_PHASE_INPUT_REGISTER_COUNT * D3D12_HS_CONTROL_POINT_REGISTER_COMPONENTS;
		m_DeviceDesc.tessControlShaderPerVertexOutputComponentMaxNum = D3D12_HS_CONTROL_POINT_PHASE_OUTPUT_REGISTER_COUNT * D3D12_HS_CONTROL_POINT_REGISTER_COMPONENTS;
		m_DeviceDesc.tessControlShaderPerPatchOutputComponentMaxNum = D3D12_HS_OUTPUT_PATCH_CONSTANT_REGISTER_SCALAR_COMPONENTS;
		m_DeviceDesc.tessControlShaderTotalOutputComponentMaxNum = m_DeviceDesc.tessControlShaderPatchPointMaxNum * m_DeviceDesc.tessControlShaderPerVertexOutputComponentMaxNum + m_DeviceDesc.tessControlShaderPerPatchOutputComponentMaxNum;

		m_DeviceDesc.tessEvaluationShaderInputComponentMaxNum = D3D12_DS_INPUT_CONTROL_POINT_REGISTER_COUNT * D3D12_DS_INPUT_CONTROL_POINT_REGISTER_COMPONENTS;
		m_DeviceDesc.tessEvaluationShaderOutputComponentMaxNum = D3D12_DS_INPUT_CONTROL_POINT_REGISTER_COUNT * D3D12_DS_INPUT_CONTROL_POINT_REGISTER_COMPONENTS;

		m_DeviceDesc.geometryShaderInvocationMaxNum = D3D12_GS_MAX_INSTANCE_COUNT;
		m_DeviceDesc.geometryShaderInputComponentMaxNum = D3D12_GS_INPUT_REGISTER_COUNT * D3D12_GS_INPUT_REGISTER_COMPONENTS;
		m_DeviceDesc.geometryShaderOutputComponentMaxNum = D3D12_GS_OUTPUT_REGISTER_COUNT * D3D12_GS_INPUT_REGISTER_COMPONENTS;
		m_DeviceDesc.geometryShaderOutputVertexMaxNum = D3D12_GS_MAX_OUTPUT_VERTEX_COUNT_ACROSS_INSTANCES;
		m_DeviceDesc.geometryShaderTotalOutputComponentMaxNum = D3D12_REQ_GS_INVOCATION_32BIT_OUTPUT_COMPONENT_LIMIT;

		m_DeviceDesc.fragmentShaderInputComponentMaxNum = D3D12_PS_INPUT_REGISTER_COUNT * D3D12_PS_INPUT_REGISTER_COMPONENTS;
		m_DeviceDesc.fragmentShaderOutputAttachmentMaxNum = D3D12_SIMULTANEOUS_RENDER_TARGET_COUNT;
		m_DeviceDesc.fragmentShaderDualSourceAttachmentMaxNum = 1;
		m_DeviceDesc.fragmentShaderCombinedOutputResourceMaxNum = D3D12_SIMULTANEOUS_RENDER_TARGET_COUNT + D3D12_PS_CS_UAV_REGISTER_COUNT;

		m_DeviceDesc.computeShaderSharedMemoryMaxSize = D3D12_CS_THREAD_LOCAL_TEMP_REGISTER_POOL;
		m_DeviceDesc.computeShaderWorkGroupMaxNum[0] = D3D12_CS_DISPATCH_MAX_THREAD_GROUPS_PER_DIMENSION;
		m_DeviceDesc.computeShaderWorkGroupMaxNum[1] = D3D12_CS_DISPATCH_MAX_THREAD_GROUPS_PER_DIMENSION;
		m_DeviceDesc.computeShaderWorkGroupMaxNum[2] = D3D12_CS_DISPATCH_MAX_THREAD_GROUPS_PER_DIMENSION;
		m_DeviceDesc.computeShaderWorkGroupInvocationMaxNum = D3D12_CS_THREAD_GROUP_MAX_THREADS_PER_GROUP;
		m_DeviceDesc.computeShaderWorkGroupMaxDim[0] = D3D12_CS_THREAD_GROUP_MAX_X;
		m_DeviceDesc.computeShaderWorkGroupMaxDim[1] = D3D12_CS_THREAD_GROUP_MAX_Y;
		m_DeviceDesc.computeShaderWorkGroupMaxDim[2] = D3D12_CS_THREAD_GROUP_MAX_Z;

	//#ifdef __ID3D12Device5_INTERFACE_DEFINED__
		if (m_IsRaytracingSupported)
		{
			m_DeviceDesc.rayTracingShaderGroupIdentifierSize = D3D12_RAYTRACING_SHADER_RECORD_BYTE_ALIGNMENT;
			m_DeviceDesc.rayTracingShaderTableAligment = D3D12_RAYTRACING_SHADER_TABLE_BYTE_ALIGNMENT;
			m_DeviceDesc.rayTracingShaderTableMaxStride = uint64.MaxValue;
			m_DeviceDesc.rayTracingShaderRecursionMaxDepth = D3D12_RAYTRACING_MAX_DECLARABLE_TRACE_RECURSION_DEPTH;
			m_DeviceDesc.rayTracingGeometryObjectMaxNum = (1 << 24) - 1;
		}
	//#endif

		m_DeviceDesc.subPixelPrecisionBits = D3D12_SUBPIXEL_FRACTIONAL_BIT_COUNT;
		m_DeviceDesc.subTexelPrecisionBits = D3D12_SUBTEXEL_FRACTIONAL_BIT_COUNT;
		m_DeviceDesc.mipmapPrecisionBits = D3D12_MIP_LOD_FRACTIONAL_BIT_COUNT;
		m_DeviceDesc.drawIndexedIndex16ValueMax = D3D12_16BIT_INDEX_STRIP_CUT_VALUE;
		m_DeviceDesc.drawIndexedIndex32ValueMax = D3D12_32BIT_INDEX_STRIP_CUT_VALUE;
		m_DeviceDesc.drawIndirectMaxNum = (((uint64)1uL << D3D12_REQ_DRAWINDEXED_INDEX_COUNT_2_TO_EXP) - 1);
		m_DeviceDesc.samplerLodBiasMin = D3D12_MIP_LOD_BIAS_MIN;
		m_DeviceDesc.samplerLodBiasMax = D3D12_MIP_LOD_BIAS_MAX;
		m_DeviceDesc.samplerAnisotropyMax = D3D12_DEFAULT_MAX_ANISOTROPY;
		m_DeviceDesc.texelOffsetMin = D3D12_COMMONSHADER_TEXEL_OFFSET_MAX_NEGATIVE;
		m_DeviceDesc.texelOffsetMax = D3D12_COMMONSHADER_TEXEL_OFFSET_MAX_POSITIVE;
		m_DeviceDesc.texelGatherOffsetMin = D3D12_COMMONSHADER_TEXEL_OFFSET_MAX_NEGATIVE;
		m_DeviceDesc.texelGatherOffsetMax = D3D12_COMMONSHADER_TEXEL_OFFSET_MAX_POSITIVE;
		m_DeviceDesc.clipDistanceMaxNum = D3D12_CLIP_OR_CULL_DISTANCE_COUNT;
		m_DeviceDesc.cullDistanceMaxNum = D3D12_CLIP_OR_CULL_DISTANCE_COUNT;
		m_DeviceDesc.combinedClipAndCullDistanceMaxNum = D3D12_CLIP_OR_CULL_DISTANCE_COUNT;
		m_DeviceDesc.conservativeRasterTier = (uint8)options.ConservativeRasterizationTier;
		m_DeviceDesc.timestampFrequencyHz = timestampFrequency;
		m_DeviceDesc.phyiscalDeviceGroupSize = m_Device.GetNodeCount();

		m_DeviceDesc.isAPIValidationEnabled = enableValidation;
		m_DeviceDesc.isTextureFilterMinMaxSupported = levels.MaxSupportedFeatureLevel >= .D3D_FEATURE_LEVEL_11_1 ? true : false;
		m_DeviceDesc.isLogicOpSupported = options.OutputMergerLogicOp != 0;
		m_DeviceDesc.isDepthBoundsTestSupported = options2.DepthBoundsTestSupported != 0;
		m_DeviceDesc.isProgrammableSampleLocationsSupported = options2.ProgrammableSamplePositionsTier != .D3D12_PROGRAMMABLE_SAMPLE_POSITIONS_TIER_NOT_SUPPORTED;
		m_DeviceDesc.isComputeQueueSupported = true;
		m_DeviceDesc.isCopyQueueSupported = true;
		m_DeviceDesc.isCopyQueueTimestampSupported = options3.CopyQueueTimestampQueriesSupported != 0;
		m_DeviceDesc.isRegisterAliasingSupported = true;
		m_DeviceDesc.isSubsetAllocationSupported = true;
		m_DeviceDesc.isFloat16Supported = options4.Native16BitShaderOpsSupported == 1;
	}

	private MemoryType GetMemoryType(MemoryLocation memoryLocation, D3D12_RESOURCE_DESC resourceDesc)
	{
		return nri.d3d12.GetMemoryType(memoryLocation, resourceDesc);
	}

	private DeviceLogger m_Logger;
	private DeviceAllocator<uint8> m_Allocator;
	private ComPtr<ID3D12Device> m_Device;
//#ifdef __ID3D12Device5_INTERFACE_DEFINED__
	private ComPtr<ID3D12Device5> m_Device5;
//#endif
	private CommandQueueD3D12[COMMAND_QUEUE_TYPE_NUM] m_CommandQueues = .();
	private List<DescriptorHeapDesc> m_DescriptorHeaps;
	private List<List<DescriptorHandle>> m_FreeDescriptors;
	private DeviceDesc m_DeviceDesc = .();
	private Dictionary<uint32, ComPtr<ID3D12CommandSignature>> m_DrawCommandSignatures;
	private Dictionary<uint32, ComPtr<ID3D12CommandSignature>> m_DrawIndexedCommandSignatures;
	private ComPtr<ID3D12CommandSignature> m_DispatchCommandSignature;
	private ComPtr<IDXGIAdapter> m_Adapter;
	private bool m_IsRaytracingSupported = false;
	private bool m_IsMeshShaderSupported = false;
	private bool m_SkipLiveObjectsReporting = false;

	private Monitor[DESCRIPTOR_HEAP_TYPE_NUM] m_FreeDescriptorLocks;
	private Monitor m_DescriptorHeapLock;
	private Monitor m_QueueLock;

	public this(DeviceLogger logger, DeviceAllocator<uint8> allocator)
	{
		m_Logger = logger;
		m_Allocator = allocator;

		m_DescriptorHeaps = Allocate!<List<DescriptorHeapDesc>>(GetAllocator());
		m_FreeDescriptors = Allocate!<List<List<DescriptorHandle>>>(GetAllocator());
		m_DrawCommandSignatures = Allocate!<Dictionary<uint32, ComPtr<ID3D12CommandSignature>>>(GetAllocator());
		m_DrawIndexedCommandSignatures = Allocate!<Dictionary<uint32, ComPtr<ID3D12CommandSignature>>>(GetAllocator());

		m_FreeDescriptors.Resize(DESCRIPTOR_HEAP_TYPE_NUM, Allocate!<List<DescriptorHandle>>(GetAllocator()));
	}

	public ~this()
	{
		for (var commandQueueD3D12 in ref m_CommandQueues)
		{
			if (commandQueueD3D12 != null)
			{
				Deallocate!(GetAllocator(), commandQueueD3D12);
				commandQueueD3D12 = null;
			}
		}

		Deallocate!(GetAllocator(), m_DrawIndexedCommandSignatures);
		Deallocate!(GetAllocator(), m_DrawCommandSignatures);

		for (var item in ref m_FreeDescriptors)
		{
			Deallocate!(GetAllocator(), item);
		}
		Deallocate!(GetAllocator(), m_FreeDescriptors);
		Deallocate!(GetAllocator(), m_DescriptorHeaps);
	}

	public static implicit operator ID3D12Device*(Self self) => self.m_Device /*.GetInterface()*/;
	public static implicit operator ID3D12Device5*(Self self) => self.m_Device5 /*.GetInterface()*/;

	private Result CreateImplementation<Implementation, Interface>(out Interface entity)
		where Implementation : Interface, var
	{
		entity = ?;

		Implementation implementation = Allocate!<Implementation>(GetAllocator(), this);
		readonly Result result = implementation.Create();

		if (result == Result.SUCCESS)
		{
			entity = (Interface)implementation;
			return Result.SUCCESS;
		}

		Deallocate!(GetAllocator(), implementation);
		return result;
	}

	private Result CreateImplementation<Implementation, Interface, P1>(out Interface entity, P1 p1)
		where Implementation : Interface, var
		where P1 : var
	{
		entity = ?;

		Implementation implementation = Allocate!<Implementation>(GetAllocator(), this);
		readonly Result result = implementation.Create(p1);

		if (result == Result.SUCCESS)
		{
			entity = (Interface)implementation;
			return Result.SUCCESS;
		}

		Deallocate!(GetAllocator(), implementation);
		return result;
	}

	private Result CreateImplementation<Implementation, Interface, P1, P2>(out Interface entity, P1 p1, P2 p2)
		where Implementation : Interface, var
		where P1 : var
		where P2 : var
	{
		entity = ?;

		Implementation implementation = Allocate!<Implementation>(GetAllocator(), this);
		readonly Result result = implementation.Create(p1, p2);

		if (result == Result.SUCCESS)
		{
			entity = (Interface)implementation;
			return Result.SUCCESS;
		}

		Deallocate!(GetAllocator(), implementation);
		return result;
	}

	private Result CreateImplementation<Implementation, Interface, P1, P2, P3>(out Interface entity, P1 p1, P2 p2, P3 p3)
		where Implementation : Interface, var
		where P1 : var
		where P2 : var
	{
		entity = ?;

		Implementation implementation = Allocate!<Implementation>(GetAllocator(), this);
		readonly Result result = implementation.Create(p1, p2, p3);

		if (result == Result.SUCCESS)
		{
			entity = (Interface)implementation;
			return Result.SUCCESS;
		}

		Deallocate!(GetAllocator(), implementation);
		return result;
	}


	public Result Create(IDXGIAdapter* dxgiAdapter, bool enableValidation)
	{
		m_Adapter = dxgiAdapter;

		// Enable the debug layer (requires the Graphics Tools "optional feature").
		// NOTE: Enabling the debug layer after device creation will invalidate the active device.
		if (enableValidation)
		{
			ComPtr<ID3D12Debug> debugController = null;
			if (SUCCEEDED(D3D12GetDebugInterface(ID3D12Debug.IID, (void**)(&debugController))))
				debugController.EnableDebugLayer();

			// GPU-based validation
			//ComPtr<ID3D12Debug1> debugController1 = null;
			//if (SUCCEEDED(debugController.QueryInterface(ID3D12Debug1.IID, (void**)(&debugController1))))
			//    debugController1.SetEnableGPUBasedValidation(true);
		}

		HRESULT hr = D3D12CreateDevice(dxgiAdapter, .D3D_FEATURE_LEVEL_12_0, ID3D12Device.IID,  (void**)(&m_Device));
		if (FAILED(hr))
		{
			REPORT_ERROR(GetLogger(), "D3D12CreateDevice() failed, error code: 0x%X.", hr);
			return Result.FAILURE;
		}

		// TODO: this code is currently needed to disable known false-positive errors reported by the debug layer
		if (enableValidation)
		{
			ComPtr<ID3D12InfoQueue> pInfoQueue = null;
			m_Device.QueryInterface(ID3D12InfoQueue.IID, (void**)&pInfoQueue);

			if (pInfoQueue != null)
			{
				#if DEBUG
					pInfoQueue.SetBreakOnSeverity(.D3D12_MESSAGE_SEVERITY_CORRUPTION, /*true*/1);
					pInfoQueue.SetBreakOnSeverity(.D3D12_MESSAGE_SEVERITY_ERROR, /*true*/1);
				#endif

				D3D12_MESSAGE_ID[?] disableMessageIDs = .(
					.D3D12_MESSAGE_ID_COMMAND_LIST_STATIC_DESCRIPTOR_RESOURCE_DIMENSION_MISMATCH // TODO: descriptor validation doesn't understand acceleration structures used outside of RAYGEN shaders
					);

				D3D12_INFO_QUEUE_FILTER filter = .();
				filter.DenyList.pIDList = &disableMessageIDs;
				filter.DenyList.NumIDs = disableMessageIDs.Count;
				pInfoQueue.AddStorageFilterEntries(&filter);
			}
		}

	//#ifdef __ID3D12Device5_INTERFACE_DEFINED__
		m_Device.QueryInterface(ID3D12Device5.IID, (void**)(&m_Device5));
	//#endif

		CommandQueue commandQueue = null;
		Result result = GetCommandQueue(CommandQueueType.GRAPHICS, out commandQueue);
		if (result != Result.SUCCESS)
			return result;

		D3D12_INDIRECT_ARGUMENT_DESC indirectArgumentDesc = .();
		indirectArgumentDesc.Type = .D3D12_INDIRECT_ARGUMENT_TYPE_DISPATCH;

		D3D12_COMMAND_SIGNATURE_DESC commandSignatureDesc = .();
		commandSignatureDesc.NumArgumentDescs = 1;
		commandSignatureDesc.pArgumentDescs = &indirectArgumentDesc;
		commandSignatureDesc.NodeMask = NRI_TEMP_NODE_MASK;
		commandSignatureDesc.ByteStride = 12;

		hr = m_Device.CreateCommandSignature(&commandSignatureDesc, null, ID3D12CommandSignature.IID, (void**)(&m_DispatchCommandSignature));
		if (FAILED(hr))
		{
			REPORT_ERROR(GetLogger(), "ID3D12Device::CreateCommandSignature() failed, error code: 0x{0:X}.", hr);
			return Result.FAILURE;
		}

		UpdateDeviceDesc(enableValidation);

		return Result.SUCCESS;
	}

	public Result Create(DeviceCreationD3D12Desc deviceCreationDesc)
	{
		m_Device = (ID3D12Device*)deviceCreationDesc.d3d12Device;
		m_SkipLiveObjectsReporting = true;

		m_Adapter = deviceCreationDesc.d3d12PhysicalAdapter;

		if (m_Adapter == null)
		{
			readonly LUID luid = m_Device.GetAdapterLuid();

			ComPtr<IDXGIFactory4> DXGIFactory = null;
			HRESULT result = CreateDXGIFactory(IDXGIFactory4.IID, (void**)(&DXGIFactory));
			RETURN_ON_BAD_HRESULT!(GetLogger(), result, "Failed to create IDXGIFactory4");

			result = DXGIFactory.EnumAdapterByLuid(luid, IDXGIAdapter.IID, (void**)(&m_Adapter));
			RETURN_ON_BAD_HRESULT!(GetLogger(), result, "Failed to find IDXGIAdapter by LUID");
		}

	//#ifdef __ID3D12Device5_INTERFACE_DEFINED__
		m_Device.QueryInterface(ID3D12Device5.IID, (void**)(&m_Device5));
	//#endif

		if (deviceCreationDesc.d3d12GraphicsQueue != null)
			CreateCommandQueue((ID3D12CommandQueue*)deviceCreationDesc.d3d12GraphicsQueue, m_CommandQueues[(uint32)CommandQueueType.GRAPHICS]);
		if (deviceCreationDesc.d3d12ComputeQueue != null)
			CreateCommandQueue((ID3D12CommandQueue*)deviceCreationDesc.d3d12ComputeQueue, m_CommandQueues[(uint32)CommandQueueType.COMPUTE]);
		if (deviceCreationDesc.d3d12CopyQueue != null)
			CreateCommandQueue((ID3D12CommandQueue*)deviceCreationDesc.d3d12CopyQueue, m_CommandQueues[(uint32)CommandQueueType.COPY]);

		CommandQueue commandQueue;
		Result result = GetCommandQueue(CommandQueueType.GRAPHICS, out commandQueue);
		if (result != Result.SUCCESS)
			return result;

		UpdateDeviceDesc(deviceCreationDesc.enableAPIValidation);

		return Result.SUCCESS;
	}

	public Result CreateCpuOnlyVisibleDescriptorHeap(D3D12_DESCRIPTOR_HEAP_TYPE type)
	{
		m_DescriptorHeapLock.Enter();
		defer m_DescriptorHeapLock.Exit();

		int heapIndex = m_DescriptorHeaps.Count;
		if (heapIndex >= HeapIndexType(-1))
			return Result.OUT_OF_MEMORY;

		ComPtr<ID3D12DescriptorHeap> descriptorHeap = null;
		D3D12_DESCRIPTOR_HEAP_DESC desc = .() { Type = type, NumDescriptors = DESCRIPTORS_BATCH_SIZE, Flags = .D3D12_DESCRIPTOR_HEAP_FLAG_NONE, NodeMask = NRI_TEMP_NODE_MASK };
		HRESULT hr = ((ID3D12Device*)m_Device).CreateDescriptorHeap(&desc, ID3D12DescriptorHeap.IID, (void**)(&descriptorHeap));
		if (FAILED(hr))
		{
			REPORT_ERROR(GetLogger(), "ID3D12Device.CreateDescriptorHeap() failed, return code %d.", hr);
			return Result.FAILURE;
		}

		DescriptorHeapDesc descriptorHeapDesc = .();
		descriptorHeapDesc.descriptorHeap = descriptorHeap;
		descriptorHeapDesc.descriptorPointerCPU = descriptorHeap.GetCPUDescriptorHandleForHeapStart().ptr;
		descriptorHeapDesc.descriptorSize = m_Device.GetDescriptorHandleIncrementSize(type);
		m_DescriptorHeaps.Add(descriptorHeapDesc);

		var freeDescriptors = ref m_FreeDescriptors[(.)type];
		for (uint32 i = 0; i < desc.NumDescriptors; i++)
			freeDescriptors.Add(.() { heapIndex = (HeapIndexType)heapIndex, heapOffset = (HeapOffsetType)i });

		return Result.SUCCESS;
	}

	public Result GetDescriptorHandle(D3D12_DESCRIPTOR_HEAP_TYPE type, ref DescriptorHandle descriptorHandle)
	{
		m_FreeDescriptorLocks[(.)type].Enter();
		defer m_FreeDescriptorLocks[(.)type].Exit();

		var freeDescriptors = ref m_FreeDescriptors[(.)type];
		if (freeDescriptors.IsEmpty)
		{
			Result result = CreateCpuOnlyVisibleDescriptorHeap(type);
			if (result != Result.SUCCESS)
				return result;
		}

		descriptorHandle = freeDescriptors.Back;
		freeDescriptors.PopBack();

		return Result.SUCCESS;
	}

	public void FreeDescriptorHandle(D3D12_DESCRIPTOR_HEAP_TYPE type, DescriptorHandle descriptorHandle)
	{
		using (m_FreeDescriptorLocks[(.)type].Enter())
		{
			var freeDescriptors = ref m_FreeDescriptors[(.)type];
			freeDescriptors.Add(descriptorHandle);
		}
	}

	public DescriptorPointerCPU GetDescriptorPointerCPU(DescriptorHandle descriptorHandle)
	{
		m_DescriptorHeapLock.Enter();
		defer m_DescriptorHeapLock.Exit();

		readonly ref DescriptorHeapDesc descriptorHeapDesc = ref m_DescriptorHeaps[descriptorHandle.heapIndex];
		DescriptorPointerCPU descriptorPointer = descriptorHeapDesc.descriptorPointerCPU + descriptorHandle.heapOffset * descriptorHeapDesc.descriptorSize;

		return descriptorPointer;
	}

	public void GetMemoryInfo(MemoryLocation memoryLocation, D3D12_RESOURCE_DESC resourceDesc, ref MemoryDesc memoryDesc)
	{
		var resourceDesc;
		memoryDesc.type = GetMemoryType(memoryLocation, resourceDesc);

		D3D12_RESOURCE_ALLOCATION_INFO resourceAllocationInfo = m_Device.GetResourceAllocationInfo(NRI_TEMP_NODE_MASK, 1, &resourceDesc);
		memoryDesc.size = (uint64)resourceAllocationInfo.SizeInBytes;
		memoryDesc.alignment = (uint32)resourceAllocationInfo.Alignment;

		memoryDesc.mustBeDedicated = RequiresDedicatedAllocation(memoryDesc.type);
	}


	public ID3D12CommandSignature* CreateCommandSignature(D3D12_INDIRECT_ARGUMENT_TYPE indirectArgumentType, uint32 stride)
	{
		D3D12_INDIRECT_ARGUMENT_DESC indirectArgumentDesc = .();
		indirectArgumentDesc.Type = indirectArgumentType;

		D3D12_COMMAND_SIGNATURE_DESC commandSignatureDesc = .();
		commandSignatureDesc.NumArgumentDescs = 1;
		commandSignatureDesc.pArgumentDescs = &indirectArgumentDesc;
		commandSignatureDesc.NodeMask = NRI_TEMP_NODE_MASK;
		commandSignatureDesc.ByteStride = stride;

		ID3D12CommandSignature* commandSignature = null;
		HRESULT hr = m_Device.CreateCommandSignature(&commandSignatureDesc, null, ID3D12CommandSignature.IID, (void**)(&commandSignature));
		if (FAILED(hr))
			REPORT_ERROR(GetLogger(), "ID3D12Device.CreateCommandSignature() failed, error code: 0x{0:X}.", hr);

		return commandSignature;
	}

	public ID3D12CommandSignature* GetDrawCommandSignature(uint32 stride)
	{
		if (m_DrawCommandSignatures.ContainsKey(stride))
		{
			return m_DrawCommandSignatures[stride];
		}

		ID3D12CommandSignature* commandSignature = CreateCommandSignature(.D3D12_INDIRECT_ARGUMENT_TYPE_DRAW, stride);
		m_DrawCommandSignatures[stride] = commandSignature;

		return commandSignature;
	}

	public ID3D12CommandSignature* GetDrawIndexedCommandSignature(uint32 stride)
	{
		if (m_DrawIndexedCommandSignatures.ContainsKey(stride))
		{
			return m_DrawIndexedCommandSignatures[stride];
		}

		ID3D12CommandSignature* commandSignature = CreateCommandSignature(.D3D12_INDIRECT_ARGUMENT_TYPE_DRAW_INDEXED, stride);
		m_DrawIndexedCommandSignatures[stride] = commandSignature;

		return commandSignature;
	}

	public ID3D12CommandSignature* GetDispatchCommandSignature()
	{
		return m_DispatchCommandSignature /*.GetInterface()*/;
	}

	public bool IsMeshShaderSupported() => m_IsMeshShaderSupported;

	public bool GetOutput(ref Display* display, ref ComPtr<IDXGIOutput> output)
	{
		if (display == null)
			return false;

		readonly uint32 index = (*(uint32*)&display) - 1;
		readonly HRESULT result = m_Adapter.EnumOutputs(index, &output);

		return SUCCEEDED(result);
	}
}