namespace NRI;

abstract class Buffer
{
	public abstract void SetDebugName(char8* name);
	
	public abstract void GetMemoryInfo(MemoryLocation memoryLocation, ref MemoryDesc memoryDesc);
	public abstract void* Map( uint64 offset, uint64 size);
	public abstract void Unmap();

	public abstract uint64 GetBufferNativeObject(uint32 physicalDeviceIndex);
}