namespace nri.vulkan;

typealias NRIVkInstance       = uint64;
typealias NRIVkPhysicalDevice = uint64;
typealias NRIVkDevice         = uint64;
typealias NRIVkQueue          = uint64;
typealias NRIVkCommandPool    = void*;
typealias NRIVkCommandBuffer  = uint64;
typealias NRIVkImage          = void*;
typealias NRIVkBuffer         = void*;
typealias NRIVkDeviceMemory   = void*;
typealias NRIVkQueryPool      = void*;
typealias NRIVkPipeline       = void*;
typealias NRIVkDescriptorPool = void*;
typealias NRIVkSemaphore      = void*;
typealias NRIVkFence          = void*;

typealias NRIVkImageView      = void*;
typealias NRIVkBufferView     = void*;

struct DeviceCreationVulkanDesc
{
	public NRIVkInstance vkInstance;
	public NRIVkDevice vkDevice;
	public /*const*/ NRIVkPhysicalDevice* vkPhysicalDevices;
	public uint32 deviceGroupSize;
	public /*const*/ uint32* queueFamilyIndices;
	public uint32 queueFamilyIndexNum;
	public CallbackInterface callbackInterface;
	public MemoryAllocatorInterface memoryAllocatorInterface;
	public bool enableNRIValidation;
	public bool enableAPIValidation;
	public char8** /*const**/ instanceExtensions;
	public uint32 instanceExtensionNum;
	public char8** /*const**/ deviceExtensions;
	public uint32 deviceExtensionNum;
	public char8* vulkanLoaderPath;
}

struct CommandQueueVulkanDesc
{
	public NRIVkQueue vkQueue;
	public uint32 familyIndex;
	public CommandQueueType commandQueueType;
}

struct CommandAllocatorVulkanDesc
{
	public NRIVkCommandPool vkCommandPool;
	public CommandQueueType commandQueueType;
}

struct CommandBufferVulkanDesc
{
	public NRIVkCommandBuffer vkCommandBuffer;
	public CommandQueueType commandQueueType;
}

struct BufferVulkanDesc
{
	public NRIVkBuffer vkBuffer;
	public uint64 bufferSize;
	public Memory* memory;
	public uint64 memoryOffset;
	public uint64 deviceAddress;
	public uint32 physicalDeviceMask;
}

struct TextureVulkanDesc
{
	public NRIVkImage vkImage;
	public uint32 vkFormat;
	public uint32 vkImageAspectFlags;
	public uint32 vkImageType;
	public uint16[3] size;
	public uint16 mipNum;
	public uint16 arraySize;
	public uint8 sampleNum;
	public uint32 physicalDeviceMask;
}

struct MemoryVulkanDesc
{
	public NRIVkDeviceMemory vkDeviceMemory;
	public uint64 size;
	public uint32 memoryTypeIndex;
	public uint32 physicalDeviceMask;
}

struct QueryPoolVulkanDesc
{
	public NRIVkQueryPool vkQueryPool;
	public uint32 vkQueryType;
	public uint32 physicalDeviceMask;
}