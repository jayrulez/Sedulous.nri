namespace NRI;

abstract class Descriptor
{
	public abstract void SetDebugName(char8* name);

	public abstract uint64 GetDescriptorNativeObject(uint32 physicalDeviceIndex);
}