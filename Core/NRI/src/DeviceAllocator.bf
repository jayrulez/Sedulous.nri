using System;
namespace NRI;

sealed class DeviceAllocator<T>
{
	private MemoryAllocatorInterface m_Interface;

	public this(MemoryAllocatorInterface @interface)
	{
		m_Interface = @interface;
	}

	public readonly ref MemoryAllocatorInterface GetInterface()
	{
		return ref m_Interface;
	}
}

public static
{
	[Inline]
	public static T Align<T>(T x, uint alignment) where T : var
	{
		return (T)(((uint)x + alignment - 1) & ~(alignment - 1));
	}

	public static mixin Allocate<T>(DeviceAllocator<uint8> allocator) where T : var
	{
#if USE_CUSTOM_ALLOCATOR
		alloctype(T) data = new:allocator T();
#else
		alloctype(T) data = new T();
#endif
		data
	}

	public static mixin Allocate<T>(DeviceAllocator<uint8> allocator, var p1) where T : var
	{
#if USE_CUSTOM_ALLOCATOR
		alloctype(T) data = new:allocator T(p1);
#else
		alloctype(T) data = new T(p1);
#endif
		data
	}

	public static mixin Allocate<T>(DeviceAllocator<uint8> allocator, var p1, var p2) where T : var
	{
#if USE_CUSTOM_ALLOCATOR
		alloctype(T) data = new:allocator T(p1, p2);
#else
		alloctype(T) data = new T(p1, p2);
#endif
		data
	}

	public static mixin Allocate<T>(DeviceAllocator<uint8> allocator, var p1, var p2, var p3) where T : var
	{
#if USE_CUSTOM_ALLOCATOR
		alloctype(T) data = new:allocator T(p1, p2, p3);
#else
		alloctype(T) data = new T(p1, p2, p3);
#endif
		data
	}

	public static mixin Allocate<T>(DeviceAllocator<uint8> allocator, var p1, var p2, var p3, var p4) where T : var
	{
#if USE_CUSTOM_ALLOCATOR
		alloctype(T) data = new:allocator T(p1, p2, p3, p4);
#else
		alloctype(T) data = new T(p1, p2, p3, p4);
#endif
		data
	}

	public static mixin Allocate<T>(DeviceAllocator<uint8> allocator, var p1, var p2, var p3, var p4, var p5) where T : var
	{
#if USE_CUSTOM_ALLOCATOR
		alloctype(T) data = new:allocator T(p1, p2, p3, p4, p5);
#else
		alloctype(T) data = new T(p1, p2, p3, p4, p5);
#endif
		data
	}

	public static mixin Deallocate<T>(DeviceAllocator<uint8> allocator, T instance) where T : delete
	{
		if (instance != null)
		{
#if USE_CUSTOM_ALLOCATOR
			delete: allocator instance;
#else
			delete instance;
#endif
			//instance = default;
		}
	}

	public static mixin AllocateArray<T>(DeviceAllocator<uint8> allocator, uint arraySize) where T : var
	{
		T* data = null;

#if USE_CUSTOM_ALLOCATOR
		data = new:allocator T[arraySize]*;
#else
		data = new [Align(alignof(T))] T[arraySize]*;
#endif
		data
	}

	public static mixin AllocateArray<T>(DeviceAllocator<uint8> allocator, uint arraySize) where T : new, struct
	{
		T* data = null;

#if USE_CUSTOM_ALLOCATOR
		data = new:allocator T[arraySize]*;
#else
		data = new [Align(alignof(T))] T[arraySize]*;
#endif
		data
	}

	/*public static mixin AllocateArray<T>(DeviceAllocator<uint8> allocator, uint arraySize) where T : new, var
	{
		T* data = null;

#if USE_CUSTOM_ALLOCATOR
		data = new:allocator T[arraySize]*;
#else
		data = new T[arraySize]*;
#endif
		for (uint i = 0; i < arraySize; i++)
		{
#if USE_CUSTOM_ALLOCATOR
			data[i] = new:allocator T();
#else
			data[i] = new T();
#endif
		}

		data
	}*/


	/*public static mixin AllocateArray<T>(DeviceAllocator<uint8> allocator, uint arraySize, var p1) where T : var
	{
		T* data = null;

#if USE_CUSTOM_ALLOCATOR
		data = new:allocator T[arraySize]*;
#else
		data = new T[arraySize]*;
#endif
		for (uint i = 0; i < arraySize; i++)
		{
#if USE_CUSTOM_ALLOCATOR
			data[i] = new:allocator T(p1);
#else
			data[i] = new T(p1);
#endif
		}

		data
	}*/

	public static mixin DeallocateArray<T>(DeviceAllocator<uint8> allocator, T* array, uint arraySize) where T : var
	{
		if (array != null)
		{

#if USE_CUSTOM_ALLOCATOR
		delete: allocator array;
#else
			delete array;
#endif
		}
	}

	public static mixin DeallocateArray<T>(DeviceAllocator<uint8> allocator, T* array, uint arraySize) where T : delete, var
	{
		if (array != null)
		{
			for (uint i = 0; i < arraySize; i++)
			{
#if USE_CUSTOM_ALLOCATOR
				delete: allocator array[i];
#else
				delete array[i];
#endif
			}

#if USE_CUSTOM_ALLOCATOR
			delete: allocator array;
#else
			delete array;
#endif
		}
	}

	private const uint STACK_ALLOC_MAX_SIZE = 65536;

	public static uint CountStackAllocationSize<T>(uint arraySize)
	{
		return (uint)((int)arraySize * sizeof(T) + alignof(T));
	}

	public static mixin ALLOCATE_SCRATCH<T>(Device device, uint arraySize) where T : var
	{
		T* data = null;

		if (CountStackAllocationSize<T>(arraySize) <= STACK_ALLOC_MAX_SIZE)
		{
			if (arraySize > 0)
			{
				data = scope:: [Align(alignof(T))] T[arraySize]*;
			}
		}
		else
		{
			data = AllocateArray!<T>(device.GetAllocator(), arraySize);
		}

		data
	}

	public static mixin FREE_SCRATCH<T>(Device device, T* array, uint arraySize) where T : var
	{
		if (array != null && CountStackAllocationSize<T>(arraySize) > STACK_ALLOC_MAX_SIZE)
		{
			DeallocateArray!<T>(device.GetAllocator(), array, arraySize);
		}
	}

	public static mixin STACK_ALLOC<T>(uint arraySize)
	{
		T* data = null;
		if (arraySize > 0)
		{
			data = scope:: [Align(alignof(T))] T[arraySize]*;
		}
		data
	}
}