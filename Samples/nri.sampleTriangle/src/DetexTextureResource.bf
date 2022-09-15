using Detex;
using System;
using nri.Helpers;
namespace nri.sampleTriangle;

class DetexTextureResource
{
	public detexTexture** texture = null;
	public String name = new .() ~ delete _;
	public ColorRGBA avgColor = .();
	public uint64 hash = 0;
	public AlphaMode alphaMode = AlphaMode.OPAQUE;
	public Format format = Format.UNKNOWN;
	public uint16 width = 0;
	public uint16 height = 0;
	public uint16 depth = 0;
	public uint16 mipNum = 0;
	public uint16 arraySize = 0;

	public ~this()
	{
		Detex.detexFreeTexture(texture, mipNum);
		texture = null;
	}

	[Inline] public void OverrideFormat(Format fmt)
	{
		this.format = fmt;
	}

	[Inline] public bool IsBlockCompressed()
	{
		return Detex.detexFormatIsCompressed(texture[0].format);
	}

	[Inline] public uint16 GetArraySize()
	{
		return arraySize;
	}

	[Inline] public uint16 GetMipNum()
	{
		return mipNum;
	}

	[Inline] public uint16 GetWidth()
	{
		return width;
	}

	[Inline] public uint16 GetHeight()
	{
		return height;
	}

	[Inline] public uint16 GetDepth()
	{
		return depth;
	}

	[Inline] public Format GetFormat()
	{
		return format;
	}

	public void GetSubresource(ref TextureSubresourceUploadDesc subresource, uint32 mipIndex, uint32 arrayIndex = 0)
	{
		// TODO: 3D images are not supported, "subresource.slices" needs to be allocated to store pointers to all slices of the current mipmap
		Runtime.Assert(GetDepth() == 1);
		//PLATFORM_UNUSED(arrayIndex);

		int32 rowPitch = 0, slicePitch = 0;
		Detex.detexComputePitch(texture[mipIndex].format, texture[mipIndex].width, texture[mipIndex].height, &rowPitch, &slicePitch);

		subresource.slices = texture[mipIndex].data;
		subresource.sliceNum = 1;
		subresource.rowPitch = (uint32)rowPitch;
		subresource.slicePitch = (uint32)slicePitch;
	}
}