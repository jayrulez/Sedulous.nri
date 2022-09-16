using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;
namespace nri.d3d12;

class DescriptorD3D12 : Descriptor
{
	private Result CreateConstantBufferView(D3D12_CONSTANT_BUFFER_VIEW_DESC desc)
	{
		var desc;
		m_HeapType = .D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV;

		Result result = m_Device.GetDescriptorHandle(m_HeapType, ref m_Handle);
		if (result == Result.SUCCESS)
		{
			m_DescriptorPointerCPU = m_Device.GetDescriptorPointerCPU(m_Handle);
			((ID3D12Device*)m_Device).CreateConstantBufferView(&desc, .() {  ptr = m_DescriptorPointerCPU });
			m_BufferLocation = desc.BufferLocation;
		}

		return result;
	}

	private Result CreateShaderResourceView(ID3D12Resource* resource, D3D12_SHADER_RESOURCE_VIEW_DESC desc)
	{
		var desc;
		m_HeapType = .D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV;

		Result result = m_Device.GetDescriptorHandle(m_HeapType, ref m_Handle);
		if (result == Result.SUCCESS)
		{
			m_DescriptorPointerCPU = m_Device.GetDescriptorPointerCPU(m_Handle);
			((ID3D12Device*)m_Device).CreateShaderResourceView(resource, &desc, .() {  ptr = m_DescriptorPointerCPU });
			m_Resource = resource;
		}

		return result;
	}

	private Result CreateUnorderedAccessView(ID3D12Resource* resource, D3D12_UNORDERED_ACCESS_VIEW_DESC desc, Format format)
	{
		var desc;
		m_HeapType = .D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV;

		Result result = m_Device.GetDescriptorHandle(m_HeapType, ref m_Handle);
		if (result == Result.SUCCESS)
		{
			m_DescriptorPointerCPU = m_Device.GetDescriptorPointerCPU(m_Handle);
			((ID3D12Device*)m_Device).CreateUnorderedAccessView(resource, null, &desc, .() {  ptr = m_DescriptorPointerCPU });
			m_Resource = resource;
			m_IsFloatingPointFormatUAV = IsFloatingPointFormat(format);
		}

		return result;
	}

	private Result CreateRenderTargetView(ID3D12Resource* resource, D3D12_RENDER_TARGET_VIEW_DESC desc)
	{
		var desc;
		m_HeapType = .D3D12_DESCRIPTOR_HEAP_TYPE_RTV;

		Result result = m_Device.GetDescriptorHandle(m_HeapType, ref m_Handle);
		if (result == Result.SUCCESS)
		{
			m_DescriptorPointerCPU = m_Device.GetDescriptorPointerCPU(m_Handle);
			((ID3D12Device*)m_Device).CreateRenderTargetView(resource, &desc, .() {  ptr = m_DescriptorPointerCPU });
			m_Resource = resource;
		}

		return result;
	}

	private Result CreateDepthStencilView(ID3D12Resource* resource, D3D12_DEPTH_STENCIL_VIEW_DESC desc)
	{
		var desc;
		m_HeapType = .D3D12_DESCRIPTOR_HEAP_TYPE_DSV;

		Result result = m_Device.GetDescriptorHandle(m_HeapType, ref m_Handle);
		if (result == Result.SUCCESS)
		{
			m_DescriptorPointerCPU = m_Device.GetDescriptorPointerCPU(m_Handle);
			((ID3D12Device*)m_Device).CreateDepthStencilView(resource, &desc, .() { ptr = m_DescriptorPointerCPU });
			m_Resource = resource;
		}

		return result;
	}

	private DeviceD3D12 m_Device;
	private ID3D12Resource* m_Resource = null;
	private D3D12_GPU_VIRTUAL_ADDRESS m_BufferLocation = 0;
	private DescriptorHandle m_Handle = .();
	private DescriptorPointerCPU m_DescriptorPointerCPU = .();
	private D3D12_DESCRIPTOR_HEAP_TYPE m_HeapType = .D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV;
	private bool m_IsFloatingPointFormatUAV = false;

	public this(DeviceD3D12 device)
	{
		m_Device = device;
	}
	public ~this()
	{
		m_Device.FreeDescriptorHandle(m_HeapType, m_Handle);
	}

	public static implicit operator ID3D12Resource*(Self self) => self.m_Resource;

	public DeviceD3D12 GetDevice() => m_Device;

	public Result Create(BufferViewDesc bufferViewDesc)
	{
		readonly BufferD3D12 buffer = ((BufferD3D12)bufferViewDesc.buffer);
		DXGI_FORMAT format = GetFormat(bufferViewDesc.format);
		uint64 size = bufferViewDesc.size == WHOLE_SIZE ? buffer.GetByteSize() : bufferViewDesc.size;
		uint32 elementSize = GetTexelBlockSize(bufferViewDesc.format);
		uint64 elementOffset;
		uint32 elementNum;


		uint32 structureStride = buffer.GetStructureStride();
		if (structureStride > 0) // structured buffer
		{
			elementOffset = bufferViewDesc.offset / structureStride;
			elementNum = (uint32)(size / structureStride);
		}
		else
		{
			elementOffset = bufferViewDesc.offset / elementSize;
			elementNum = (uint32)(size / elementSize);
		}

		switch (bufferViewDesc.viewType)
		{
		case BufferViewType.CONSTANT:
			{
				D3D12_CONSTANT_BUFFER_VIEW_DESC desc;
				desc.BufferLocation = buffer.GetPointerGPU() + bufferViewDesc.offset;
				desc.SizeInBytes = (uint32)size;

				return CreateConstantBufferView(desc);
			}
		case BufferViewType.SHADER_RESOURCE:
			{
				D3D12_SHADER_RESOURCE_VIEW_DESC desc = .();
				desc.Format = format;
				desc.ViewDimension = .D3D12_SRV_DIMENSION_BUFFER;
				desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
				desc.Buffer.FirstElement = elementOffset;
				desc.Buffer.NumElements = elementNum;
				desc.Buffer.StructureByteStride = structureStride;
				desc.Buffer.Flags = .D3D12_BUFFER_SRV_FLAG_NONE;

				return CreateShaderResourceView(buffer, desc);
			}
		case BufferViewType.SHADER_RESOURCE_STORAGE:
			{
				D3D12_UNORDERED_ACCESS_VIEW_DESC desc = .();
				desc.Format = format;
				desc.ViewDimension = .D3D12_UAV_DIMENSION_BUFFER;
				desc.Buffer.FirstElement = elementOffset;
				desc.Buffer.NumElements = elementNum;
				desc.Buffer.StructureByteStride = structureStride;
				desc.Buffer.CounterOffsetInBytes = 0;
				desc.Buffer.Flags = .D3D12_BUFFER_UAV_FLAG_NONE;

				return CreateUnorderedAccessView(buffer, desc, bufferViewDesc.format);
			}
		default:
			break;
		}

		return Result.FAILURE;
	}
	public Result Create(Texture1DViewDesc textureViewDesc)
	{
		readonly TextureD3D12 texture = (TextureD3D12)textureViewDesc.texture;
		DXGI_FORMAT format = GetFormat(textureViewDesc.format);

		readonly ref D3D12_RESOURCE_DESC textureDesc = ref texture.GetTextureDesc();
		uint32 remainingMipLevels = textureViewDesc.mipNum == REMAINING_MIP_LEVELS ? (textureDesc.MipLevels - textureViewDesc.mipOffset) : textureViewDesc.mipNum;
		uint32 remainingArrayLayers = textureViewDesc.arraySize == REMAINING_ARRAY_LAYERS ? (textureDesc.DepthOrArraySize - textureViewDesc.arrayOffset) : textureViewDesc.arraySize;

		switch (textureViewDesc.viewType)
		{
		case Texture1DViewType.SHADER_RESOURCE_1D:
			{
				D3D12_SHADER_RESOURCE_VIEW_DESC desc = .();
				desc.Format = format;
				desc.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE1D;
				desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
				desc.Texture1D.MostDetailedMip = textureViewDesc.mipOffset;
				desc.Texture1D.MipLevels = remainingMipLevels;
				desc.Texture1D.ResourceMinLODClamp = 0;

				return CreateShaderResourceView(texture, desc);
			}
		case Texture1DViewType.SHADER_RESOURCE_1D_ARRAY:
			{
				D3D12_SHADER_RESOURCE_VIEW_DESC desc;
				desc.Format = format;
				desc.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE1DARRAY;
				desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
				desc.Texture1DArray.MostDetailedMip = textureViewDesc.mipOffset;
				desc.Texture1DArray.MipLevels = remainingMipLevels;
				desc.Texture1DArray.FirstArraySlice = textureViewDesc.arrayOffset;
				desc.Texture1DArray.ArraySize = remainingArrayLayers;
				desc.Texture1DArray.ResourceMinLODClamp = 0;

				return CreateShaderResourceView(texture, desc);
			}
		case Texture1DViewType.SHADER_RESOURCE_STORAGE_1D:
			{
				D3D12_UNORDERED_ACCESS_VIEW_DESC desc = .();
				desc.Format = format;
				desc.ViewDimension = .D3D12_UAV_DIMENSION_TEXTURE1D;
				desc.Texture1D.MipSlice = textureViewDesc.mipOffset;

				return CreateUnorderedAccessView(texture, desc, textureViewDesc.format);
			}
		case Texture1DViewType.SHADER_RESOURCE_STORAGE_1D_ARRAY:
			{
				D3D12_UNORDERED_ACCESS_VIEW_DESC desc = .();
				desc.Format = format;
				desc.ViewDimension = .D3D12_UAV_DIMENSION_TEXTURE1DARRAY;
				desc.Texture1DArray.MipSlice = textureViewDesc.mipOffset;
				desc.Texture1DArray.FirstArraySlice = textureViewDesc.arrayOffset;
				desc.Texture1DArray.ArraySize = remainingArrayLayers;

				return CreateUnorderedAccessView(texture, desc, textureViewDesc.format);
			}
		case Texture1DViewType.COLOR_ATTACHMENT:
			{
				D3D12_RENDER_TARGET_VIEW_DESC desc = .();
				desc.Format = format;
				desc.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE1DARRAY;
				desc.Texture1DArray.MipSlice = textureViewDesc.mipOffset;
				desc.Texture1DArray.FirstArraySlice = textureViewDesc.arrayOffset;
				desc.Texture1DArray.ArraySize = remainingArrayLayers;

				return CreateRenderTargetView(texture, desc);
			}
		case Texture1DViewType.DEPTH_STENCIL_ATTACHMENT:
			{
				D3D12_DEPTH_STENCIL_VIEW_DESC desc = .();
				desc.Format = format;
				desc.ViewDimension = .D3D12_DSV_DIMENSION_TEXTURE1DARRAY;
				desc.Flags = .D3D12_DSV_FLAG_NONE;
				desc.Texture1DArray.MipSlice = textureViewDesc.mipOffset;
				desc.Texture1DArray.FirstArraySlice = textureViewDesc.arrayOffset;
				desc.Texture1DArray.ArraySize = remainingArrayLayers;

				if (textureViewDesc.flags.HasFlag(ResourceViewBits.READONLY_DEPTH))
					desc.Flags |= .D3D12_DSV_FLAG_READ_ONLY_DEPTH;
				if (textureViewDesc.flags.HasFlag(ResourceViewBits.READONLY_STENCIL))
					desc.Flags |= .D3D12_DSV_FLAG_READ_ONLY_STENCIL;

				return CreateDepthStencilView(texture, desc);
			}
		default:
			break;
		}

		return Result.FAILURE;
	}

	public Result Create(Texture2DViewDesc textureViewDesc)
	{
		readonly TextureD3D12 texture = (TextureD3D12)textureViewDesc.texture;
		DXGI_FORMAT format = GetFormat(textureViewDesc.format);
		bool isMultisampled = texture.GetTextureDesc().SampleDesc.Count > 1 ? true : false;

		readonly ref D3D12_RESOURCE_DESC textureDesc = ref texture.GetTextureDesc();
		uint32 remainingMipLevels = textureViewDesc.mipNum == REMAINING_MIP_LEVELS ? (textureDesc.MipLevels - textureViewDesc.mipOffset) : textureViewDesc.mipNum;
		uint32 remainingArrayLayers = textureViewDesc.arraySize == REMAINING_ARRAY_LAYERS ? (textureDesc.DepthOrArraySize - textureViewDesc.arrayOffset) : textureViewDesc.arraySize;

		switch (textureViewDesc.viewType)
		{
		case Texture2DViewType.SHADER_RESOURCE_2D:
			{
				D3D12_SHADER_RESOURCE_VIEW_DESC desc = .();
				desc.Format = GetShaderFormatForDepth(format);
				desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
				if (isMultisampled)
				{
					desc.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE2DMS;
				}
				else
				{
					desc.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE2D;
					desc.Texture2D.MostDetailedMip = textureViewDesc.mipOffset;
					desc.Texture2D.MipLevels = remainingMipLevels;
					desc.Texture2D.PlaneSlice = 0;
					desc.Texture2D.ResourceMinLODClamp = 0;
				}

				return CreateShaderResourceView(texture, desc);
			}
		case Texture2DViewType.SHADER_RESOURCE_2D_ARRAY:
			{
				D3D12_SHADER_RESOURCE_VIEW_DESC desc = .();
				desc.Format = format;
				desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
				if (isMultisampled)
				{
					desc.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE2DMSARRAY;
					desc.Texture2DMSArray.FirstArraySlice = textureViewDesc.arrayOffset;
					desc.Texture2DMSArray.ArraySize = remainingArrayLayers;
				}
				else
				{
					desc.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE2DARRAY;
					desc.Texture2DArray.MostDetailedMip = textureViewDesc.mipOffset;
					desc.Texture2DArray.MipLevels = remainingMipLevels;
					desc.Texture2DArray.FirstArraySlice = textureViewDesc.arrayOffset;
					desc.Texture2DArray.ArraySize = remainingArrayLayers;
					desc.Texture2D.PlaneSlice = 0;
					desc.Texture2DArray.ResourceMinLODClamp = 0;
				}

				return CreateShaderResourceView(texture, desc);
			}
		case Texture2DViewType.SHADER_RESOURCE_CUBE:
			{
				D3D12_SHADER_RESOURCE_VIEW_DESC desc = .();
				desc.Format = format;
				desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
				desc.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURECUBE;
				desc.TextureCube.MostDetailedMip = textureViewDesc.mipOffset;
				desc.TextureCube.MipLevels = remainingMipLevels;

				return CreateShaderResourceView(texture, desc);
			}
		case Texture2DViewType.SHADER_RESOURCE_CUBE_ARRAY:
			{
				D3D12_SHADER_RESOURCE_VIEW_DESC desc = .();
				desc.Format = format;
				desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
				desc.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURECUBEARRAY;
				desc.TextureCubeArray.MostDetailedMip = textureViewDesc.mipOffset;
				desc.TextureCubeArray.MipLevels = remainingMipLevels;
				desc.TextureCubeArray.First2DArrayFace = textureViewDesc.arrayOffset;
				desc.TextureCubeArray.NumCubes = remainingArrayLayers / 6;

				return CreateShaderResourceView(texture, desc);
			}
		case Texture2DViewType.SHADER_RESOURCE_STORAGE_2D:
			{
				D3D12_UNORDERED_ACCESS_VIEW_DESC desc = .();
				desc.Format = format;
				desc.ViewDimension = .D3D12_UAV_DIMENSION_TEXTURE2D;
				desc.Texture2D.MipSlice = textureViewDesc.mipOffset;
				desc.Texture2D.PlaneSlice = 0;

				return CreateUnorderedAccessView(texture, desc, textureViewDesc.format);
			}
		case Texture2DViewType.SHADER_RESOURCE_STORAGE_2D_ARRAY:
			{
				D3D12_UNORDERED_ACCESS_VIEW_DESC desc = .();
				desc.Format = format;
				desc.ViewDimension = .D3D12_UAV_DIMENSION_TEXTURE2DARRAY;
				desc.Texture2DArray.MipSlice = textureViewDesc.mipOffset;
				desc.Texture2DArray.FirstArraySlice = textureViewDesc.arrayOffset;
				desc.Texture2DArray.ArraySize = remainingArrayLayers;
				desc.Texture2DArray.PlaneSlice = 0;

				return CreateUnorderedAccessView(texture, desc, textureViewDesc.format);
			}
		case Texture2DViewType.COLOR_ATTACHMENT:
			{
				D3D12_RENDER_TARGET_VIEW_DESC desc = .();
				desc.Format = format;
				desc.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE2DARRAY;
				desc.Texture2DArray.MipSlice = textureViewDesc.mipOffset;
				desc.Texture2DArray.FirstArraySlice = textureViewDesc.arrayOffset;
				desc.Texture2DArray.ArraySize = remainingArrayLayers;
				desc.Texture2DArray.PlaneSlice = 0;

				return CreateRenderTargetView(texture, desc);
			}
		case Texture2DViewType.DEPTH_STENCIL_ATTACHMENT:
			{
				D3D12_DEPTH_STENCIL_VIEW_DESC desc = .();
				desc.Format = format;
				desc.Flags = .D3D12_DSV_FLAG_NONE;
				desc.ViewDimension = .D3D12_DSV_DIMENSION_TEXTURE2DARRAY;
				desc.Texture2DArray.MipSlice = textureViewDesc.mipOffset;
				desc.Texture2DArray.FirstArraySlice = textureViewDesc.arrayOffset;
				desc.Texture2DArray.ArraySize = remainingArrayLayers;

				if (textureViewDesc.flags.HasFlag(ResourceViewBits.READONLY_DEPTH))
					desc.Flags |= .D3D12_DSV_FLAG_READ_ONLY_DEPTH;
				if (textureViewDesc.flags.HasFlag(ResourceViewBits.READONLY_STENCIL))
					desc.Flags |= .D3D12_DSV_FLAG_READ_ONLY_STENCIL;

				return CreateDepthStencilView(texture, desc);
			}
		default:
			break;
		}

		return Result.FAILURE;
	}

	public Result Create(Texture3DViewDesc textureViewDesc)
	{
		readonly TextureD3D12 texture = (TextureD3D12)textureViewDesc.texture;
		DXGI_FORMAT format = GetFormat(textureViewDesc.format);

		readonly ref D3D12_RESOURCE_DESC textureDesc = ref texture.GetTextureDesc();
		uint32 remainingMipLevels = textureViewDesc.mipNum == REMAINING_MIP_LEVELS ? (textureDesc.MipLevels - textureViewDesc.mipOffset) : textureViewDesc.mipNum;

		switch (textureViewDesc.viewType)
		{
		case Texture3DViewType.SHADER_RESOURCE_3D:
			{
				D3D12_SHADER_RESOURCE_VIEW_DESC desc = .();
				desc.Format = format;
				desc.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE3D;
				desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
				desc.Texture3D.MostDetailedMip = textureViewDesc.mipOffset;
				desc.Texture3D.MipLevels = remainingMipLevels;
				desc.Texture3D.ResourceMinLODClamp = 0;

				return CreateShaderResourceView(texture, desc);
			}
		case Texture3DViewType.SHADER_RESOURCE_STORAGE_3D:
			{
				D3D12_UNORDERED_ACCESS_VIEW_DESC desc = .();
				desc.Format = format;
				desc.ViewDimension = .D3D12_UAV_DIMENSION_TEXTURE3D;
				desc.Texture3D.MipSlice = textureViewDesc.mipOffset;
				desc.Texture3D.FirstWSlice = textureViewDesc.sliceOffset;
				desc.Texture3D.WSize = textureViewDesc.sliceNum;

				return CreateUnorderedAccessView(texture, desc, textureViewDesc.format);
			}
		case Texture3DViewType.COLOR_ATTACHMENT:
			{
				D3D12_RENDER_TARGET_VIEW_DESC desc;
				desc.Format = format;
				desc.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE3D;
				desc.Texture3D.MipSlice = textureViewDesc.mipOffset;
				desc.Texture3D.FirstWSlice = textureViewDesc.sliceOffset;
				desc.Texture3D.WSize = textureViewDesc.sliceNum;

				return CreateRenderTargetView(texture, desc = .());
			}
		default:
			break;
		}

		return Result.FAILURE;
	}
	//#ifdef __ID3D12GraphicsCommandList4_INTERFACE_DEFINED__
	public Result Create(AccelerationStructure accelerationStructure)
	{
		D3D12_SHADER_RESOURCE_VIEW_DESC desc = .();
		desc.ViewDimension = .D3D12_SRV_DIMENSION_RAYTRACING_ACCELERATION_STRUCTURE;
		desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
		desc.RaytracingAccelerationStructure.Location = ((AccelerationStructureD3D12)accelerationStructure).GetHandle(0);

		return CreateShaderResourceView(null, desc);
	}
	//#endif
	public Result Create(SamplerDesc samplerDesc)
	{
		bool useAnisotropy = samplerDesc.anisotropy > 1 ? true : false;
		bool useComparison = samplerDesc.compareFunc != CompareFunc.NONE;

		D3D12_SAMPLER_DESC desc = .();
		desc.Filter = useAnisotropy ?
			GetFilterAnisotropic(samplerDesc.filterExt, useComparison) :
			GetFilterIsotropic(samplerDesc.mip, samplerDesc.magnification, samplerDesc.minification, samplerDesc.filterExt, useComparison);
		desc.AddressU = GetAddressMode(samplerDesc.addressModes.u);
		desc.AddressV = GetAddressMode(samplerDesc.addressModes.v);
		desc.AddressW = GetAddressMode(samplerDesc.addressModes.w);
		desc.MipLODBias = samplerDesc.mipBias;
		desc.MaxAnisotropy = samplerDesc.anisotropy;
		desc.ComparisonFunc = GetComparisonFunc(samplerDesc.compareFunc);
		desc.MinLOD = samplerDesc.mipMin;
		desc.MaxLOD = samplerDesc.mipMax;

		if (samplerDesc.borderColor == BorderColor.FLOAT_OPAQUE_BLACK || samplerDesc.borderColor == BorderColor.INT_OPAQUE_BLACK)
		{
			desc.BorderColor[3] = 1.0f;
		}
		else if (samplerDesc.borderColor == BorderColor.FLOAT_OPAQUE_WHITE || samplerDesc.borderColor == BorderColor.INT_OPAQUE_WHITE)
		{
			desc.BorderColor[0] = 1.0f;
			desc.BorderColor[1] = 1.0f;
			desc.BorderColor[2] = 1.0f;
			desc.BorderColor[3] = 1.0f;
		}

		m_HeapType = .D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER;

		Result result = m_Device.GetDescriptorHandle(m_HeapType, ref m_Handle);
		if (result == Result.SUCCESS)
		{
			m_DescriptorPointerCPU = m_Device.GetDescriptorPointerCPU(m_Handle);
			((ID3D12Device*)m_Device).CreateSampler(&desc, .() { ptr = m_DescriptorPointerCPU });
		}

		return result;
	}

	public DescriptorPointerCPU GetPointerCPU() => m_DescriptorPointerCPU;
	public D3D12_GPU_VIRTUAL_ADDRESS GetBufferLocation() => m_BufferLocation;
	public bool IsFloatingPointUAV() => m_IsFloatingPointFormatUAV;

	public override void SetDebugName(char8* name)
	{
	}
}