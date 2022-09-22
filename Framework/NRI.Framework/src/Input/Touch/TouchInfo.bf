using NRI.Framework.Mathematics;
namespace NRI.Framework.Input.Touch;

/// <summary>
/// Represents the parameters of an active touch input.
/// </summary>
public struct TouchInfo
{
	/// <summary>
	/// Initializes a new instance of the <see cref="TouchInfo"/> structure.
	/// </summary>
	/// <param name="timestamp">The timestamp, in ticks, at which the touch began.</param>
	/// <param name="touchID">The unique identifier of the touch event.</param>
	/// <param name="touchIndex">The index of the touch within the current gesture.</param>
	/// <param name="fingerID">The unique identifier of the finger which caused the touch event.</param>
	/// <param name="originX">The normalized x-coordinate at which the touch originated.</param>
	/// <param name="originY">The normalized x-coordinate at which the touch originated.</param>
	/// <param name="currentX">The normalized x-coordinate of the touch.</param>
	/// <param name="currentY">The normalized y-coordinate of the touch.</param>
	/// <param name="pressure">The normalized pressure of the touch.</param>
	/// <param name="isLongPress">A value indicating whether the touch is a long press.</param>
	public this(int64 timestamp, int64 touchID, int32 touchIndex, int64 fingerID,
		float originX, float originY, float currentX, float currentY, float pressure, bool isLongPress)
	{
		this.mTimestamp = timestamp;
		this.mTouchID = touchID;
		this.mTouchIndex = touchIndex;
		this.mFingerID = fingerID;
		this.mOriginX = originX;
		this.mOriginY = originY;
		this.mCurrentX = currentX;
		this.mCurrentY = currentY;
		this.mPressure = pressure;
		this.mDistance = 0;
		this.mIsLongPress = isLongPress;
	}

	/// <summary>
	/// Gets the timestamp, in ticks, at which the touch began.
	/// </summary>
	public int64 Timestamp
	{
		get { return mTimestamp; }
		internal set mut { mTimestamp = value; }
	}

	/// <summary>
	/// Gets the unique identifier of the touch event.
	/// </summary>
	public int64 TouchID
	{
		get { return mTouchID; }
		internal set mut { mTouchID = value; }
	}

	/// <summary>
	/// Gets the index of the touch within the current gesture.
	/// </summary>
	public int32 TouchIndex
	{
		get { return mTouchIndex; }
		internal set mut { mTouchIndex = value; }
	}

	/// <summary>
	/// Gets the internal identifier of the finger which caused the touch event.
	/// </summary>
	public int64 FingerID
	{
		get { return mFingerID; }
		internal set mut { mFingerID = value; }
	}

	/// <summary>
	/// Gets the normalized coordinates of the position at which the touch originated.
	/// </summary>
	public Point2F OriginPosition => Point2F(mOriginX, mOriginY);

	/// <summary>
	/// Gets the normalized x-coordinate at which the touch originated.
	/// </summary>
	public float OriginX
	{
		get { return mOriginX; }
		internal set mut { mOriginX = value; }
	}

	/// <summary>
	/// Gets the normalized y-coordinate at which the touch originated.
	/// </summary>
	public float OriginY
	{
		get { return mOriginY; }
		internal set mut { mOriginY = value; }
	}

	/// <summary>
	/// Gets the normalized coordinates of the touch's current position.
	/// </summary>
	public Point2F CurrentPosition => Point2F(mCurrentX, mCurrentY);

	/// <summary>
	/// Gets the normalized x-coordinate of the touch.
	/// </summary>
	public float CurrentX
	{
		get { return mCurrentX; }
		internal set mut { mCurrentX = value; }
	}

	/// <summary>
	/// Gets the normalized y-coordinate of the touch.
	/// </summary>
	public float CurrentY
	{
		get { return mCurrentY; }
		internal set mut { mCurrentY = value; }
	}

	/// <summary>
	/// Gets the normalized pressure of the touch.
	/// </summary>
	public float Pressure
	{
		get { return mPressure; }
		internal set mut { mPressure = value; }
	}

	/// <summary>
	/// Gets the total distance that the touch has moved.
	/// </summary>
	public float Distance
	{
		get { return mDistance; }
		internal set mut { mDistance = value; }
	}

	/// <summary>
	/// Gets a value indicating whether the touch is a long press.
	/// </summary>
	public bool IsLongPress
	{
		get { return mIsLongPress; }
		internal set mut { mIsLongPress = value; }
	}

	// Property values.
	private int64 mTimestamp;
	private int64 mTouchID;
	private int32 mTouchIndex;
	private int64 mFingerID;
	private float mOriginX;
	private float mOriginY;
	private float mCurrentX;
	private float mCurrentY;
	private float mPressure;
	private float mDistance;
	private bool mIsLongPress;
}