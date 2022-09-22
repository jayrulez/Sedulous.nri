namespace NRI.Framework.Mathematics;

struct Point2
{
	/// <summary>
	/// The point's x-coordinate.
	/// </summary>
	public int32 X;

	/// <summary>
	/// The point's y-coordinate.
	/// </summary>
	public int32 Y;

	/// <summary>
	/// Initializes a new instance of the <see cref="Point2"/> structure.
	/// </summary>
	/// <param name="x">The point's x-coordinate.</param>
	/// <param name="y">The point's y-coordinate.</param>
	public this(int32 x, int32 y)
	{
		X = x;
		Y = y;
	}
}