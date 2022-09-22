using System.Collections;
using System.Threading;
namespace NRI.Validation;

class MemoryVal : DeviceObjectVal<Memory>
{
	private List<BufferVal> m_Buffers;
	private List<TextureVal> m_Textures;
	private List<AccelerationStructureVal> m_AccelerationStructures;
	private Monitor m_Lock = new .() ~ delete _;

	private uint64 m_Size = 0;
	private MemoryLocation m_MemoryLocation = MemoryLocation.MAX_NUM;

	public this(DeviceVal device, Memory memory, uint64 size, MemoryLocation memoryLocation) : base(device, memory)
	{
		m_Size = size;
		m_MemoryLocation = memoryLocation;
	}

	public bool HasBoundResources()
	{
		m_Lock.Enter();
		defer m_Lock.Exit();
		return !m_Buffers.IsEmpty || !m_Textures.IsEmpty || !m_AccelerationStructures.IsEmpty;
	}

	public void ReportBoundResources()
	{
		m_Lock.Enter();
		defer m_Lock.Exit();

		for (int i = 0; i < m_Buffers.Count; i++)
		{
			BufferVal buffer = m_Buffers[i];
			REPORT_ERROR(m_Device.GetLogger(), "Buffer ({} '{}') is still bound to the memory.",
				&buffer, buffer.GetDebugName());
		}

		for (int i = 0; i < m_Textures.Count; i++)
		{
			TextureVal texture = m_Textures[i];
			REPORT_ERROR(m_Device.GetLogger(), "Texture ({} '{}') is still bound to the memory.",
				&texture, texture.GetDebugName());
		}

		for (int i = 0; i < m_AccelerationStructures.Count; i++)
		{
			AccelerationStructureVal accelerationStructure = m_AccelerationStructures[i];
			REPORT_ERROR(m_Device.GetLogger(), "AccelerationStructure ({} '{}') is still bound to the memory.",
				&accelerationStructure, accelerationStructure.GetDebugName());
		}
	}

	public  uint64 GetSize()
		{ return m_Size; }

	public MemoryLocation GetMemoryLocation()
		{ return m_MemoryLocation; }

	public void BindBuffer(BufferVal buffer)
	{
		m_Lock.Enter();
		defer m_Lock.Exit();
		m_Buffers.Add(buffer);
		buffer.SetBoundToMemory(this);
	}

	public void BindTexture(TextureVal texture)
	{
		m_Lock.Enter();
		defer m_Lock.Exit();
		m_Textures.Add(texture);
		texture.SetBoundToMemory(this);
	}

	public void BindAccelerationStructure(AccelerationStructureVal accelerationStructure)
	{
		m_Lock.Enter();
		defer m_Lock.Exit();
		m_AccelerationStructures.Add(accelerationStructure);
		accelerationStructure.SetBoundToMemory(this);
	}

	public void UnbindBuffer(BufferVal buffer)
	{
		m_Lock.Enter();
		defer m_Lock.Exit();

		if (!m_Buffers.Contains(buffer))
		{
			REPORT_ERROR(m_Device.GetLogger(), "Unexpected error: Can't find the buffer in the list of bound resources.");
			return;
		}

		m_Buffers.Remove(buffer);
	}

	public void UnbindTexture(TextureVal texture)
	{
		m_Lock.Enter();
		defer m_Lock.Exit();

		if (!m_Textures.Contains(texture))
		{
			REPORT_ERROR(m_Device.GetLogger(), "Unexpected error: Can't find the texture in the list of bound resources.");
			return;
		}

		m_Textures.Remove(texture);
	}

	public void UnbindAccelerationStructure(AccelerationStructureVal accelerationStructure)
	{
		m_Lock.Enter();
		defer m_Lock.Exit();

		if (!m_AccelerationStructures.Contains(accelerationStructure))
		{
			REPORT_ERROR(m_Device.GetLogger(), "Unexpected error: Can't find the acceleration structure in the list of bound resources.");
			return;
		}

		m_AccelerationStructures.Remove(accelerationStructure);
	}


	public void SetDebugName(char8* name)
	{
		m_Name.Set(scope .(name));
		m_ImplObject.SetDebugName(name);
	}
}