namespace NRI.Framework.Input.Touch;

/// <summary>
/// Represents the parameters of a tap event.
/// </summary>
public struct TouchTapInfo
{
    /// <summary>
    /// Initializes a new instance of the <see cref="TouchTapInfo"/> structure.
    /// </summary>
    /// <param name="touchID">The unique identifier of the touch which caused the tap.</param>
    /// <param name="fingerID">The unique identifier of the finger which caused the tap.</param>
    /// <param name="x">The normalized x-coordinate at which the tap originated.</param>
    /// <param name="y">The normalized x-coordinate at which the tap originated.</param>
    public this(int64 touchID, int64 fingerID, float x, float y)
    {
        this.mTouchID = touchID;
        this.mFingerID = fingerID;
        this.mX = x;
        this.mY = y;
    }

    /// <summary>
    /// Gets the unique identifier of the finger which caused the tap.
    /// </summary>
    public int64 TouchID => mTouchID;

    /// <summary>
    /// Gets the unique identifier of the finger which caused the tap.
    /// </summary>
    public int64 FingerID => mFingerID;

    /// <summary>
    /// Gets the normalized x-coordinate at which the tap originated.
    /// </summary>
    public float X => mX;

    /// <summary>
    /// Gets the normalized y-coordinate at which the tap originated.
    /// </summary>
    public float Y => mY;

    // Property values.
    private readonly int64 mTouchID;
    private readonly int64 mFingerID;
    private readonly float mX;
    private readonly float mY;
}