namespace NRI;

abstract class Pipeline
{
	public abstract void SetDebugName(char8* name);
	
	public abstract Result WriteShaderGroupIdentifiers(uint32 baseShaderGroupIndex, uint32 shaderGroupNum, void* buffer); // TODO: add stride
}