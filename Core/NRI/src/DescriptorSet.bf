namespace NRI;

abstract class DescriptorSet
{
	public abstract void SetDebugName(char8* name);

	public abstract void UpdateDescriptorRanges(uint32 physicalDeviceMask, uint32 baseRange, uint32 rangeNum, DescriptorRangeUpdateDesc* rangeUpdateDescs);
	public abstract void UpdateDynamicConstantBuffers(uint32 physicalDeviceMask, uint32 baseBuffer, uint32 bufferNum, Descriptor* descriptors);
	public abstract void Copy(DescriptorSetCopyDesc descriptorSetCopyDesc);
}