using System;
using System.Threading;
using System.Collections;
namespace NRI.Validation;

class DeviceVal : Device
{
	private Device m_Device;
	private String m_Name;
	private CommandQueueVal[COMMAND_QUEUE_TYPE_NUM] m_CommandQueues = .();
	private Dictionary<MemoryType, MemoryLocation> m_MemoryTypeMap;
	private Monitor m_Lock = new .() ~ delete _;
	private uint32 m_PhysicalDeviceNum = 0;
	private uint32 m_PhysicalDeviceMask = 0;
	/*private bool m_IsSwapChainSupported = false;
	private bool m_IsWrapperD3D11Supported = false;
	private bool m_IsWrapperD3D12Supported = false;
	private bool m_IsWrapperVKSupported = false;
	private bool m_IsRayTracingSupported = false;
	private bool m_IsMeshShaderExtSupported = false;*/

	public this(DeviceLogger logger, DeviceAllocator<uint8> allocator, Device device, uint32 physicalDeviceNum)
	{
		m_Device = device;
		m_Name = Allocate!<String>(m_Device.GetAllocator());
		m_PhysicalDeviceNum = physicalDeviceNum;
		m_PhysicalDeviceMask = (1 << (physicalDeviceNum + 1)) - 1;
		m_MemoryTypeMap = Allocate!<Dictionary<MemoryType, MemoryLocation>>(m_Device.GetAllocator());
	}

	public ~this()
	{
		for (uint i = 0; i < m_CommandQueues.Count; i++)
		{
			if (m_CommandQueues[i] != null)
				Deallocate!(GetAllocator(), m_CommandQueues[i]);
		}
		DeviceAllocator<uint8> allocator = m_Device.GetAllocator();

		((Device)m_Device).Destroy();

		Deallocate!(allocator, m_MemoryTypeMap);
	}

	public bool Create()
	{
		return true;
	}

	public void RegisterMemoryType(MemoryType memoryType, MemoryLocation memoryLocation)
	{
		using (m_Lock.Enter())
			m_MemoryTypeMap[memoryType] = memoryLocation;
	}

	public  void* GetNativeObject()
		{ return m_Device.GetDeviceNativeObject(); }

	public uint32 GetPhysicalDeviceNum()
		{ return m_PhysicalDeviceNum; }

	public bool IsPhysicalDeviceMaskValid(uint32 physicalDeviceMask)
		{ return (physicalDeviceMask & m_PhysicalDeviceMask) == physicalDeviceMask; }

	public Monitor GetLock()
		{ return m_Lock; }
}