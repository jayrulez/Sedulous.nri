namespace NRI;

interface CommandAllocator
{
	public abstract void SetDebugName(char8* name);

	public abstract Result CreateCommandBuffer(out CommandBuffer commandBuffer);
	public abstract void Reset();
}