using Win32.System.Com;
namespace nri.d3dcommon;

/*using System;
[CRepr]
struct IUnknown
{
	public new const Guid IID = .(0x00000000, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public VTable* VT { get => (.)mVT; }

	protected VTable* mVT;

	[CRepr]public struct VTable
	{
		protected new function [CallingConvention(.Stdcall)] System.Windows.COM_IUnknown.HResult(SelfOuter* self, in Guid riid, void** ppvObject) QueryInterface;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) AddRef;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) Release;
	}


	public System.Windows.COM_IUnknown.HResult QueryInterface(in Guid riid, void** ppvObject) mut => VT.[Friend]QueryInterface(&this, riid, ppvObject);

	public uint32 AddRef() mut => VT.[Friend]AddRef(&this);

	public uint32 Release() mut => VT.[Friend]Release(&this);
}

struct COMPtr<T> : IDisposable where T : IUnknown
{
	private T* m_ComPtr = null;

	public void Dispose() mut
	{
		m_ComPtr.Release();
	}
}*/

typealias ComPtr<T> = T*;

public static{
	public static mixin RELEASE(IUnknown* object){
		if(object == null)
			return;

		object.Release();

		//object = null;
	}
}