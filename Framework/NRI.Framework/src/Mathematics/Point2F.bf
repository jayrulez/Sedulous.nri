using System;
namespace NRI.Framework.Mathematics;

/// <summary>
/// Represents a point in two-dimensional space with single-precision floating point components.
/// </summary>
struct Point2F : IEquatable<Self>
{
	/// <summary>
	/// The point's x-coordinate.
	/// </summary>
	public float X;

	/// <summary>
	/// The point's y-coordinate.
	/// </summary>
	public float Y;

	/// <summary>
	/// Initializes a new instance of the <see cref="Point2F"/> structure.
	/// </summary>
	/// <param name="x">The point's x-coordinate.</param>
	/// <param name="y">The point's y-coordinate.</param>
	public this(float x, float y)
	{
	    X = x;
	    Y = y;
	}

	public bool Equals(Point2F other)
	{
		return X == other.X && Y == other.Y;
	}
}