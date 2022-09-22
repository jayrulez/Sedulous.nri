using System;
namespace NRI.Validation;

public abstract class DeviceObjectBaseVal
{
	protected DeviceVal m_Device;

	public this(DeviceVal device)
	{
		m_Device = m_Device;
	}

	public DeviceVal GetDevice() => m_Device;
}

public abstract class DeviceObjectVal<T> : DeviceObjectBaseVal
{
	protected T m_ImplObject;
	protected String m_Name;

	public this(DeviceVal device, T object)
		: base(device)
	{
		m_ImplObject = object;

		m_Name = Allocate!<String>(device.GetAllocator());
	}

	public T GetImpl() => m_ImplObject;

	public String GetDebugName() => m_Name;
}

public static
{
	public const char8*[?] DESCRIPTOR_TYPE_NAME = .(
		"SAMPLER",
		"CONSTANT_BUFFER",
		"TEXTURE",
		"STORAGE_TEXTURE",
		"BUFFER",
		"STORAGE_BUFFER",
		"STRUCTURED_BUFFER",
		"STORAGE_STRUCTURED_BUFFER",
		"ACCELERATION_STRUCTURE"
		);

	public static void Asserts()
	{
		Compiler.Assert(DESCRIPTOR_TYPE_NAME.Count == (uint32)DescriptorType.MAX_NUM, "descriptor type name array is out of date");
	}

	public static char8* GetDescriptorTypeName(DescriptorType descriptorType)
	{
		return DESCRIPTOR_TYPE_NAME[(uint32)descriptorType];
	}

	public static DeviceVal GetDeviceVal<T>(T object) where T : var
	{
		return ((DeviceObjectBaseVal)object).GetDevice();
	}

	public static mixin NRI_GET_IMPL_PTR<TOut, TObj>(TObj object)
		where TObj : var
		where TOut : var
	{
		object != null ? object.GetImpl() : null
	}

	public static mixin NRI_GET_IMPL_REF<TOut, TObj>(TObj object)
		where TObj : var
		where TOut : var
	{
		(TOut)object.GetImpl()
	}
}