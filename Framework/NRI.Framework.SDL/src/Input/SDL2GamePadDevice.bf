using NRI.Framework.Input.GamePad;
using NRI.Framework.Mathematics;
using SDL2;
using System;
namespace NRI.Framework.SDL.Input;

using internal NRI.Framework.SDL.Input;

/// <summary>
/// Represents the SDL2 implementation of the <see cref="GamePadDevice"/> class.
/// </summary>
public sealed class SDL2GamePadDevice : GamePadDevice
{
	/// <summary>
	/// Initializes a new instance of the <see cref="SDL2GamePadDevice"/> class.
	/// </summary>
	/// <param name="app">The Application instance.</param>
	/// <param name="joystickIndex">The index of the SDL2 joystick device.</param>
	/// <param name="playerIndex">The index of the player that owns the device.</param>
	public this(Application app, int32 joystickIndex, int32 playerIndex)
		: base(app)
	{
		this.timeLastPressAxis = new double[Enum.GetCount<GamePadAxis>()];
		this.timeLastPressButton = new double[Enum.GetCount<GamePadButton>()];

		this.repeatingAxis = new bool[this.timeLastPressAxis.Count];
		this.repeatingButton = new bool[this.timeLastPressButton.Count];

		if ((this.controller = SDL.GameControllerOpen(joystickIndex)) == null)
		{
			Runtime.FatalError();
		}

		this.name = new String(SDL.GameControllerNameForIndex(joystickIndex));
		this.states = new InternalButtonState[Enum.GetCount<GamePadButton>()];
		this.playerIndex = playerIndex;

		var joystick = SDL.GameControllerGetJoystick(controller);

		if ((this.instanceID = SDL.JoystickInstanceID(joystick)) < 0)
		{
			Runtime.FatalError();
		}
	}

	/// <summary>
	/// Receives a message that has been published to a queue.
	/// </summary>
	/// <param name="evt">The SDLEvent that was received.</param>
	internal void HandleEvent(SDL.Event evt)
	{
		switch (evt.type)
		{
		case .ControllerButtondown:
			{
				if (evt.cbutton.which == instanceID)
				{
					if (!isRegistered)
						Register();

					var button = SDLToUltravioletButton((SDL.SDL_GameControllerButton)evt.cbutton.button);
					PutButtonInDownState(button);
				}
			}
			break;

		case .ControllerButtonup:
			{
				if (evt.cbutton.which == instanceID)
				{
					if (!isRegistered)
						Register();

					var button = SDLToUltravioletButton((SDL.SDL_GameControllerButton)evt.cbutton.button);
					PutButtonInUpState(button);
				}
			}
			break;

		case .ControllerAxismotion:
			{
				if (evt.caxis.which == instanceID)
				{
					if (!isRegistered)
						Register();

					OnAxisMotion(evt.caxis);
				}
			}
			break;
		default: break;
		}
	}

	/// <summary>
	/// Gets the pointer to the native SDL2 object that this object represents.
	/// </summary>
	/// <returns>A pointer to the native SDL2 object that this object represents.</returns>
	public SDL.SDL_GameController* ToNative()
	{
		//Contract.EnsureNotDisposed(this, Disposed);

		return controller;
	}

	/// <summary>
	/// Resets the device's state in preparation for the next frame.
	/// </summary>
	public void ResetDeviceState()
	{
		//Contract.EnsureNotDisposed(this, Disposed);

		for (int i = 0; i < states.Count; i++)
		{
			states[i].Reset();
		}
	}

	/// <inheritdoc/>
	public override void Update(FrameworkTime time)
	{
		//Contract.EnsureNotDisposed(this, Disposed);

		lastUpdateTime = time.TotalTime.TotalMilliseconds;

		var leftJoystickVector = LeftJoystickVector;
		if (leftJoystickVector != leftJoystickVectorPrev)
		{
			leftJoystickVectorPrev = leftJoystickVector;
			OnLeftJoystickVectorChanged(leftJoystickVectorPrev);
		}

		var rightJoystickVector = RightJoystickVector;
		if (rightJoystickVector != rightJoystickVectorPrev)
		{
			rightJoystickVectorPrev = rightJoystickVector;
			OnRightJoystickVectorChanged(rightJoystickVector);
		}

		CheckForRepeatedPresses(time);
	}

	/// <inheritdoc/>
	public override bool IsButtonDown(GamePadButton button)
	{
		//Contract.EnsureNotDisposed(this, Disposed);

		var btnval = (int32)button;
		return states[btnval].Down;
	}

	/// <inheritdoc/>
	public override bool IsButtonUp(GamePadButton button)
	{
		//Contract.EnsureNotDisposed(this, Disposed);

		var btnval = (int32)button;
		return states[btnval].Up;
	}

	/// <inheritdoc/>
	public override bool IsButtonPressed(GamePadButton button, bool ignoreRepeats = true)
	{
		//Contract.EnsureNotDisposed(this, Disposed);

		var btnval = (int32)button;
		return states[btnval].Pressed || (!ignoreRepeats && states[btnval].Repeated);
	}

	/// <inheritdoc/>
	public override bool IsButtonReleased(GamePadButton button)
	{
		//Contract.EnsureNotDisposed(this, Disposed);

		var btnval = (int32)button;
		return states[btnval].Released;
	}

	/// <inheritdoc/>
	public override GamePadJoystickDirection GetJoystickDirection(GamePadJoystick joystick, float? threshold = null)
	{
		//Contract.EnsureNotDisposed(this, Disposed);

		var thresholdValue = Math.Abs(threshold ?? AxisDownThreshold);

		var hAxis = GamePadAxis.None;
		var vAxis = GamePadAxis.None;

		switch (joystick)
		{
		case GamePadJoystick.None:
			return GamePadJoystickDirection.None;

		case GamePadJoystick.Left:
			hAxis = GamePadAxis.LeftJoystickX;
			vAxis = GamePadAxis.LeftJoystickY;
			break;

		case GamePadJoystick.Right:
			hAxis = GamePadAxis.RightJoystickX;
			vAxis = GamePadAxis.RightJoystickY;
			break;

		default:
			Runtime.FatalError("joystick");
		}

		var hAxisValue = GetAxisValue(hAxis);
		var vAxisValue = GetAxisValue(vAxis);

		var result = GamePadJoystickDirection.None;

		if (hAxisValue <= -thresholdValue)
			result |= GamePadJoystickDirection.Left;
		else if (hAxisValue >= thresholdValue)
			result |= GamePadJoystickDirection.Right;

		if (vAxisValue <= -thresholdValue)
			result |= GamePadJoystickDirection.Up;
		else if (vAxisValue > thresholdValue)
			result |= GamePadJoystickDirection.Down;

		return result;
	}

	/// <inheritdoc/>
	public override GamePadJoystickDirection GetJoystickDirectionFromAxis(GamePadAxis axis, float? threshold = null)
	{
		//Contract.EnsureNotDisposed(this, Disposed);

		var thresholdValue = Math.Abs(threshold ?? AxisDownThreshold);

		switch (axis)
		{
		case GamePadAxis.None:
			return GamePadJoystickDirection.None;

		case GamePadAxis.LeftTrigger:
		case GamePadAxis.RightTrigger:
			return GamePadJoystickDirection.None;

		case GamePadAxis.LeftJoystickX:
			if (leftJoystickX <= -thresholdValue)
			{
				return GamePadJoystickDirection.Left;
			}
			if (leftJoystickX >= thresholdValue)
			{
				return GamePadJoystickDirection.Right;
			}
			return GamePadJoystickDirection.None;

		case GamePadAxis.LeftJoystickY:
			if (leftJoystickY <= -thresholdValue)
			{
				return GamePadJoystickDirection.Up;
			}
			if (leftJoystickY >= thresholdValue)
			{
				return GamePadJoystickDirection.Down;
			}
			return GamePadJoystickDirection.None;

		case GamePadAxis.RightJoystickX:
			if (rightJoystickX <= -thresholdValue)
			{
				return GamePadJoystickDirection.Left;
			}
			if (rightJoystickX >= thresholdValue)
			{
				return GamePadJoystickDirection.Right;
			}
			return GamePadJoystickDirection.None;

		case GamePadAxis.RightJoystickY:
			if (rightJoystickY <= -thresholdValue)
			{
				return GamePadJoystickDirection.Up;
			}
			if (rightJoystickY >= thresholdValue)
			{
				return GamePadJoystickDirection.Down;
			}
			return GamePadJoystickDirection.None;
		}

		Runtime.FatalError("axis");
	}

	/// <inheritdoc/>
	public override float GetAxisValue(GamePadAxis axis)
	{
		//Contract.EnsureNotDisposed(this, Disposed);

		switch (axis)
		{
		case GamePadAxis.None:
			return 0f;

		case GamePadAxis.LeftJoystickX:
			return leftJoystickX;

		case GamePadAxis.LeftJoystickY:
			return leftJoystickY;

		case GamePadAxis.RightJoystickX:
			return rightJoystickX;

		case GamePadAxis.RightJoystickY:
			return rightJoystickY;

		case GamePadAxis.LeftTrigger:
			return leftTrigger;

		case GamePadAxis.RightTrigger:
			return rightTrigger;
		default:
			Runtime.FatalError("axis");
		}
	}

	/// <inheritdoc/>
	public override bool IsAxisDown(GamePadAxis axis)
	{
		//Contract.EnsureNotDisposed(this, Disposed);

		switch (axis)
		{
		case GamePadAxis.None:
			return false;

		case GamePadAxis.LeftJoystickX:
			return IsAxisDown(leftJoystickX);

		case GamePadAxis.LeftJoystickY:
			return IsAxisDown(leftJoystickY);

		case GamePadAxis.RightJoystickX:
			return IsAxisDown(rightJoystickX);

		case GamePadAxis.RightJoystickY:
			return IsAxisDown(rightJoystickY);

		case GamePadAxis.LeftTrigger:
			return IsAxisDown(leftTrigger);

		case GamePadAxis.RightTrigger:
			return IsAxisDown(rightTrigger);
		default:
			Runtime.FatalError("axis");
		}
	}

	/// <inheritdoc/>
	public override bool IsAxisUp(GamePadAxis axis)
	{
		//Contract.EnsureNotDisposed(this, Disposed);

		switch (axis)
		{
		case GamePadAxis.None:
			return true;

		case GamePadAxis.LeftJoystickX:
			return !IsAxisDown(leftJoystickX);

		case GamePadAxis.LeftJoystickY:
			return !IsAxisDown(leftJoystickY);

		case GamePadAxis.RightJoystickX:
			return !IsAxisDown(rightJoystickX);

		case GamePadAxis.RightJoystickY:
			return !IsAxisDown(rightJoystickY);

		case GamePadAxis.LeftTrigger:
			return !IsAxisDown(leftTrigger);

		case GamePadAxis.RightTrigger:
			return !IsAxisDown(rightTrigger);
		default: Runtime.FatalError("axis");
		}
	}

	/// <inheritdoc/>
	public override bool IsAxisPressed(GamePadAxis axis)
	{
		//Contract.EnsureNotDisposed(this, Disposed);

		switch (axis)
		{
		case GamePadAxis.None:
			return false;

		case GamePadAxis.LeftJoystickX:
			return IsAxisPressed(prevLeftJoystickX, leftJoystickX);

		case GamePadAxis.LeftJoystickY:
			return IsAxisPressed(prevLeftJoystickY, leftJoystickY);

		case GamePadAxis.RightJoystickX:
			return IsAxisPressed(prevRightJoystickX, rightJoystickX);

		case GamePadAxis.RightJoystickY:
			return IsAxisPressed(prevRightJoystickY, rightJoystickY);

		case GamePadAxis.LeftTrigger:
			return IsAxisPressed(prevLeftTrigger, leftTrigger);

		case GamePadAxis.RightTrigger:
			return IsAxisPressed(prevRightTrigger, rightTrigger);
		default: Runtime.FatalError("axis");
		}
	}

	/// <inheritdoc/>
	public override bool IsAxisReleased(GamePadAxis axis)
	{
		//Contract.EnsureNotDisposed(this, Disposed);

		switch (axis)
		{
		case GamePadAxis.None:
			return false;

		case GamePadAxis.LeftJoystickX:
			return IsAxisReleased(prevLeftJoystickX, leftJoystickX);

		case GamePadAxis.LeftJoystickY:
			return IsAxisReleased(prevLeftJoystickY, leftJoystickY);

		case GamePadAxis.RightJoystickX:
			return IsAxisReleased(prevRightJoystickX, rightJoystickX);

		case GamePadAxis.RightJoystickY:
			return IsAxisReleased(prevRightJoystickY, rightJoystickY);

		case GamePadAxis.LeftTrigger:
			return IsAxisReleased(prevLeftTrigger, leftTrigger);

		case GamePadAxis.RightTrigger:
			return IsAxisReleased(prevRightTrigger, rightTrigger);
		default:
			Runtime.FatalError("axis");
		}
	}

	/// <inheritdoc/>
	public override String Name => name;

	/// <inheritdoc/>
	public override int32 PlayerIndex => playerIndex;

	/// <inheritdoc/>
	public override float AxisDownThreshold { get; set; }

	/// <inheritdoc/>
	public override float LeftTrigger => leftTrigger;

	/// <inheritdoc/>
	public override float RightTrigger => rightTrigger;

	/// <inheritdoc/>
	public override float LeftJoystickX => leftJoystickX;

	/// <inheritdoc/>
	public override float LeftJoystickY => leftJoystickY;

	/// <inheritdoc/>
	public override Vector2 LeftJoystickVector => Vector2(leftJoystickX, leftJoystickY);

	/// <inheritdoc/>
	public override float RightJoystickX => rightJoystickX;

	/// <inheritdoc/>
	public override float RightJoystickY => rightJoystickY;

	/// <inheritdoc/>
	public override Vector2 RightJoystickVector => Vector2(rightJoystickX, rightJoystickY);

	/// <inheritdoc/>
	public override bool IsRegistered => isRegistered;

	/// <summary>
	/// Gets the SDL2 instance identifier of the game pad device.
	/// </summary>
	internal int32 InstanceID => instanceID;

	/// <inheritdoc/>
	/*protected override void Dispose(bool disposing)
	{
		if (Disposed)
			return;

		if (disposing)
		{
			if (!Ultraviolet.Disposed)
			{
				Ultraviolet.Messages.Unsubscribe(this);
			}

			instanceID = 0;
		}

		base.Dispose(disposing);
	}*/

	/// <summary>
	/// Converts an SDL2 SDL_GameControllerButton value to an Ultraviolet GamePadButton value.
	/// </summary>
	/// <param name="button">The <see cref="SDL_GameControllerButton"/> value to convert.</param>
	/// <returns>The converted <see cref="GamePadButton"/> value.</returns>
	private static GamePadButton SDLToUltravioletButton(SDL.SDL_GameControllerButton button) => (GamePadButton)(1 + (int)button);

	/// <summary>
	/// Normalizes an SDL2 axis value.
	/// </summary>
	/// <param name="value">The SDL2 axis value to normalize.</param>
	/// <returns>The normalized value.</returns>
	private static float NormalizeAxisValue(int16 value)
	{
		return (value < 0) ? -(value / (float)int16.MinValue) : value / (float)int16.MaxValue;
	}

	/// <summary>
	/// Puts the specified button into the "Down" state if it isn't already in that state.
	/// </summary>
	private void PutButtonInDownState(GamePadButton button)
	{
		var buttonIndex = (int32)button;
		if (states[buttonIndex].Down)
			return;

		states[buttonIndex].OnDown(false);
		timeLastPressButton[buttonIndex] = lastUpdateTime;
		repeatingButton[buttonIndex] = false;
		OnButtonPressed(button, false);
	}

	/// <summary>
	/// Puts the specified direction in the "Up" state if it isn't already in that state.
	/// </summary>
	private void PutButtonInUpState(GamePadButton button)
	{
		var buttonIndex = (int)button;
		if (states[buttonIndex].Up)
			return;

		states[buttonIndex].OnUp();
		timeLastPressButton[buttonIndex] = lastUpdateTime;
		repeatingButton[buttonIndex] = false;
		OnButtonReleased(button);
	}

	/// <summary>
	/// Handles an SDL2 axis motion event.
	/// </summary>
	/// <param name="evt">The SDL2 event data.</param>
	private void OnAxisMotion(SDL.ControllerAxisEvent evt)
	{
		var value = NormalizeAxisValue(evt.axisValue);

		switch ((SDL.SDL_GameControllerAxis)evt.axis)
		{
		case .LeftX:
			prevLeftJoystickX = leftJoystickX;
			leftJoystickX = value;
			OnAxisChanged(GamePadAxis.LeftJoystickX, value);
			CheckForAxisPresses(GamePadAxis.LeftJoystickX, prevLeftJoystickX, value);
			break;

		case .LeftY:
			prevLeftJoystickY = leftJoystickY;
			leftJoystickY = value;
			OnAxisChanged(GamePadAxis.LeftJoystickY, value);
			CheckForAxisPresses(GamePadAxis.LeftJoystickY, prevLeftJoystickY, value);
			break;

		case .RightX:
			prevRightJoystickX = rightJoystickX;
			rightJoystickX = value;
			OnAxisChanged(GamePadAxis.RightJoystickX, value);
			CheckForAxisPresses(GamePadAxis.RightJoystickX, prevRightJoystickX, value);
			break;

		case .RightY:
			prevRightJoystickY = rightJoystickY;
			rightJoystickY = value;
			OnAxisChanged(GamePadAxis.RightJoystickY, value);
			CheckForAxisPresses(GamePadAxis.RightJoystickY, prevRightJoystickY, value);
			break;

		case .TriggerLeft:
			prevLeftTrigger = leftTrigger;
			leftTrigger = value;
			OnAxisChanged(GamePadAxis.LeftTrigger, value);
			CheckForAxisPresses(GamePadAxis.LeftTrigger, prevLeftTrigger, value);
			break;

		case .TriggerRight:
			prevRightTrigger = rightTrigger;
			rightTrigger = value;
			OnAxisChanged(GamePadAxis.RightTrigger, value);
			CheckForAxisPresses(GamePadAxis.RightTrigger, prevRightTrigger, value);
			break;
		default: break;
		}
	}

	/// <summary>
	/// Raises <see cref="GamePadDevice.AxisPressed"/> and <see cref="GamePadDevice.AxisReleased"/> in response
	/// to changes in a particular axis.
	/// </summary>
	/// <param name="axis">The axis to evaluate.</param>
	/// <param name="previousValue">The last known value of the axis.</param>
	/// <param name="currentValue">The current value of the axis.</param>
	private void CheckForAxisPresses(GamePadAxis axis, float previousValue, float currentValue)
	{
		var axisIndex = (int)axis;

		var axisWasDown = IsAxisDown(previousValue);
		var axisIsDown = IsAxisDown(currentValue);

		// Update button states.
		var btnPrev = ButtonFromAxis(axis, previousValue);
		var btnCurrent = ButtonFromAxis(axis, currentValue);

		if (btnPrev != GamePadButton.None && (btnPrev != btnCurrent || !axisIsDown))
			PutButtonInUpState(btnPrev);

		if (btnCurrent != GamePadButton.None && axisIsDown)
			PutButtonInDownState(btnCurrent);

		// Axis went from pressed->pressed but changed direction.
		if (axisIsDown && axisWasDown && Math.Sign(currentValue) != Math.Sign(previousValue))
		{
			timeLastPressAxis[axisIndex] = lastUpdateTime;
			repeatingAxis[axisIndex] = false;

			OnAxisReleased(axis, 0f);
			OnAxisPressed(axis, currentValue, false);

			return;
		}

		// Axis went from pressed->released or released->pressed.
		if (axisWasDown != axisIsDown)
		{
			if (axisIsDown)
			{
				timeLastPressAxis[axisIndex] = lastUpdateTime;
				repeatingAxis[axisIndex] = false;

				OnAxisPressed(axis, currentValue, false);
			}
			else
			{
				OnAxisReleased(axis, currentValue);
			}
		}
	}

	/// <summary>
	/// Raises repeated <see cref="GamePadDevice.AxisPressed"/> and <see cref="GamePadDevice.ButtonPressed"/> events as necessary.
	/// </summary>
	private void CheckForRepeatedPresses(FrameworkTime time)
	{
		for (int i = 0; i < repeatingAxis.Count; i++)
		{
			var axis = (GamePadAxis)i;
			if (!IsAxisDown(axis))
				continue;

			var delay = repeatingAxis[i] ? PressRepeatDelay : PressRepeatInitialDelay;
			if (delay <= time.TotalTime.TotalMilliseconds - timeLastPressAxis[i])
			{
				repeatingAxis[i] = true;
				timeLastPressAxis[i] = time.TotalTime.TotalMilliseconds;

				var value = GetAxisValue(axis);
				OnAxisPressed(axis, value, true);
			}
		}

		for (int i = 0; i < repeatingButton.Count; i++)
		{
			var button = (GamePadButton)i;
			if (!IsButtonDown(button))
				continue;

			var delay = repeatingButton[i] ? PressRepeatDelay : PressRepeatInitialDelay;
			if (delay <= time.TotalTime.TotalMilliseconds - timeLastPressButton[i])
			{
				repeatingButton[i] = true;
				timeLastPressButton[i] = time.TotalTime.TotalMilliseconds;

				OnButtonPressed(button, true);
			}
		}
	}

	/// <summary>
	/// Gets a value indicating whether the specified axis value counts as being "down."
	/// </summary>
	/// <param name="value">The axis' value.</param>
	/// <returns><see langword="true"/> if the axis is down; otherwise, <see langword="false"/>.</returns>
	private bool IsAxisDown(float value)
	{
		return Math.Abs(value) >= AxisDownThreshold;
	}

	/// <summary>
	/// Gets a value indicating whether the specified axis values count as being "pressed."
	/// </summary>
	private bool IsAxisPressed(float previousValue, float currentValue)
	{
		var previousDown = IsAxisDown(previousValue);
		var currentDown = IsAxisDown(currentValue);

		if (currentDown && previousDown && Math.Sign(previousValue) != Math.Sign(currentValue))
			return true;

		if (currentDown && !previousDown)
			return true;

		return false;
	}

	/// <summary>
	/// Gets a value indicating whether the specified axis values count as being "released."
	/// </summary>
	private bool IsAxisReleased(float previousValue, float currentValue)
	{
		var previousDown = IsAxisDown(previousValue);
		var currentDown = IsAxisDown(currentValue);

		if (currentDown && previousDown && Math.Sign(previousValue) != Math.Sign(currentValue))
			return true;

		if (!currentDown && previousDown)
			return true;

		return false;
	}

	/// <summary>
	/// Gets the <see cref="GamePadButton"/> value that corresponds to the specified axis and value.
	/// </summary>
	private GamePadButton ButtonFromAxis(GamePadAxis axis, float value)
	{
		switch (axis)
		{
		case GamePadAxis.LeftJoystickX:
			return Math.Sign(value) < 0 ? GamePadButton.LeftStickLeft : GamePadButton.LeftStickRight;

		case GamePadAxis.LeftJoystickY:
			return Math.Sign(value) < 0 ? GamePadButton.LeftStickUp : GamePadButton.LeftStickDown;

		case GamePadAxis.RightJoystickX:
			return Math.Sign(value) < 0 ? GamePadButton.RightStickLeft : GamePadButton.RightStickRight;

		case GamePadAxis.RightJoystickY:
			return Math.Sign(value) < 0 ? GamePadButton.RightStickUp : GamePadButton.RightStickDown;

		case GamePadAxis.LeftTrigger:
			return GamePadButton.LeftTrigger;

		case GamePadAxis.RightTrigger:
			return GamePadButton.RightTrigger;
		default:
			return GamePadButton.None;
		}
	}

	/// <summary>
	/// Flags the device as registered.
	/// </summary>
	private void Register()
	{
		var input = (SDL2InputManager)Application.GetInput();
		if (input.RegisterGamePadDevice(this))
			isRegistered = true;
	}

	// State values.
	private int32 instanceID;
	private readonly int32 playerIndex;
	private readonly SDL.SDL_GameController* controller;
	private readonly InternalButtonState[] states;
	private double lastUpdateTime;

	// Property values.
	private readonly String name;
	private float leftTrigger;
	private float prevLeftTrigger;
	private float rightTrigger;
	private float prevRightTrigger;
	private Vector2 leftJoystickVectorPrev;
	private float leftJoystickX;
	private float prevLeftJoystickX;
	private float leftJoystickY;
	private float prevLeftJoystickY;
	private Vector2 rightJoystickVectorPrev;
	private float rightJoystickX;
	private float prevRightJoystickX;
	private float rightJoystickY;
	private float prevRightJoystickY;
	private bool isRegistered;

	// Press timers.
	private readonly double[] timeLastPressAxis;
	private readonly double[] timeLastPressButton;
	private readonly bool[] repeatingAxis;
	private readonly bool[] repeatingButton;

	// Repeat delays.
	private const float PressRepeatInitialDelay = 500.0f;
	private const float PressRepeatDelay = 33.0f;

	private EventAccessor<GamePadButtonPressedEventHandler> mButtonPressed = new .() ~ delete _;
	public override EventAccessor<GamePadButtonPressedEventHandler> ButtonPressed => mButtonPressed;

	private EventAccessor<GamePadButtonReleasedEventHandler> mButtonReleased = new .() ~ delete _;
	public override EventAccessor<GamePadButtonReleasedEventHandler> ButtonReleased => mButtonReleased;

	private EventAccessor<GamePadAxisEventHandler> mAxisChanged = new .() ~ delete _;
	public override EventAccessor<GamePadAxisEventHandler> AxisChanged => mAxisChanged;

	private EventAccessor<GamePadAxisPressedEventHandler> mAxisPressed = new .() ~ delete _;
	public override EventAccessor<GamePadAxisPressedEventHandler> AxisPressed => mAxisPressed;

	private EventAccessor<GamePadAxisReleasedEventHandler> mAxisReleased = new .() ~ delete _;
	public override EventAccessor<GamePadAxisReleasedEventHandler> AxisReleased => mAxisReleased;

	private EventAccessor<GamePadAxisVectorEventHandler> mLeftJoystickVectorChanged = new .() ~ delete _;
	public override EventAccessor<GamePadAxisVectorEventHandler> LeftJoystickVectorChanged => mLeftJoystickVectorChanged;

	private EventAccessor<GamePadAxisVectorEventHandler> mRightJoystickVectorChanged = new .() ~ delete _;
	public override EventAccessor<GamePadAxisVectorEventHandler> RightJoystickVectorChanged => mRightJoystickVectorChanged;
}