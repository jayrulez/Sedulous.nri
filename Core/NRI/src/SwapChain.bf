namespace NRI;

abstract class SwapChain
{
	public abstract void SetDebugName(char8* name);

	public abstract Texture* GetTextures(ref uint32 textureNum, ref Format format);
	public abstract uint32 AcquireNextTexture(ref QueueSemaphore textureReadyForRender);
	public abstract Result Present(QueueSemaphore textureReadyForPresent);
	public abstract Result SetHdrMetadata(HdrMetadata hdrMetadata);
}