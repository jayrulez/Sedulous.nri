using NRI.Framework.Input.Keyboard;
using SDL2;
namespace NRI.Framework.SDL;

class SDLKeyboardEventDispatcher : KeyboardEventDispatcher
{
	internal bool HandleEvent(SDL.Event ev)
	{
		return true;
	}
}