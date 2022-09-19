using NRI.Framework.SDL;
using NRI;
namespace Samples.Triangle;

class Program
{
	public static void Main()
	{
		const GraphicsAPI graphicsAPI = .VULKAN;

		var windowSystem = scope SDLWindowSystem();

		var primaryWindow = windowSystem.CreateWindow(scope $"Triangle @ {graphicsAPI}", 1280, 720, true, graphicsAPI, .. ?);

		defer windowSystem.DestroyWindow(primaryWindow);

		var app = scope TriangleApplication(primaryWindow, graphicsAPI);

		app.Start();

		windowSystem.Run(scope => app.Update);

		app.Stop();
	}
}