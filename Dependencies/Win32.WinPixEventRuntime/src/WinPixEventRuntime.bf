using Win32.Graphics.Direct3D12;
using System;
using Win32.Foundation;
namespace Win32.WinPixEventRuntime;

[Union, CRepr] struct PIXCaptureParameters
{
	[CRepr]
	public enum PIXCaptureStorage
	{
		Memory = 0,
	}

	[CRepr]
	public struct PixGpuCaptureParameters
	{
		public char16* FileName;
	}
	public PixGpuCaptureParameters GpuCaptureParameters;

	[CRepr]
	public struct PixTimingCaptureParameters
	{
		public char16* FileName;
		public uint32 MaximumToolingMemorySizeMb;
		public PIXCaptureStorage CaptureStorage;

		public BOOL CaptureGpuTiming;

		public BOOL CaptureCallstacks;
		public BOOL CaptureCpuSamples;
		public uint32 CpuSamplesPerSecond;

		public BOOL CaptureFileIO;

		public BOOL CaptureVirtualAllocEvents;
		public BOOL CaptureHeapAllocEvents;
		public BOOL CaptureXMemEvents; // Xbox only
		public BOOL CapturePixMemEvents; // Xbox only
	}
	public PixTimingCaptureParameters TimingCaptureParameters;
}

public static
{
	private static int mLibraryHandle = 0;

	typealias PFN_PIXBeginCapture2 = function void(uint32 captureFlags, PIXCaptureParameters captureParameters);
	typealias PFN_PIXBeginEventOnCommandList = function void(ID3D12GraphicsCommandList* pCommandList, uint64 color,  char8* pFormat);
	typealias PFN_PIXBeginEventOnCommandQueue = function void(ID3D12CommandQueue* pCommandQueue, uint64 color,  char8* pFormat);
	typealias PFN_PIXEndCapture = function void(bool discard);
	typealias PFN_PIXEndEventOnCommandList = function void(ID3D12GraphicsCommandList* pCommandList);
	typealias PFN_PIXEndEventOnCommandQueue = function void(ID3D12CommandQueue* pCommandQueue);
	//typealias PFN_PIXEventsReplaceBlock = function void();
	//typealias PFN_PIXGetCaptureState = function void();
	//typealias PFN_PIXGetThreadInfo = function void();
	//typealias PFN_PIXNotifyWakeFromFenceSignal = function void();
	typealias PFN_PIXReportCounter = function void(char16* name, float value);
	typealias PFN_PIXSetMarkerOnCommandList = function void(ID3D12GraphicsCommandList* pCommandList, uint64 color,  char8* pFormat);
	typealias PFN_PIXSetMarkerOnCommandQueue = function void(ID3D12CommandQueue* pCommandQueue, uint64 color,  char8* pFormat);

	private static PFN_PIXBeginCapture2 PIXBeginCapture2_ptr;
	private static PFN_PIXBeginEventOnCommandList PIXBeginEventOnCommandList_ptr;
	private static PFN_PIXBeginEventOnCommandQueue PIXBeginEventOnCommandQueue_ptr;
	private static PFN_PIXEndCapture PIXEndCapture_ptr;
	private static PFN_PIXEndEventOnCommandList PIXEndEventOnCommandList_ptr;
	private static PFN_PIXEndEventOnCommandQueue PIXEndEventOnCommandQueue_ptr;
	//private static PFN_PIXEventsReplaceBlock PIXEventsReplaceBlock_ptr;
	//private static PFN_PIXGetCaptureState PIXGetCaptureState_ptr;
	//private static PFN_PIXGetThreadInfo PIXGetThreadInfo_ptr;
	//private static PFN_PIXNotifyWakeFromFenceSignal PIXNotifyWakeFromFenceSignal_ptr;
	private static PFN_PIXReportCounter PIXReportCounter_ptr;
	private static PFN_PIXSetMarkerOnCommandList PIXSetMarkerOnCommandList_ptr;
	private static PFN_PIXSetMarkerOnCommandQueue PIXSetMarkerOnCommandQueue_ptr;

	private static Result<T> LoadFunction<T>(StringView functionName) where T : var
	{
		void* func = System.Windows.GetProcAddress((System.Windows.HModule)mLibraryHandle, functionName.ToScopeCStr!());
		if (func == null)
			return .Err;

		return .Ok((T)func);
	}

	public static void Init()
	{
		mLibraryHandle = (int)System.Windows.LoadLibraryA("WinPixEventRuntime.dll");
		if (mLibraryHandle == 0)
		{
			Runtime.FatalError("Failed to load WinPixEventRuntime");
		}

		PIXBeginCapture2_ptr = LoadFunction<PFN_PIXBeginCapture2>("PIXBeginCapture2").GetValueOrDefault();
		PIXBeginEventOnCommandList_ptr = LoadFunction<PFN_PIXBeginEventOnCommandList>("PIXBeginEventOnCommandList").GetValueOrDefault();
		PIXBeginEventOnCommandQueue_ptr = LoadFunction<PFN_PIXBeginEventOnCommandQueue>("PIXBeginEventOnCommandQueue").GetValueOrDefault();
		PIXEndCapture_ptr = LoadFunction<PFN_PIXEndCapture>("PIXEndCapture").GetValueOrDefault();
		PIXEndEventOnCommandList_ptr = LoadFunction<PFN_PIXEndEventOnCommandList>("PIXEndEventOnCommandList").GetValueOrDefault();
		PIXEndEventOnCommandQueue_ptr = LoadFunction<PFN_PIXEndEventOnCommandQueue>("PIXEndEventOnCommandQueue").GetValueOrDefault();
		//PIXEventsReplaceBlock_ptr = LoadFunction<PFN_PIXEventsReplaceBlock>("PIXEventsReplaceBlock").GetValueOrDefault();
		//PIXGetCaptureState_ptr = LoadFunction<PFN_PIXGetCaptureState>("PIXGetCaptureState").GetValueOrDefault();
		//PIXGetThreadInfo_ptr = LoadFunction<PFN_PIXGetThreadInfo>("PIXGetThreadInfo").GetValueOrDefault();
		//PIXNotifyWakeFromFenceSignal_ptr = LoadFunction<PFN_PIXNotifyWakeFromFenceSignal>("PIXNotifyWakeFromFenceSignal").GetValueOrDefault();
		PIXReportCounter_ptr = LoadFunction<PFN_PIXReportCounter>("PIXReportCounter").GetValueOrDefault();
		PIXSetMarkerOnCommandList_ptr = LoadFunction<PFN_PIXSetMarkerOnCommandList>("PIXSetMarkerOnCommandList").GetValueOrDefault();
		PIXSetMarkerOnCommandQueue_ptr = LoadFunction<PFN_PIXSetMarkerOnCommandQueue>("PIXSetMarkerOnCommandQueue").GetValueOrDefault();
	}

	static this()
	{
		Init();
	}

	static ~this()
	{
		System.Windows.FreeLibrary((System.Windows.HModule)mLibraryHandle);
	}

	public static uint32 PIX_COLOR(uint8 r, uint8 g, uint8 b)
	{
		return 0xff000000 | ((uint32)r << 16) | ((uint32)g << 8) | b;
	}

	public static uint32 PIX_COLOR_INDEX(uint8 i) { return i; }

	public const uint32 PIX_COLOR_DEFAULT = PIX_COLOR_INDEX(0);

#region CPU ONLY

	/*[Import("WinPixEventRuntime.lib"), LinkName(.CPP), CallingConvention(.Stdcall)]
	public static extern void PIXBeginEvent(uint64 color,  char8* pFormat, ...);

	[Import("WinPixEventRuntime.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PIXBeginEvent(uint64 color,  char16* pFormat, ...);*/

#endregion CPU ONLY


#region CPU and GPU

	public static void PIXBeginEvent(ID3D12GraphicsCommandList* pCommandList, uint64 color,  StringView format, params Object[] args)
	{
		if (PIXBeginEventOnCommandList_ptr == null)
			return;

		String message = scope .();
		message.AppendF(scope String(format), params args);

		PIXBeginEventOnCommandList_ptr(pCommandList, color, message);
	}

	public static void PIXBeginEvent(ID3D12CommandQueue* pCommandQueue, uint64 color,  StringView format, params Object[] args)
	{
		if (PIXBeginEventOnCommandQueue_ptr == null)
			return;

		String message = scope .();
		message.AppendF(scope String(format), params args);

		PIXBeginEventOnCommandQueue_ptr(pCommandQueue, color, message);
	}
#endregion CPU and GPU

	/*[Import("WinPixEventRuntime.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PIXEndEvent();*/

	public static void PIXEndEvent(ID3D12GraphicsCommandList* pCommandList)
	{
		if (PIXEndEventOnCommandList_ptr == null)
			return;

		PIXEndEventOnCommandList_ptr(pCommandList);
	}

	public static void PIXEndEvent(ID3D12CommandQueue* pCommandQueue)
	{
		if (PIXEndEventOnCommandQueue_ptr == null)
			return;

		PIXEndEventOnCommandQueue_ptr(pCommandQueue);
	}

	/*[Import("WinPixEventRuntime.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PIXSetMarker(uint64 color,  char8* pFormat, ...);

	[Import("WinPixEventRuntime.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PIXSetMarker(uint64 color,  char16* pFormat, ...);*/

	public static void PIXSetMarker(ID3D12GraphicsCommandList* pCommandList, uint64 color,  StringView format, params Object[] args)
	{
		if (PIXSetMarkerOnCommandList_ptr == null)
			return;

		String message = scope .();
		message.AppendF(scope String(format), params args);

		PIXSetMarkerOnCommandList_ptr(pCommandList, color, message);
	}

	public static void PIXSetMarker(ID3D12CommandQueue* pCommandQueue, uint64 color,  StringView format, params Object[] args)
	{
		if (PIXSetMarkerOnCommandQueue_ptr == null)
			return;

		String message = scope .();
		message.AppendF(scope String(format), params args);

		PIXSetMarkerOnCommandQueue_ptr(pCommandQueue, color, message);
	}

	/*[Import("WinPixEventRuntime.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PIXScopedEvent(uint64 color,  char8* pFormat, ...);

	[Import("WinPixEventRuntime.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PIXScopedEvent(uint64 color,  char16* pFormat, ...);

	[Import("WinPixEventRuntime.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PIXScopedEvent(ID3D12GraphicsCommandList* pCommandList, uint64 color,  char16* pFormat, ...);

	[Import("WinPixEventRuntime.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PIXScopedEvent(ID3D12CommandQueue* pCommandQueue, uint64 color,  char16* pFormat, ...);

	[Import("WinPixEventRuntime.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PIXScopedEvent(ID3D12GraphicsCommandList* pCommandList, uint64 color,  char8* pFormat, ...);

	[Import("WinPixEventRuntime.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PIXScopedEvent(ID3D12CommandQueue* pCommandQueue, uint64 color,  char8* pFormat, ...);*/
}