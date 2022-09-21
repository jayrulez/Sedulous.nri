using NRI.Framework.Input.Mouse;
using SDL2;
namespace NRI.Framework.SDL;

class SDLMouseEventDispatcher : MouseEventDispatcher
{
	private SDLWindow mWindow;

	public this(SDLWindow window)
	{
		mWindow = window;
	}

	internal bool HandleEvent(SDL.Event ev)
	{
		return true;
	}

	internal void HandleWindowEvent(SDL.WindowEventID windowEventID)
	{
	}
}