using Bulkan;
using System;
using System.Collections;
namespace NRI.Vulkan;

class TextureVK : Texture
{
	private VkImage[PHYSICAL_DEVICE_GROUP_MAX_SIZE] m_Handles = .();
	private VkImageAspectFlags m_ImageAspectFlags = (VkImageAspectFlags)0;
	private VkExtent3D m_Extent = .();
	private uint16 m_MipNum = 0;
	private uint16 m_ArraySize = 0;
	private Format m_Format = Format.UNKNOWN;
	private TextureType m_TextureType = (TextureType)0;
	private VkSampleCountFlags m_SampleCount = (VkSampleCountFlags)0;
	private DeviceVK m_Device;
	private bool m_OwnsNativeObjects = false;

	public this(DeviceVK device)
	{
		m_Device = device;
	}

	public ~this()
	{
		if (!m_OwnsNativeObjects)
			return;

		for (uint32 i = 0; i < m_Device.GetPhyiscalDeviceGroupSize(); i++)
		{
			if (m_Handles[i] != .Null)
				VulkanNative.vkDestroyImage(m_Device, m_Handles[i], m_Device.GetAllocationCallbacks());
		}
	}

	public DeviceVK GetDevice() => m_Device;

	public void Create(VkImage handle, VkImageAspectFlags aspectFlags, VkImageType imageType, VkExtent3D extent, Format format)
	{
		m_OwnsNativeObjects = false;
		m_TextureType = NRI.Vulkan.GetTextureType(imageType);
		m_Handles[0] = handle;
		m_ImageAspectFlags = aspectFlags;
		m_Extent = extent;
		m_MipNum = 1;
		m_ArraySize = 1;
		m_Format = format;
		m_SampleCount = .VK_SAMPLE_COUNT_1_BIT;
	}

	public Result Create(TextureDesc textureDesc)
	{
		m_OwnsNativeObjects = true;
		m_TextureType = textureDesc.type;
		m_Extent = .() { width = textureDesc.size[0], height = textureDesc.size[1], depth = textureDesc.size[2] };
		m_MipNum = textureDesc.mipNum;
		m_ArraySize = textureDesc.arraySize;
		m_Format = textureDesc.format;
		m_SampleCount = NRI.Vulkan.GetSampleCount(textureDesc.sampleNum);

		readonly VkImageType imageType = NRI.Vulkan.GetImageType(textureDesc.type);

		readonly VkSharingMode sharingMode =
			m_Device.IsConcurrentSharingModeEnabledForImages() ? .VK_SHARING_MODE_CONCURRENT : .VK_SHARING_MODE_EXCLUSIVE;

		readonly List<uint32> queueIndices = m_Device.GetConcurrentSharingModeQueueIndices();

		VkImageCreateInfo info = .();
		info.sType = .VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
		info.imageType = imageType;
		info.format = ConvertNRIFormatToVK(m_Format);
		info.extent.width = textureDesc.size[0];
		info.extent.height = textureDesc.size[1];
		info.extent.depth = textureDesc.size[2];
		info.mipLevels = textureDesc.mipNum;
		info.arrayLayers = textureDesc.arraySize;
		info.samples = m_SampleCount;
		info.tiling = .VK_IMAGE_TILING_OPTIMAL;
		info.usage = GetImageUsageFlags(textureDesc.usageMask);
		info.sharingMode = sharingMode;
		info.queueFamilyIndexCount = (uint32)queueIndices.Count;
		info.pQueueFamilyIndices = queueIndices.Ptr;
		info.flags = GetImageCreateFlags(m_Format);

		m_ImageAspectFlags = NRI.Vulkan.GetImageAspectFlags(textureDesc.format);

		uint32 physicalDeviceMask = (textureDesc.physicalDeviceMask == WHOLE_DEVICE_GROUP) ? 0xff : textureDesc.physicalDeviceMask;

		for (uint32 i = 0; i < m_Device.GetPhyiscalDeviceGroupSize(); i++)
		{
			if ((1 << i) & physicalDeviceMask != 0)
			{
				readonly VkResult result = VulkanNative.vkCreateImage(m_Device, &info, m_Device.GetAllocationCallbacks(), &m_Handles[i]);

				RETURN_ON_FAILURE!(m_Device.GetLogger(), result == .VK_SUCCESS, GetReturnCode(result),
					"Can't create a texture: vkCreateImage returned {0}.", (int32)result);
			}
		}

		return Result.SUCCESS;
	}

	public Result Create(TextureVulkanDesc textureDesc)
	{
		m_OwnsNativeObjects = false;
		m_Extent = .() { width = textureDesc.size[0], height = textureDesc.size[1], depth = textureDesc.size[2] };
		m_MipNum = textureDesc.mipNum;
		m_ArraySize = textureDesc.arraySize;
		m_Format = ConvertVKFormatToNRI((VkFormat)textureDesc.vkFormat);
		m_ImageAspectFlags = (VkImageAspectFlags)textureDesc.vkImageAspectFlags;
		m_TextureType = NRI.Vulkan.GetTextureType((VkImageType)textureDesc.vkImageType);
		m_SampleCount = (VkSampleCountFlags)textureDesc.sampleNum;

		readonly VkImage handle = (VkImage)textureDesc.vkImage;
		readonly uint32 physicalDeviceMask = GetPhysicalDeviceGroupMask(textureDesc.physicalDeviceMask);

		for (uint32 i = 0; i < m_Device.GetPhyiscalDeviceGroupSize(); i++)
		{
			if ((1 << i) & physicalDeviceMask != 0)
				m_Handles[i] = handle;
		}

		return Result.SUCCESS;
	}

	public VkImage GetHandle(uint32 physicalDeviceIndex) => m_Handles[physicalDeviceIndex];
	public VkImageAspectFlags GetImageAspectFlags() => m_ImageAspectFlags;
	public readonly ref VkExtent3D GetExtent() => ref m_Extent;

	public uint16 GetSize(uint32 dimension, uint32 mipOffset = 0)
	{
		Runtime.Assert(dimension < 3);

		uint16 size = (uint16)((&m_Extent.width)[dimension]);
		size = (uint16)Math.Max(size >> mipOffset, 1);

		// TODO: VK doesn't require manual alignment, but probably we should use it here and during texture creation
		//size = Align( size, dimension < 2 ? (uint16)GetTexelBlockWidth(m_Format) : 1 );

		return size;
	}

	public uint16 GetMipNum() => m_MipNum;
	public uint16 GetArraySize() => m_ArraySize;
	public Format GetFormat() => m_Format;
	public TextureType GetTextureType() => m_TextureType;
	public VkSampleCountFlags GetSampleCount() => m_SampleCount;

	public void ClearHandle()
	{
		for (uint32 i = 0; i < m_Handles.Count; i++)
			m_Handles[i] = .Null;
	}

	public void SetDebugName(char8* name)
	{
		uint64[PHYSICAL_DEVICE_GROUP_MAX_SIZE] handles = .();
		for (uint i = 0; i < handles.Count; i++)
			handles[i] = (uint64)m_Handles[i];

		m_Device.SetDebugNameToDeviceGroupObject(.VK_OBJECT_TYPE_IMAGE, &handles, name);
	}

	public uint64 GetTextureNativeObject(uint32 physicalDeviceIndex)
	{
		return uint64(((TextureVK)this).GetHandle(physicalDeviceIndex));
	}

	public void GetMemoryInfo(MemoryLocation memoryLocation, ref MemoryDesc memoryDesc)
	{
		VkImage handle = .Null;
		for (uint32 i = 0; i < m_Device.GetPhyiscalDeviceGroupSize() && handle == .Null; i++)
			handle = m_Handles[i];

		VkMemoryDedicatedRequirements dedicatedRequirements = .()
			{
				sType = .VK_STRUCTURE_TYPE_MEMORY_DEDICATED_REQUIREMENTS,
				pNext = null
			};

		VkMemoryRequirements2 requirements = .()
			{
				sType = .VK_STRUCTURE_TYPE_MEMORY_REQUIREMENTS_2,
				pNext = &dedicatedRequirements
			};

		VkImageMemoryRequirementsInfo2 info = .()
			{
				sType = .VK_STRUCTURE_TYPE_IMAGE_MEMORY_REQUIREMENTS_INFO_2,
				pNext = null,
				image = handle
			};

		VulkanNative.vkGetImageMemoryRequirements2(m_Device, &info, &requirements);

		memoryDesc.mustBeDedicated = dedicatedRequirements.prefersDedicatedAllocation ||
			dedicatedRequirements.requiresDedicatedAllocation;

		memoryDesc.alignment = (uint32)requirements.memoryRequirements.alignment;
		memoryDesc.size = requirements.memoryRequirements.size;

		MemoryTypeUnpack unpack = .();
		readonly bool found = m_Device.GetMemoryType(memoryLocation, requirements.memoryRequirements.memoryTypeBits, ref unpack.info);
		CHECK(m_Device.GetLogger(), found, "Can't find suitable memory type: {0}", requirements.memoryRequirements.memoryTypeBits);

		unpack.info.isDedicated = dedicatedRequirements.requiresDedicatedAllocation ? 1 : 0;

		memoryDesc.type = unpack.type;
	}

	public void GetTextureVK(uint32 physicalDeviceIndex, ref TextureVulkanDesc textureVulkanDesc)
	{
		textureVulkanDesc = .();
		textureVulkanDesc.vkImage = (NRIVkImage)GetHandle(physicalDeviceIndex);
		textureVulkanDesc.vkFormat = (.)ConvertNRIFormatToVK(GetFormat());
		textureVulkanDesc.vkImageAspectFlags = (.)GetImageAspectFlags();
		textureVulkanDesc.vkImageType = (.)GetImageType(GetTextureType());
		textureVulkanDesc.size[0] = GetSize(0);
		textureVulkanDesc.size[1] = GetSize(1);
		textureVulkanDesc.size[2] = GetSize(2);
		textureVulkanDesc.mipNum = GetMipNum();
		textureVulkanDesc.arraySize = GetArraySize();
		textureVulkanDesc.sampleNum = (uint8)GetSampleCount();
		textureVulkanDesc.physicalDeviceMask = 1 << physicalDeviceIndex;
	}
}

public static
{
	private static void Asserts()
	{
		Compiler.Assert((uint32)TextureType.TEXTURE_1D == 0, "TextureVK.GetSize() depends on TextureType");
		Compiler.Assert((uint32)TextureType.TEXTURE_2D == 1, "TextureVK.GetSize() depends on TextureType");
		Compiler.Assert((uint32)TextureType.TEXTURE_3D == 2, "TextureVK.GetSize() depends on TextureType");
	}
}