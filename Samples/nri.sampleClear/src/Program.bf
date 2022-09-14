namespace nri.sampleClear;

class Program
{
	public static void Main()
	{
		var app = scope ClearApplication("Clear", 1280, 720);

		app.Run();
	}
}