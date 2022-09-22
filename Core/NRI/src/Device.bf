using NRI.Helpers;
namespace NRI;

interface Device
{
	public abstract DeviceLogger GetLogger();
	public abstract DeviceAllocator<uint8> GetAllocator();

	public abstract void SetDebugName(char8* name);

	public abstract readonly ref DeviceDesc GetDesc();
	public abstract Result GetCommandQueue(CommandQueueType commandQueueType, out CommandQueue commandQueue);

	public abstract Result CreateCommandAllocator(CommandQueue commandQueue, uint32 physicalDeviceMask, out CommandAllocator commandAllocator);
	public abstract Result CreateDescriptorPool(DescriptorPoolDesc descriptorPoolDesc, out DescriptorPool descriptorPool);
	public abstract Result CreateBuffer(BufferDesc bufferDesc, out Buffer buffer);
	public abstract Result CreateTexture(TextureDesc textureDesc, out Texture texture);
	public abstract Result CreateBufferView(BufferViewDesc bufferViewDesc, out Descriptor bufferView);
	public abstract Result CreateTexture1DView(Texture1DViewDesc textureViewDesc, out Descriptor textureView);
	public abstract Result CreateTexture2DView(Texture2DViewDesc textureViewDesc, out Descriptor textureView);
	public abstract Result CreateTexture3DView(Texture3DViewDesc textureViewDesc, out Descriptor textureView);
	public abstract Result CreateSampler(SamplerDesc samplerDesc, out Descriptor sampler);
	public abstract Result CreatePipelineLayout(PipelineLayoutDesc pipelineLayoutDesc, out PipelineLayout pipelineLayout);
	public abstract Result CreateGraphicsPipeline(GraphicsPipelineDesc graphicsPipelineDesc, out Pipeline pipeline);
	public abstract Result CreateComputePipeline(ComputePipelineDesc computePipelineDesc, out Pipeline pipeline);
	public abstract Result CreateFrameBuffer(FrameBufferDesc frameBufferDesc, out FrameBuffer frameBuffer);
	public abstract Result CreateQueryPool(QueryPoolDesc queryPoolDesc, out QueryPool queryPool);
	public abstract Result CreateQueueSemaphore(out QueueSemaphore queueSemaphore);
	public abstract Result CreateDeviceSemaphore(bool signaled, out DeviceSemaphore deviceSemaphore);
	public abstract Result CreateCommandBuffer(CommandAllocator commandAllocator, out CommandBuffer commandBuffer);
    public abstract Result CreateSwapChain(SwapChainDesc swapChainDesc, out SwapChain swapChain);
    public abstract Result CreateRayTracingPipeline(RayTracingPipelineDesc rayTracingPipelineDesc, out Pipeline pipeline);
    public abstract Result CreateAccelerationStructure(AccelerationStructureDesc accelerationStructureDesc, out AccelerationStructure accelerationStructure);


	public abstract void DestroyCommandAllocator(CommandAllocator commandAllocator);
	public abstract void DestroyDescriptorPool(DescriptorPool descriptorPool);
	public abstract void DestroyBuffer(Buffer buffer);
	public abstract void DestroyTexture(Texture texture);
	public abstract void DestroyDescriptor(Descriptor descriptor);
	public abstract void DestroyPipelineLayout(PipelineLayout pipelineLayout);
	public abstract void DestroyPipeline(Pipeline pipeline);
	public abstract void DestroyFrameBuffer(FrameBuffer frameBuffer);
	public abstract void DestroyQueryPool(QueryPool queryPool);
	public abstract void DestroyQueueSemaphore(QueueSemaphore queueSemaphore);
	public abstract void DestroyDeviceSemaphore(DeviceSemaphore deviceSemaphore);
	public abstract void DestroyCommandBuffer(CommandBuffer commandBuffer);
    public abstract void DestroySwapChain(SwapChain swapChain);
	public abstract void DestroyAccelerationStructure(AccelerationStructure accelerationStructure);
	public abstract void Destroy();
	
	public abstract Result GetDisplays(Display** displays, ref uint32 displayNum);
	public abstract Result GetDisplaySize(ref Display display, ref uint16 width, ref uint16 height);

	public abstract Result AllocateMemory(uint32 physicalDeviceMask, MemoryType memoryType, uint64 size, out Memory memory);
	public abstract Result BindBufferMemory(BufferMemoryBindingDesc* memoryBindingDescs, uint32 memoryBindingDescNum);
	public abstract Result BindTextureMemory(TextureMemoryBindingDesc* memoryBindingDescs, uint32 memoryBindingDescNum);
    public abstract Result BindAccelerationStructureMemory(AccelerationStructureMemoryBindingDesc* memoryBindingDescs, uint32 memoryBindingDescNum);
	public abstract void FreeMemory(Memory memory);

	public abstract FormatSupportBits GetFormatSupport(Format format);

	
	public abstract uint32 CalculateAllocationNumber(ResourceGroupDesc resourceGroupDesc);
	public abstract Result AllocateAndBindMemory(ResourceGroupDesc resourceGroupDesc, Memory* allocations);

	public abstract void* GetDeviceNativeObject();
}