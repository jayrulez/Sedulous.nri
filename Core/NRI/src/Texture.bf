namespace NRI;

abstract class Texture
{
	public abstract void SetDebugName(char8* name);
	
	public abstract void GetMemoryInfo(MemoryLocation memoryLocation, ref MemoryDesc memoryDesc);
}