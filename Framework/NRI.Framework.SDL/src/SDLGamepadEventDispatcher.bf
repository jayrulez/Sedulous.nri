using SDL2;
using NRI.Framework.Input.Gamepad;
namespace NRI.Framework.SDL;

class SDLGamePadEventDispatcher : GamePadEventDispatcher
{
	internal bool HandleEvent(SDL.Event ev)
	{
		return true;
	}
}