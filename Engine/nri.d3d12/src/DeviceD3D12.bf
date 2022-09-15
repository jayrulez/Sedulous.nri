using nri.d3dcommon;
using Win32.Graphics.Direct3D12;
using System.Collections;
using Win32.Graphics.Dxgi;
using System.Threading;
namespace nri.d3d12;

struct DescriptorHandle
{
	public HeapIndexType heapIndex;
	public HeapOffsetType heapOffset;
}

struct DescriptorHeapDesc
{
	public ComPtr<ID3D12DescriptorHeap> descriptorHeap;
	public DescriptorPointerCPU descriptorPointerCPU;
	public DescriptorPointerGPU descriptorPointerGPU;
	public uint32 descriptorSize;
}

public static
{
	public const uint DESCRIPTOR_HEAP_TYPE_NUM = (.)D3D12_DESCRIPTOR_HEAP_TYPE.D3D12_DESCRIPTOR_HEAP_TYPE_NUM_TYPES;
	public const  uint32 DESCRIPTORS_BATCH_SIZE = 1024;
}

class DeviceD3D12 : Device
{
	private ComPtr<ID3D12Device> m_Device;
//#ifdef __ID3D12Device5_INTERFACE_DEFINED__
	private ComPtr<ID3D12Device5> m_Device5;
//#endif
	private CommandQueueD3D12[COMMAND_QUEUE_TYPE_NUM] m_CommandQueues = .();
	private List<DescriptorHeapDesc> m_DescriptorHeaps;
	private List<List<DescriptorHandle>> m_FreeDescriptors;
	private DeviceDesc m_DeviceDesc = .();
	private Dictionary<uint32, ComPtr<ID3D12CommandSignature>> m_DrawCommandSignatures;
	private Dictionary<uint32, ComPtr<ID3D12CommandSignature>> m_DrawIndexedCommandSignatures;
	private ComPtr<ID3D12CommandSignature> m_DispatchCommandSignature;
	private ComPtr<IDXGIAdapter> m_Adapter;
	private bool m_IsRaytracingSupported = false;
	private bool m_IsMeshShaderSupported = false;
	private bool m_SkipLiveObjectsReporting = false;

	private Monitor[DESCRIPTOR_HEAP_TYPE_NUM] m_FreeDescriptorLocks;
	private Monitor m_DescriptorHeapLock;
	private Monitor m_QueueLock;
}