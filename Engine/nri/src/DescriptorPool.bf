namespace nri;

abstract class DescriptorPool
{
	public abstract void SetDebugName(char8* name);

	public abstract Result AllocateDescriptorSets(PipelineLayout pipelineLayout, uint32 setIndex, DescriptorSet* descriptorSets, uint32 instanceNum, uint32 physicalDeviceMask, uint32 variableDescriptorNum);
	public abstract void Reset();
}