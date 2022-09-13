namespace nri;

abstract class CommandAllocator
{
	public abstract void SetDebugName(char8* name);

	public abstract Result CreateCommandBuffer(out CommandBuffer commandBuffer);
	public abstract void Reset();
}