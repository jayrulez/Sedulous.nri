using System;
namespace NRI.Framework;

abstract class WindowSystem
{
	public abstract Window PrimaryWindow {get;}

	public abstract bool IsRunning {get; protected set; }

	public abstract Result<void> CreateWindow(StringView title, uint32 width, uint32 height, bool isVisible, GraphicsAPI graphicsAPI, out Window window);

	public abstract void DestroyWindow(Window window);

	public abstract Window GetWindowByID(int windowId);

	protected internal abstract void CreateMainLoop(delegate void(FrameworkTime time) frameAction);

	protected internal void Run(delegate void(FrameworkTime time) frameCallback)
	{
		CreateMainLoop(frameCallback);
	}
}