using System.Diagnostics;
using System;
namespace nri;

public static
{
	public const uint32 PHYSICAL_DEVICE_GROUP_MAX_SIZE = 4;
	public const uint32 COMMAND_QUEUE_TYPE_NUM = (uint32)CommandQueueType.MAX_NUM;

	public static Vendor GetVendorFromID(uint32 vendorID)
	{
		switch (vendorID)
		{
		case 0x10DE: return Vendor.NVIDIA;
		case 0x1002: return Vendor.AMD;
		case 0x8086: return Vendor.INTEL;
		}

		return Vendor.UNKNOWN;
	}

	public static void MessageCallback(void* userArg, char8* message, Message messageType)
	{
		//MaybeUnused(userArg);
		//MaybeUnused(messageType);

		Console.WriteLine(scope String(message));
		Debug.WriteLine(scope String(message));
	}

	static void AbortExecution(void* userArg)
	{
		//MaybeUnused(userArg);

		// todo sed
#if BF_PLATFORM_WINDOWS
//	    DebugBreak();
#else
//	    raise(SIGTRAP);
#endif
	}

	public static void CheckAndSetDefaultCallbacks(ref CallbackInterface callbackInterface)
	{
		if (callbackInterface.MessageCallback == null)
			callbackInterface.MessageCallback = => MessageCallback;

		if (callbackInterface.AbortExecution == null)
			callbackInterface.AbortExecution = => AbortExecution;
	}

	public static mixin RETURN_ON_FAILURE<T>(DeviceLogger logger, bool condition, T returnCode, StringView format)
	{
		if (!condition)
		{
			logger.ReportMessage(.TYPE_ERROR, format);

			return returnCode;
		}
	}

	public static mixin RETURN_ON_FAILURE<T>(DeviceLogger logger, bool condition, T returnCode, StringView format, Object arg1)
	{
		if (!condition)
		{
			logger.ReportMessage(.TYPE_ERROR, format, arg1);

			return returnCode;
		}
	}

	public static mixin RETURN_ON_FAILURE<T>(DeviceLogger logger, bool condition, T returnCode, StringView format, params Object[] args)
	{
		if (!condition)
		{
			logger.ReportMessage(.TYPE_ERROR, format, params args);

			return returnCode;
		}
	}

	public static void REPORT_INFO(DeviceLogger logger, StringView format, params Object[] args)
	{
		logger.ReportMessage(.TYPE_INFO, format, params args);
	}

	public static void REPORT_WARNING(DeviceLogger logger, StringView format, params Object[] args)
	{
		logger.ReportMessage(.TYPE_WARNING, format, params args);
	}

	public static void REPORT_ERROR(DeviceLogger logger, StringView format, params Object[] args)
	{
		logger.ReportMessage(.TYPE_ERROR, format, params args);
	}

	public static void CHECK(DeviceLogger logger, bool condition, StringView format, params Object[] args)
	{
#if DEBUG
		if (!condition)
			logger.ReportMessage(.TYPE_ERROR, format, params args);
#endif
	}
}