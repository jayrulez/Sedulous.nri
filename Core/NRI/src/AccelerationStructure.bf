namespace NRI;

abstract class AccelerationStructure
{
	public abstract void SetDebugName(char8* name);

	public abstract Result CreateDescriptor(uint32 physicalDeviceMask, out Descriptor descriptor);

	public abstract void GetMemoryInfo(ref MemoryDesc memoryDesc);
	public abstract uint64 GetUpdateScratchBufferSize();
	public abstract uint64 GetBuildScratchBufferSize();
	public abstract uint64 GetHandle(uint32 physicalDeviceIndex);

}