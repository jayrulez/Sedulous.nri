namespace NRI;

interface Texture
{
	public abstract void SetDebugName(char8* name);
	
	public abstract void GetMemoryInfo(MemoryLocation memoryLocation, ref MemoryDesc memoryDesc);

	public abstract uint64 GetTextureNativeObject(uint32 physicalDeviceIndex);
}