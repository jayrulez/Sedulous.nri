using SDL2;
using System;
namespace NRI.Framework.SDL;

using internal NRI.Framework;

class SDLWindowSystem : WindowSystem
{
	private bool mSDLInitialized = false;

	public override bool IsRunning { get; protected set; }

	private Window mPrimaryWindow;

	public override Window PrimaryWindow => mPrimaryWindow;

	public this()
	{
		if (SDL.Init(.Everything) < 0)
		{
			Runtime.FatalError(scope $"SDL initialization failed: {SDL.GetError()}");
		}
		mSDLInitialized = true;
	}

	public ~this()
	{
		if (mSDLInitialized)
		{
			SDL.Quit();
		}
	}

	public override Result<void> CreateWindow(StringView title, uint32 width, uint32 height, bool isVisible, GraphicsAPI graphicsAPI, out Window window)
	{
		window = new SDLWindow(title, width, height, isVisible, graphicsAPI);

		if(mPrimaryWindow == null)
			mPrimaryWindow = window;

		return .Ok;
	}

	public override void DestroyWindow(Window window)
	{
		delete window;
	}

	protected internal override void CreateMainLoop(delegate void(FrameworkTime time) frameAction)
	{
		SDL.PumpEvents();

		IsRunning = true;

		while (IsRunning)
		{
			if (let sdlWindow = mPrimaryWindow as SDLWindow)
			{
				while (SDL.PollEvent(let ev) != 0)
				{
					sdlWindow.[Friend]OnEvent(ev);

					if (ev.type == .Quit)
					{
						IsRunning = false;
					}
				}
			}

			frameAction(null);
		}
	}

	public override Window GetWindowByID(int windowId)
	{
		return default;
	}
}