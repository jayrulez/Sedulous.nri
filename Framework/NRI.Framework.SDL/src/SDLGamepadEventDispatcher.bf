using SDL2;
using NRI.Framework.Input.Gamepad;
namespace NRI.Framework.SDL;

class SDLGamepadEventDispatcher : GamepadEventDispatcher
{
	internal bool HandleEvent(SDL.Event ev)
	{
		return true;
	}
}