namespace nri;

abstract class CommandBuffer
{
	public abstract void SetDebugName(char8* name);

	public abstract Result Begin(DescriptorPool descriptorPool, uint32 physicalDeviceIndex);
	public abstract Result End();

	public abstract void  SetPipeline(Pipeline pipeline);
	public abstract void  SetPipelineLayout(PipelineLayout pipelineLayout);
	public abstract void  SetDescriptorSets(uint32 baseSlot, uint32 descriptorSetNum, DescriptorSet* descriptorSets, uint32* dynamicConstantBufferOffsets);
	public abstract void  SetConstants(uint32 pushConstantIndex, void* data, uint32 size);
	public abstract void  SetDescriptorPool(DescriptorPool descriptorPool);
	public abstract void  PipelineBarrier(TransitionBarrierDesc* transitionBarriers, AliasingBarrierDesc* aliasingBarriers, BarrierDependency dependency);

	public abstract void  BeginRenderPass(FrameBuffer frameBuffer, RenderPassBeginFlag renderPassBeginFlag);
	public abstract void  EndRenderPass();
	public abstract void  SetViewports(Viewport* viewports, uint32 viewportNum);
	public abstract void  SetScissors(Rect* rects, uint32 rectNum);
	public abstract void  SetDepthBounds(float boundsMin, float boundsMax);
	public abstract void  SetStencilReference(uint8 reference);
	public abstract void  SetSamplePositions(SamplePosition* positions, uint32 positionNum);
	public abstract void  ClearAttachments(ClearDesc* clearDescs, uint32 clearDescNum, Rect* rects, uint32 rectNum);
	public abstract void  SetIndexBuffer(Buffer buffer, uint64 offset, IndexType indexType);
	public abstract void  SetVertexBuffers(uint32 baseSlot, uint32 bufferNum, Buffer* buffers, uint64* offsets);

	public abstract void  Draw(uint32 vertexNum, uint32 instanceNum, uint32 baseVertex, uint32 baseInstance);
	public abstract void  DrawIndexed(uint32 indexNum, uint32 instanceNum, uint32 baseIndex, uint32 baseVertex, uint32 baseInstance);
	public abstract void  DrawIndirect(Buffer buffer, uint64 offset, uint32 drawNum, uint32 stride);
	public abstract void  DrawIndexedIndirect(Buffer buffer, uint64 offset, uint32 drawNum, uint32 stride);
	public abstract void  Dispatch(uint32 x, uint32 y, uint32 z);
	public abstract void  DispatchIndirect(Buffer buffer, uint64 offset);
	public abstract void  BeginQuery(QueryPool queryPool, uint32 offset);
	public abstract void  EndQuery(QueryPool queryPool, uint32 offset);
	public abstract void  BeginAnnotation(char8* name);
	public abstract void  EndAnnotation();

	public abstract void  ClearStorageBuffer(ClearStorageBufferDesc clearDesc);
	public abstract void  ClearStorageTexture(ClearStorageTextureDesc clearDesc);
	public abstract void  CopyBuffer(Buffer dstBuffer, uint32 dstPhysicalDeviceIndex, uint64 dstOffset, Buffer srcBuffer, uint32 srcPhysicalDeviceIndex, uint64 srcOffset, uint64 size);
	public abstract void  CopyTexture(Texture dstTexture, uint32 dstPhysicalDeviceIndex, TextureRegionDesc* dstRegionDesc, Texture srcTexture, uint32 srcPhysicalDeviceIndex, TextureRegionDesc* srcRegionDesc);
	public abstract void  UploadBufferToTexture(Texture dstTexture, TextureRegionDesc dstRegionDesc, Buffer srcBuffer, TextureDataLayoutDesc srcDataLayoutDesc);
	public abstract void  ReadbackTextureToBuffer(Buffer dstBuffer, ref TextureDataLayoutDesc dstDataLayoutDesc, Texture srcTexture, TextureRegionDesc srcRegionDesc);
	public abstract void  CopyQueries(QueryPool queryPool, uint32 offset, uint32 num, Buffer dstBuffer, uint64 dstOffset);
	public abstract void  ResetQueries(QueryPool queryPool, uint32 offset, uint32 num);

	public abstract void  BuildTopLevelAccelerationStructure(uint32 instanceNum, Buffer buffer, uint64 bufferOffset,
		AccelerationStructureBuildBits flags, AccelerationStructure dst, Buffer scratch, uint64 scratchOffset);
	public abstract void  BuildBottomLevelAccelerationStructure(uint32 geometryObjectNum, GeometryObject* geometryObjects,
		AccelerationStructureBuildBits flags, AccelerationStructure dst, Buffer scratch, uint64 scratchOffset);
	public abstract void  UpdateTopLevelAccelerationStructure(uint32 instanceNum, Buffer buffer, uint64 bufferOffset,
		AccelerationStructureBuildBits flags, AccelerationStructure dst, AccelerationStructure src, Buffer scratch, uint64 scratchOffset);
	public abstract void  UpdateBottomLevelAccelerationStructure(uint32 geometryObjectNum, GeometryObject* geometryObjects,
		AccelerationStructureBuildBits flags, AccelerationStructure dst, AccelerationStructure src, Buffer scratch, uint64 scratchOffset);

	public abstract void  CopyAccelerationStructure(AccelerationStructure dst, AccelerationStructure src, CopyMode copyMode);
	public abstract void  WriteAccelerationStructureSize(AccelerationStructure* accelerationStructures, uint32 accelerationStructureNum, QueryPool queryPool, uint32 queryPoolOffset);

	public abstract void  DispatchRays(DispatchRaysDesc dispatchRaysDesc);

	public abstract void  DispatchMeshTasks(uint32 taskNum);
}