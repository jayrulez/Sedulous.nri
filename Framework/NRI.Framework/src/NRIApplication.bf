using System;
using System.Diagnostics;
namespace NRI.Framework;

public static
{
	public static SPIRVBindingOffsets SPIRV_BINDING_OFFSETS = .()
		{
			samplerOffset = 100,
			textureOffset = 200,
			constantBufferOffset = 300,
			storageTextureAndBufferOffset = 400
		};
	public const bool D3D11_COMMANDBUFFER_EMULATION = false;
	public const uint32 DEFAULT_MEMORY_ALIGNMENT = 16;
	public const uint32 BUFFERED_FRAME_MAX_NUM = 2;
	public const uint32 SWAP_CHAIN_TEXTURE_NUM = BUFFERED_FRAME_MAX_NUM;
}

class NRIApplication : Application
{
	protected Window Window { get; private set; }
	protected GraphicsAPI GraphicsAPI = .VULKAN;

	protected Device mDevice = null;

	public this(Window window, GraphicsAPI graphicsAPI)
	{
		Window = window;
		GraphicsAPI = graphicsAPI;
	}

	protected override Result<void> OnStartup()
	{
		if (base.OnStartup() case .Err)
			return .Err;

		DeviceCreationDesc deviceDesc = .()
			{
				graphicsAPI = GraphicsAPI,
				enableAPIValidation = true,
				enableNRIValidation = false,
				D3D11CommandBufferEmulation = D3D11_COMMANDBUFFER_EMULATION,
				spirvBindingOffsets = SPIRV_BINDING_OFFSETS
			};

		Result result = .SUCCESS;

		if (GraphicsAPI == .VULKAN)
		{
			result = NRI.Vulkan.CreateDeviceVK(deviceDesc, out mDevice);
		} else if (GraphicsAPI == .D3D12)
		{
			result = NRI.D3D12.CreateDeviceD3D12(deviceDesc, out mDevice);
		} else
		{
			Runtime.FatalError(scope $"GraphicsAPI {GraphicsAPI} is not supported.");
		}

		if (result != .SUCCESS)
		{
			Debug.WriteLine("Failed to create Device");
			return .Err;
		}

		return .Ok;
	}


	protected override void OnShutdown()
	{
		if (mDevice != null)
		{
			if (GraphicsAPI == .VULKAN)
			{
				NRI.Vulkan.DestroyDeviceVK(mDevice);
			} else if (GraphicsAPI == .D3D12)
			{
				NRI.D3D12.DestroyDeviceD3D12(mDevice);
			} else
			{
				Runtime.FatalError(scope $"GraphicsAPI {GraphicsAPI} is not supported.");
			}
			mDevice = null;
		}

		base.OnShutdown();
	}
}