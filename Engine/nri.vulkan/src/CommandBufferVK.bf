using Bulkan;
namespace nri.vulkan;

struct Barriers
{
	public VkBufferMemoryBarrier* buffers;
	public VkImageMemoryBarrier* images;
	public uint32 bufferNum;
	public uint32 imageNum;
}

class CommandBufferVK : CommandBuffer
{
	private void FillAliasingBufferBarriers(AliasingBarrierDesc aliasing, ref Barriers barriers)
	{
		for (uint32 i = 0; i < aliasing.bufferNum; i++)
		{
			readonly ref BufferAliasingBarrierDesc barrierDesc = ref aliasing.buffers[i];
			readonly BufferVK bufferImpl = (BufferVK)barrierDesc.after;

			barriers.buffers[barriers.bufferNum++] = .()
				{
					sType = .VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER,
					pNext = null,
					srcAccessMask = (VkAccessFlags)0,
					dstAccessMask = GetAccessFlags(barrierDesc.nextAccess),
					srcQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED,
					dstQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED,
					buffer = bufferImpl.GetHandle(m_PhysicalDeviceIndex),
					offset = 0,
					size = VulkanNative.VK_WHOLE_SIZE
				};
		}
	}

	private void FillAliasingImageBarriers(AliasingBarrierDesc aliasing, ref Barriers barriers)
	{
		for (uint32 i = 0; i < aliasing.textureNum; i++)
		{
			readonly ref TextureAliasingBarrierDesc barrierDesc = ref aliasing.textures[i];
			readonly TextureVK textureImpl = (TextureVK)barrierDesc.after;

			barriers.images[barriers.imageNum++] = .()
				{
					sType = .VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
					pNext = null,
					srcAccessMask = (VkAccessFlags)0,
					dstAccessMask = GetAccessFlags(barrierDesc.nextAccess),
					oldLayout = .VK_IMAGE_LAYOUT_UNDEFINED,
					newLayout = GetImageLayout(barrierDesc.nextLayout),
					srcQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED,
					dstQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED,
					image = textureImpl.GetHandle(m_PhysicalDeviceIndex),
					subresourceRange = VkImageSubresourceRange()
						{
							aspectMask = textureImpl.GetImageAspectFlags(),
							baseMipLevel = 0,
							levelCount = VulkanNative.VK_REMAINING_MIP_LEVELS,
							baseArrayLayer = 0,
							layerCount = VulkanNative.VK_REMAINING_ARRAY_LAYERS
						}
				};
		}
	}

	private void FillTransitionBufferBarriers(TransitionBarrierDesc transitions, ref Barriers barriers)
	{
		for (uint32 i = 0; i < transitions.bufferNum; i++)
		{
			readonly ref BufferTransitionBarrierDesc barrierDesc = ref transitions.buffers[i];

			ref VkBufferMemoryBarrier barrier = ref barriers.buffers[barriers.bufferNum++];
			readonly BufferVK bufferImpl = (BufferVK)barrierDesc.buffer;

			barrier = .()
				{
					sType = .VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER,
					pNext = null,
					srcAccessMask = GetAccessFlags(barrierDesc.prevAccess),
					dstAccessMask = GetAccessFlags(barrierDesc.nextAccess),
					srcQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED,
					dstQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED,
					buffer = bufferImpl.GetHandle(m_PhysicalDeviceIndex),
					offset = 0,
					size = VulkanNative.VK_WHOLE_SIZE
				};
		}
	}

	private void FillTransitionImageBarriers(TransitionBarrierDesc transitions, ref Barriers barriers)
	{
		for (uint32 i = 0; i < transitions.textureNum; i++)
		{
			readonly ref TextureTransitionBarrierDesc barrierDesc = ref transitions.textures[i];

			ref VkImageMemoryBarrier barrier = ref barriers.images[barriers.imageNum++];
			readonly TextureVK textureImpl = (TextureVK)barrierDesc.texture;

			barrier = .()
				{
					sType = .VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
					pNext = null,
					srcAccessMask = GetAccessFlags(barrierDesc.prevAccess),
					dstAccessMask = GetAccessFlags(barrierDesc.nextAccess),
					oldLayout = GetImageLayout(barrierDesc.prevLayout),
					newLayout = GetImageLayout(barrierDesc.nextLayout),
					srcQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED,
					dstQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED,
					image = textureImpl.GetHandle(m_PhysicalDeviceIndex),
					subresourceRange = VkImageSubresourceRange()
						{
							aspectMask = textureImpl.GetImageAspectFlags(),
							baseMipLevel = barrierDesc.mipOffset,
							levelCount = (barrierDesc.mipNum == REMAINING_MIP_LEVELS) ? VulkanNative.VK_REMAINING_MIP_LEVELS : barrierDesc.mipNum,
							baseArrayLayer = barrierDesc.arrayOffset,
							layerCount = (barrierDesc.arraySize == REMAINING_ARRAY_LAYERS) ? VulkanNative.VK_REMAINING_ARRAY_LAYERS : barrierDesc.arraySize
						}
				};
		}
	}

	private void CopyWholeTexture(TextureVK dstTexture, uint32 dstPhysicalDeviceIndex, TextureVK srcTexture, uint32 srcPhysicalDeviceIndex)
	{
		VkImageCopy* regions = STACK_ALLOC!<VkImageCopy>(dstTexture.GetMipNum());

		for (uint32 i = 0; i < dstTexture.GetMipNum(); i++)
		{
			regions[i].srcSubresource = .()
				{
					aspectMask = srcTexture.GetImageAspectFlags(),
					mipLevel = i,
					baseArrayLayer = 0,
					layerCount = srcTexture.GetArraySize()
				};

			regions[i].dstSubresource = .()
				{
					aspectMask = dstTexture.GetImageAspectFlags(),
					mipLevel = i,
					baseArrayLayer = 0,
					layerCount = dstTexture.GetArraySize()
				};

			regions[i].dstOffset = .();
			regions[i].srcOffset = .();
			regions[i].extent = dstTexture.GetExtent();
		}

		VulkanNative.vkCmdCopyImage(m_Handle,
			srcTexture.GetHandle(srcPhysicalDeviceIndex), .VK_IMAGE_LAYOUT_GENERAL,
			dstTexture.GetHandle(dstPhysicalDeviceIndex), .VK_IMAGE_LAYOUT_GENERAL,
			dstTexture.GetMipNum(), regions);
	}

	private VkCommandBuffer m_Handle = .Null;
	private uint32 m_PhysicalDeviceIndex = 0;
	private DeviceVK m_Device;
	private CommandQueueType m_Type = (CommandQueueType)0;
	private VkPipelineBindPoint m_CurrentPipelineBindPoint = (.)0; //.VK_PIPELINE_BIND_POINT_MAX_ENUM;
	private VkPipelineLayout m_CurrentPipelineLayoutHandle = .Null;
	private PipelineVK m_CurrentPipeline = null;
	private PipelineLayoutVK m_CurrentPipelineLayout = null;
	private FrameBufferVK m_CurrentFrameBuffer = null;
	private VkCommandPool m_CommandPool = .Null;

	public this(DeviceVK device)
	{
		m_Device = device;
	}

	public ~this()
	{
		if (m_CommandPool == .Null)
			return;

		VulkanNative.vkFreeCommandBuffers(m_Device, m_CommandPool, 1, &m_Handle);
	}

	public static implicit operator VkCommandBuffer(Self self) => self.m_Handle;
	public DeviceVK GetDevice() => m_Device;

	public void Create(VkCommandPool commandPool, VkCommandBuffer commandBuffer, CommandQueueType type)
	{
		m_CommandPool = commandPool;
		m_Handle = commandBuffer;
		m_Type = type;
	}

	public Result Create(CommandBufferVulkanDesc commandBufferDesc)
	{
		m_CommandPool = .Null;
		m_Handle = (VkCommandBuffer)commandBufferDesc.vkCommandBuffer;
		m_Type = commandBufferDesc.commandQueueType;

		return Result.SUCCESS;
	}
}