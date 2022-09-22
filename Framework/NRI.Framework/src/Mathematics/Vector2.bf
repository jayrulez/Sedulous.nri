namespace NRI.Framework.Mathematics;

/// <summary>
/// Represents a two-dimensional vector.
/// </summary>
struct Vector2
{
	/// <summary>
	/// The vector's x-coordinate.
	/// </summary>
	public float X;

	/// <summary>
	/// The vector's y-coordinate.
	/// </summary>
	public float Y;

	/// <summary>
	/// Initializes a new instance of the <see cref="Vector2"/> structure with all of its components set to the specified value.
	/// </summary>
	/// <param name="value">The value to which to set the vector's components.</param>
	public this(float value)
	{
	    X = value;
	    Y = value;
	}

	/// <summary>
	/// Initializes a new instance of the <see cref="Vector2"/> structure with the specified x and y components.
	/// </summary>
	/// <param name="x">The vector's x component.</param>
	/// <param name="y">The vector's y component.</param>
	public this(float x, float y){
		X = x;
		Y = y;
	}
}