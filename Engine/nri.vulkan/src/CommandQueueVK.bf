using Bulkan;
using nri.Helpers;
namespace nri.vulkan;

class CommandQueueVK : CommandQueue
{
	private VkQueue m_Handle = .Null;
	private uint32 m_FamilyIndex = (uint32) - 1;
	private CommandQueueType m_Type = (CommandQueueType) - 1;
	private DeviceVK m_Device;

	public this(DeviceVK device)
	{
		m_Device = device;
	}

	public this(DeviceVK device, VkQueue queue, uint32 familyIndex, CommandQueueType type)
	{
		m_Device = device;
		m_Handle = queue;
		m_FamilyIndex = familyIndex;
		m_Type = type;
	}

	public static implicit operator VkQueue(Self self) => self.m_Handle;
	public DeviceVK GetDevice() => m_Device;

	public Result Create(CommandQueueVulkanDesc commandQueueDesc)
	{
		m_Handle = (VkQueue)commandQueueDesc.vkQueue;
		m_FamilyIndex = commandQueueDesc.familyIndex;
		m_Type = commandQueueDesc.commandQueueType;

		return Result.SUCCESS;
	}

	public uint32 GetFamilyIndex() => m_FamilyIndex;
	public CommandQueueType GetCommandQueueType() => m_Type;

	public override void SetDebugName(char8* name)
	{
		m_Device.SetDebugNameToTrivialObject(.VK_OBJECT_TYPE_QUEUE, (uint64)m_Handle, name);
	}

	public override void SubmitWork(WorkSubmissionDesc workSubmissionDesc, DeviceSemaphore deviceSemaphore)
	{
		VkCommandBuffer* commandBuffers = STACK_ALLOC!<VkCommandBuffer>(workSubmissionDesc.commandBufferNum);
		VkSemaphore* waitSemaphores = STACK_ALLOC!<VkSemaphore>(workSubmissionDesc.waitNum);
		VkPipelineStageFlags* waitStages = STACK_ALLOC!<VkPipelineStageFlags>(workSubmissionDesc.waitNum);
		VkSemaphore* signalSemaphores = STACK_ALLOC!<VkSemaphore>(workSubmissionDesc.signalNum);

		VkSubmitInfo submission = .()
			{
				sType = .VK_STRUCTURE_TYPE_SUBMIT_INFO,
				pNext = null,
				waitSemaphoreCount  = workSubmissionDesc.waitNum,
				pWaitSemaphores  = waitSemaphores,
				pWaitDstStageMask  = waitStages,
				commandBufferCount  = workSubmissionDesc.commandBufferNum,
				pCommandBuffers  = commandBuffers,
				signalSemaphoreCount  = workSubmissionDesc.signalNum,
				pSignalSemaphores  = signalSemaphores
			};

		for (uint32 i = 0; i < workSubmissionDesc.commandBufferNum; i++)
			commandBuffers[i] = (CommandBufferVK)workSubmissionDesc.commandBuffers[i];

		for (uint32 i = 0; i < workSubmissionDesc.waitNum; i++)
		{
			waitSemaphores[i] = (QueueSemaphoreVK)workSubmissionDesc.wait[i];
			waitStages[i] = .VK_PIPELINE_STAGE_ALL_COMMANDS_BIT; // TODO: more optimal stage
		}

		for (uint32 i = 0; i < workSubmissionDesc.signalNum; i++)
			*(signalSemaphores++) = (QueueSemaphoreVK)workSubmissionDesc.signal[i];

		VkFence fence = .Null;
		if (deviceSemaphore != null)
			fence = (DeviceSemaphoreVK)deviceSemaphore;

		VkDeviceGroupSubmitInfo deviceGroupInfo = .();
		if (m_Device.GetPhyiscalDeviceGroupSize() > 1)
		{
			uint32* waitSemaphoreDeviceIndices = STACK_ALLOC!<uint32>(workSubmissionDesc.waitNum);
			uint32* commandBufferDeviceMasks = STACK_ALLOC!<uint32>(workSubmissionDesc.commandBufferNum);
			uint32* signalSemaphoreDeviceIndices = STACK_ALLOC!<uint32>(workSubmissionDesc.signalNum);

			for (uint32 i = 0; i < workSubmissionDesc.waitNum; i++)
				waitSemaphoreDeviceIndices[i] = workSubmissionDesc.physicalDeviceIndex;

			for (uint32 i = 0; i < workSubmissionDesc.commandBufferNum; i++)
				commandBufferDeviceMasks[i] = 1u << workSubmissionDesc.physicalDeviceIndex;

			for (uint32 i = 0; i < workSubmissionDesc.signalNum; i++)
				signalSemaphoreDeviceIndices[i] = workSubmissionDesc.physicalDeviceIndex;

			deviceGroupInfo = .()
				{
					sType = .VK_STRUCTURE_TYPE_DEVICE_GROUP_SUBMIT_INFO,
					pNext = null,
					waitSemaphoreCount = workSubmissionDesc.waitNum,
					pWaitSemaphoreDeviceIndices = waitSemaphoreDeviceIndices,
					commandBufferCount = workSubmissionDesc.commandBufferNum,
					pCommandBufferDeviceMasks = commandBufferDeviceMasks,
					signalSemaphoreCount = workSubmissionDesc.signalNum,
					pSignalSemaphoreDeviceIndices = signalSemaphoreDeviceIndices
				};

			submission.pNext = &deviceGroupInfo;
		}

		readonly VkResult result = VulkanNative.vkQueueSubmit(m_Handle, 1, &submission, fence);

		RETURN_ON_FAILURE!(m_Device.GetLogger(), result == .VK_SUCCESS, void(),
			"Can't submit work to a command queue: vkQueueSubmit returned {0}.", (int32)result);
	}

	public override void WaitForSemaphore(DeviceSemaphore deviceSemaphore)
	{
		/*readonly*/ VkFence fence = (DeviceSemaphoreVK)deviceSemaphore;

		const uint64 tenSeconds = 10000000000;

		VkResult result = VulkanNative.vkWaitForFences(m_Device, 1, &fence, .True, tenSeconds);

		RETURN_ON_FAILURE!(m_Device.GetLogger(), result == .VK_SUCCESS, void(),
			"Can't wait on a device semaphore: vkWaitForFences returned {0}.", (int32)result);

		result = VulkanNative.vkResetFences(m_Device, 1, &fence);

		RETURN_ON_FAILURE!(m_Device.GetLogger(), result == .VK_SUCCESS, void(),
			"Can't reset a device semaphore: vkResetFences returned {0}.", (int32)result);
	}

	public override Result ChangeResourceStates(TransitionBarrierDesc transitionBarriers)
	{
		ResourceStateChangeHelper resourceStateChange = scope .(m_Device, this);

		return resourceStateChange.ChangeStates(transitionBarriers);
	}

	public override Result UploadData(nri.Helpers.TextureUploadDesc* textureUploadDescs, uint32 textureUploadDescNum, nri.Helpers.BufferUploadDesc* bufferUploadDescs, uint32 bufferUploadDescNum)
	{
		DataUploadHelper helperDataUpload = scope .(m_Device, m_Device.GetAllocator(), this);

		return helperDataUpload.UploadData(textureUploadDescs, textureUploadDescNum, bufferUploadDescs, bufferUploadDescNum);
	}

	public override Result WaitForIdle()
	{
		VkResult result = VulkanNative.vkQueueWaitIdle(m_Handle);

		RETURN_ON_FAILURE!(m_Device.GetLogger(), result == .VK_SUCCESS, GetReturnCode(result),
			"Can't wait for idle: vkQueueWaitIdle returned {0}.", (int32)result);

		return Result.SUCCESS;
	}
}