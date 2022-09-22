namespace NRI.Framework;

/// <summary>
/// Represents an object which encapsulates some native or implementation-specific resource.
/// </summary>
abstract class ApplicationResource
{
	// Property values.
	private readonly Application mApp;

	/// <summary>
	/// Gets the Application instance.
	/// </summary>
	public Application Application => mApp;

	/// <summary>
	/// Initializes a new instance of the <see cref="ApplicationResource"/> class.
	/// </summary>
	/// <param name="app">The Application instance.</param>
	public this(Application app)
	{
		mApp = app;
	}
}