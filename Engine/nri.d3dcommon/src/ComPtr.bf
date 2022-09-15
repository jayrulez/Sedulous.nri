using System;
using Win32.System.Com;
namespace nri.d3dcommon;

/*struct ComPtr<T> : IDisposable where T : IUnknown
{
	private T* m_ComPtr = null;

	public void Dispose() mut
	{
		m_ComPtr.Release();
	}
}*/

typealias ComPtr<T> = T*;