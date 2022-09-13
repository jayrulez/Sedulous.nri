using System;
using nri.Helpers;
namespace nri;

abstract class CommandQueue
{
	public abstract void SetDebugName(char8* name);

	public abstract void SubmitWork(WorkSubmissionDesc workSubmissionDesc, DeviceSemaphore deviceSemaphore);
	public abstract void WaitForSemaphore(DeviceSemaphore deviceSemaphore);

	public abstract Result ChangeResourceStates(TransitionBarrierDesc transitionBarriers);
	public abstract Result UploadData(TextureUploadDesc* textureUploadDescs, uint32 textureUploadDescNum,
		BufferUploadDesc* bufferUploadDescs, uint32 bufferUploadDescNum);
	public abstract Result WaitForIdle();
}