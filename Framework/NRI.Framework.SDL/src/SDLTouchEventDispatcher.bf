using NRI.Framework.Input.Touch;
using SDL2;
namespace NRI.Framework.SDL;

class SDLTouchEventDispatcher : TouchEventDispatcher
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
}