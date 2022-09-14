using Bulkan;
namespace nri.vulkan;

class CommandAllocatorVK : CommandAllocator
{
	private VkCommandPool m_Handle = .Null;
	private CommandQueueType m_Type = (CommandQueueType)0;
	private DeviceVK m_Device;
	private bool m_OwnsNativeObjects = false;


	public this(DeviceVK device)
	{
		m_Device = device;
	}
	public ~this()
	{
		if (m_Handle != .Null && m_OwnsNativeObjects)
			VulkanNative.vkDestroyCommandPool(m_Device, m_Handle, m_Device.GetAllocationCallbacks());
	}

	public static implicit operator VkCommandPool(Self self) => self.m_Handle;
	public DeviceVK GetDevice() => m_Device;

	public Result Create(CommandQueue commandQueue, uint32 physicalDeviceMask)
	{
		//MaybeUnused(physicalDeviceMask); // TODO: use it

		m_OwnsNativeObjects = true;
		readonly CommandQueueVK commandQueueImpl = (CommandQueueVK)commandQueue;

		m_Type = commandQueueImpl.GetCommandQueueType();

		/*readonly*/ VkCommandPoolCreateInfo info = .()
			{
				sType = .VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
				pNext = null,
				flags = .VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
				queueFamilyIndex = commandQueueImpl.GetFamilyIndex()
			};

		readonly VkResult result = VulkanNative.vkCreateCommandPool(m_Device, &info, m_Device.GetAllocationCallbacks(), &m_Handle);

		RETURN_ON_FAILURE!(m_Device.GetLogger(), result == .VK_SUCCESS, GetReturnCode(result),
			"Can't create a command pool: vkCreateCommandPool returned {0}.", (int32)result);

		return Result.SUCCESS;
	}

	public Result Create(CommandAllocatorVulkanDesc commandAllocatorDesc)
	{
		m_OwnsNativeObjects = false;
		m_Handle = (VkCommandPool)commandAllocatorDesc.vkCommandPool;
		m_Type = commandAllocatorDesc.commandQueueType;
		return Result.SUCCESS;
	}

	public override void SetDebugName(char8* name)
	{
		m_Device.SetDebugNameToTrivialObject(.VK_OBJECT_TYPE_COMMAND_POOL, (uint64)m_Handle, name);
	}

	public override Result CreateCommandBuffer(out CommandBuffer commandBuffer)
	{
		commandBuffer = ?;
	/*readonly*/ VkCommandBufferAllocateInfo info = .()
			{
				sType = .VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
				pNext = null,
				commandPool = m_Handle,
				level = .VK_COMMAND_BUFFER_LEVEL_PRIMARY,
				commandBufferCount = 1
			};

		VkCommandBuffer commandBufferHandle = .Null;
		readonly VkResult result = VulkanNative.vkAllocateCommandBuffers(m_Device, &info, &commandBufferHandle);

		RETURN_ON_FAILURE!(m_Device.GetLogger(), result == .VK_SUCCESS, GetReturnCode(result),
			"Can't create the command buffer: vkAllocateCommandBuffers returned %d.", (int32)result);

		CommandBufferVK commandBufferImpl = Allocate!<CommandBufferVK>(m_Device.GetAllocator(), m_Device);
		commandBufferImpl.Create(m_Handle, commandBufferHandle, m_Type);

		commandBuffer = (CommandBuffer)commandBufferImpl;

		return Result.SUCCESS;
	}

	public override void Reset()
	{
		readonly VkResult result = VulkanNative.vkResetCommandPool(m_Device, m_Handle, (VkCommandPoolResetFlags)0);

		RETURN_ON_FAILURE!(m_Device.GetLogger(), result == .VK_SUCCESS, void(),
			"Can't reset a command pool. vkResetCommandPool returned {0}.", (int32)result);
	}
}