namespace NRI;

interface QueryPool
{
	public abstract void SetDebugName(char8* name);
	
	public abstract uint32 GetQuerySize();
}