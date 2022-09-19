namespace NRI;

abstract class QueryPool
{
	public abstract void SetDebugName(char8* name);
	
	public abstract uint32 GetQuerySize();
}