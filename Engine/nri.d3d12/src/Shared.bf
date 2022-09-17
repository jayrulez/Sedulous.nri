using System;
using Win32.Graphics.Direct3D;
using Win32.Graphics.Direct3D12;
namespace nri.d3d12;


public static
{
	public const uint32 NRI_TEMP_NODE_MASK = 0x1;

	public static void SET_D3D_DEBUG_OBJECT_NAME<T>(mut T object, StringView name) where T : var
	{
		if (object != null)
		{
			object.SetPrivateData(WKPDID_D3DDebugObjectName, (.)name.Length, name.ToScopedNativeWChar!());
		}
	}
}