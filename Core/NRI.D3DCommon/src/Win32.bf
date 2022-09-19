using Win32.Foundation;
namespace NRI.d3dcommon;

public static
{
	public static bool SUCCEEDED(HRESULT hr)
	{
		return hr >= 0;
	}

	public static bool FAILED(HRESULT hr)
	{
		return hr < 0;
	}

}