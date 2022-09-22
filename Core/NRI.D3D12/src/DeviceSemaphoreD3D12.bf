using NRI.D3DCommon;
using Win32.Graphics.Direct3D12;
using Win32.Foundation;
using System;
using System.Diagnostics;
using Win32;
namespace NRI.D3D12;

class DeviceSemaphoreD3D12 : DeviceSemaphore
{
	private DeviceD3D12 m_Device;
	private ComPtr<ID3D12Fence> m_Fence;
	private uint64 m_SignalValue = 0;

	public this(DeviceD3D12 device)
	{
		m_Device = device;
	}
	public ~this()
	{
		m_Fence.Dispose();
	}

	public static implicit operator ID3D12Fence*(Self self) => self.m_Fence.GetInterface();

	public DeviceD3D12 GetDevice() => m_Device;

	public Result Create(bool signaled)
	{
		HRESULT hr = ((ID3D12Device*)m_Device).CreateFence(m_SignalValue, .D3D12_FENCE_FLAG_NONE, ID3D12Fence.IID, (void**)(&m_Fence));
		if (FAILED(hr))
		{
			REPORT_ERROR(m_Device.GetLogger(), "ID3D12Device::CreateFence() failed, error code: 0x{0:X}.", hr);
			return Result.FAILURE;
		}

		if (!signaled)
			m_SignalValue++;

		return Result.SUCCESS;
	}

	public void Signal(ID3D12CommandQueue* commandQueue)
	{
		commandQueue.Signal(m_Fence.Get(), m_SignalValue);
	}

	public void Wait()
	{
		while (m_Fence->GetCompletedValue() != m_SignalValue) { }

		m_SignalValue++;
	}

	public void SetDebugName(char8* name)
	{
		SET_D3D_DEBUG_OBJECT_NAME!(m_Fence, scope String(name));
	}
}