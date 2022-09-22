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
	public static DeviceVal GetDeviceVal<T>(T object) where T : var
	{
		return ((DeviceObjectBaseVal)object).GetDevice();
	}

	public static mixin NRI_GET_IMPL_PTR<TOut, TObj>(TObj object)
		where TOut : TObj
		where TObj : var
	{
		object != null ? object.GetImpl() : null
	}

	public static mixin NRI_GET_IMPL_REF<TOut, TObj>(TObj object)
		where TOut : TObj
		where TObj : var
	{
		(TOut)object.GetImpl()
	}
}