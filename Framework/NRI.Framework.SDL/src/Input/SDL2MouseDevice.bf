using NRI.Framework.Mathematics;
using NRI.Framework.Input.Mouse;
using SDL2;
using System;
namespace NRI.Framework.SDL.Input;

using internal NRI.Framework.SDL.Input;

/// <summary>
/// Represents the SDL2 implementation of the MouseDevice class.
/// </summary>
public sealed class SDL2MouseDevice : MouseDevice
{
    /// <summary>
    /// Initializes a new instance of the SDL2MouseDevice class.
    /// </summary>
    /// <param name="app">The Application instance.</param>
    public this(Application app)
        : base(app)
    {
        this.window = Application.GetWindowSystem().PrimaryWindow;

        var buttonCount = Enum.GetCount<MouseButton>();            
        this.states = new InternalButtonState[buttonCount];

        /*uv.Messages.Subscribe(this,
            SDL2UltravioletMessages.SDLEvent);*/
    }

    /// <inheritdoc/>
    internal void HandleEvent(ref SDL.Event evt)
    {
            switch (evt.type)
            {
                case .MouseMotion:
                    {
                        // HACK: On iOS, for some goddamn reason, SDL2 sends us a spurious motion event
                        // with mouse ID 0 when you first touch the screen. This only seems to happen once
                        // so let's just ignore it.
                        if (!ignoredFirstMouseMotionEvent)
                        {
                            SetMousePositionFromDevicePosition(evt.motion.windowID);
                            ignoredFirstMouseMotionEvent = true;
                        }
                        else
                        {
                            if (!isRegistered && evt.motion.which != SDL_TOUCH_MOUSEID)
                                Register(evt.motion.windowID);

                            OnMouseMotion(ref evt.motion);
                        }
                    }
                    break;

                case .MouseButtonDown:
                    {
                        if (!isRegistered && evt.button.which != SDL_TOUCH_MOUSEID)
                            Register(evt.button.windowID);

                        OnMouseButtonDown(ref evt.button);
                    }
                    break;

                case .MouseButtonUp:
                    {
                        if (!isRegistered && evt.button.which != SDL_TOUCH_MOUSEID)
                            Register(evt.button.windowID);

                        OnMouseButtonUp(ref evt.button);
                    }
                    break;

                case .MouseWheel:
                    {
                        if (!isRegistered && evt.wheel.which != SDL_TOUCH_MOUSEID)
                            Register(evt.wheel.windowID);

                        OnMouseWheel(ref evt.wheel);
                    }
                    break;

			default: break;
            }
    }
    
    /// <summary>
    /// Resets the device's state in preparation for the next frame.
    /// </summary>
    public void ResetDeviceState()
    {
        buttonStateClicks       = 0;
        buttonStateDoubleClicks = 0;

        for (int i = 0; i < states.Count; i++)
        {
            states[i].Reset();
        }
    }

    /// <inheritdoc/>
    public override void Update(FrameworkTime time)
    {

    }

    /// <inheritdoc/>
    public override void WarpToWindow(Window window, int32 x, int32 y)
    {
        //Contract.EnsureNotDisposed(this, Disposed);
        //Contract.Require(window, nameof(window));

        window.WarpMouseWithinWindow(x, y);
    }

    /// <inheritdoc/>
    public override void WarpToWindowCenter(Window window)
    {
        //Contract.EnsureNotDisposed(this, Disposed);
        //Contract.Require(window, nameof(window));

        var size = window.ClientSize;
        window.WarpMouseWithinWindow(size.Width / 2, size.Height / 2);
    }

    /// <inheritdoc/>
    public override void WarpToPrimaryWindow(int32 x, int32 y)
    {
        //Contract.EnsureNotDisposed(this, Disposed);

        var primary = Application.GetWindowSystem().PrimaryWindow;
        if (primary == null)
            Runtime.FatalError("NoPrimaryWindow");

        primary.WarpMouseWithinWindow(x, y);
    }

    /// <inheritdoc/>
    public override void WarpToPrimaryWindowCenter()
    {
        //Contract.EnsureNotDisposed(this, Disposed);

        var primary = Application.GetWindowSystem().PrimaryWindow;
        if (primary == null)
            Runtime.FatalError("NoPrimaryWindow");

        var size = primary.ClientSize;
        primary.WarpMouseWithinWindow(size.Width / 2, size.Height / 2);
    }

    /// <inheritdoc/>
    public override Point2? GetPositionInWindow(Window window)
    {
        //Contract.Require(window, nameof(window));

        if (Window != window)
            return null;

        var spos = (Point2)Position;
        var cpos = Window.Compositor.WindowToPoint(spos);

        return cpos;
    }

    /// <inheritdoc/>
    public override bool IsButtonDown(MouseButton button)
    {
        //Contract.EnsureNotDisposed(this, Disposed);

        return states[(int)button].Down;
    }

    /// <inheritdoc/>
    public override bool IsButtonUp(MouseButton button)
    {
        //Contract.EnsureNotDisposed(this, Disposed);

        return states[(int)button].Up;
    }

    /// <inheritdoc/>
    public override bool IsButtonPressed(MouseButton button, bool ignoreRepeats = true)
    {
        //Contract.EnsureNotDisposed(this, Disposed);

        return states[(int)button].Pressed || (!ignoreRepeats && states[(int)button].Repeated);
    }

    /// <inheritdoc/>
    public override bool IsButtonReleased(MouseButton button)
    {
        //Contract.EnsureNotDisposed(this, Disposed);

        return states[(int)button].Released;
    }

    /// <inheritdoc/>
    public override bool IsButtonClicked(MouseButton button)
    {
        //Contract.EnsureNotDisposed(this, Disposed);

        return (buttonStateClicks & (.)SDL_BUTTON(button)) != 0;
    }

    /// <inheritdoc/>
    public override bool IsButtonDoubleClicked(MouseButton button)
    {
        //Contract.EnsureNotDisposed(this, Disposed);

        return (buttonStateDoubleClicks & (.)SDL_BUTTON(button)) != 0;
    }

    /// <inheritdoc/>
    public override bool GetIsRelativeModeEnabled()
    {
        //Contract.EnsureNotDisposed(this, Disposed);

        return SDL.GetRelativeMouseMode();
    }

    /// <inheritdoc/>
    public override bool SetIsRelativeModeEnabled(bool enabled)
    {
        //Contract.EnsureNotDisposed(this, Disposed);

        var result = SDL.SetRelativeMouseMode(enabled);
        if (result == -1)
            return false;

        if (result < 0)
            Runtime.FatalError("Failed to set relative mouse mode.");

        relativeMode = enabled;
        return true;
    }

    /// <inheritdoc/>
    public override Window Window => window;

    /// <inheritdoc/>
    public override Point2 Position => Point2(x, y);

    /// <inheritdoc/>
    public override int32 X => x;

    /// <inheritdoc/>
    public override int32 Y => y;

    /// <inheritdoc/>
    public override int32 WheelDeltaX => wheelDeltaX;

    /// <inheritdoc/>
    public override int32 WheelDeltaY => wheelDeltaY;

    /// <inheritdoc/>
    public override bool IsRegistered => isRegistered;

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
        }

        base.Dispose(disposing);
    }*/

    /// <summary>
    /// Creates the SDL2 button state mask that corresponds to the specified button.
    /// </summary>
    /// <param name="button">The button for which to create a state mask.</param>
    /// <returns>The state mask for the specified button.</returns>
    private static int32 SDL_BUTTON(int32 button)
    {
        return 1 << (button - 1);
    }

    /// <summary>
    /// Creates the SDL2 button state mask that corresponds to the specified button.
    /// </summary>
    /// <param name="button">The button for which to create a state mask.</param>
    /// <returns>The state mask for the specified button.</returns>
    private static int32 SDL_BUTTON(MouseButton button)
    {
        switch (button)
        {
            case MouseButton.None:
                return 0;
            case MouseButton.Left:
                return SDL_BUTTON(1);
            case MouseButton.Middle:
                return SDL_BUTTON(2);
            case MouseButton.Right:
                return SDL_BUTTON(3);
            case MouseButton.XButton1:
                return SDL_BUTTON(4);
            case MouseButton.XButton2:
                return SDL_BUTTON(5);
        default:
			Runtime.FatalError("button");
		}
    }

    /// <summary>
    /// Gets the Ultraviolet MouseButton value that corresponds to the specified SDL2 button value.
    /// </summary>
    /// <param name="value">The SDL2 button value to convert.</param>
    /// <returns>The Ultraviolet MouseButton value that corresponds to the specified SDL2 button value.</returns>
    private static MouseButton GetUltravioletButton(int32 value)
    {
        if (value == 0)
            return MouseButton.None;

        switch (value)
        {
            case SDL.SDL_BUTTON_LEFT:
                return MouseButton.Left;
            case SDL.SDL_BUTTON_MIDDLE:
                return MouseButton.Middle;
            case SDL.SDL_BUTTON_RIGHT:
                return MouseButton.Right;
            case SDL.SDL_BUTTON_X1:
                return MouseButton.XButton1;
            case SDL.SDL_BUTTON_X2:
                return MouseButton.XButton2;
        }
        Runtime.FatalError("value");
    }

    /// <summary>
    /// Handles SDL2's MOUSEMOTION event.
    /// </summary>
    private void OnMouseMotion(ref SDL.MouseMotionEvent evt)
    {
        if (!Application.GetInput().EmulateMouseWithTouchInput && evt.which == SDL_TOUCH_MOUSEID)
            return;

        if (relativeMode)
        {
            SetMousePosition(evt.windowID, evt.x, evt.y);
            OnMoved(window, evt.x, evt.y, evt.xrel, evt.yrel);
        }
        else
        {
            SetMousePosition(evt.windowID, evt.x, evt.y);
            OnMoved(window, evt.x, evt.y, evt.xrel, evt.yrel);
        }
    }

    /// <summary>
    /// Handles SDL2's MOUSEBUTTONDOWN event.
    /// </summary>
    private void OnMouseButtonDown(ref SDL.MouseButtonEvent evt)
    {
        if (!Application.GetInput().EmulateMouseWithTouchInput && evt.which == SDL_TOUCH_MOUSEID)
            return;

        var window = Application.GetWindowSystem().GetWindowByID((int)evt.windowID);
        var button = GetUltravioletButton(evt.button);

        this.states[(int)button].OnDown(false);

        OnButtonPressed(window, button);
    }

    /// <summary>
    /// Handles SDL2's MOUSEBUTTONUP event.
    /// </summary>
    private void OnMouseButtonUp(ref SDL.MouseButtonEvent evt)
    {
        if (!Application.GetInput().EmulateMouseWithTouchInput && evt.which == SDL_TOUCH_MOUSEID)
            return;

        var window = Application.GetWindowSystem().GetWindowByID((int)evt.windowID);
        var button = GetUltravioletButton(evt.button);

        this.states[(int)button].OnUp();
        
        if (evt.clicks == 1)
        {
            buttonStateClicks |= (uint32)SDL_BUTTON(evt.button);
            OnClick(window, button);
        }

        if (evt.clicks == 2)
        {
            buttonStateDoubleClicks |= (uint32)SDL_BUTTON(evt.button);
            OnDoubleClick(window, button);
        }

        OnButtonReleased(window, button);
    }

    /// <summary>
    /// Handles SDL2's MOUSEWHEEL event.
    /// </summary>
    private void OnMouseWheel(ref SDL.MouseWheelEvent evt)
    {
        if (!Application.GetInput().EmulateMouseWithTouchInput && evt.which == SDL_TOUCH_MOUSEID)
            return;

        var window = Application.GetWindowSystem().GetWindowByID((int)evt.windowID);
        wheelDeltaX = evt.x;
        wheelDeltaY = evt.y;
        OnWheelScrolled(window, evt.x, evt.y);
    }

    /// <summary>
    /// Flags the device as registered.
    /// </summary>
    private void Register(uint32 windowID)
    {
        var input = (SDL2InputManager)Application.GetInput();
        if (input.RegisterMouseDevice(this))
        {
            isRegistered = true;
        }
    }

    /// <summary>
    /// Sets the mouse cursor's position within its window.
    /// </summary>
    private void SetMousePosition(uint32 windowID, int32 x, int32 y)
    {
        this.window = Application.GetWindowSystem().GetWindowByID((int)windowID);

        if (Application.Properties.SupportsHighDensityDisplayModes)
        {
            var scale = window?.Display.DeviceScale ?? 1f;
            this.x = (int32)(x * scale);
            this.y = (int32)(y * scale);
        }
        else
        {
            this.x = x;
            this.y = y;
        }
    }

    /// <summary>
    /// Sets the mouse cursor's position based on the device's physical position.
    /// </summary>
    private void SetMousePositionFromDevicePosition(uint32 windowID)
    {
        int32 x = 0, y = 0;
        SDL.GetMouseState(&x, &y);
        SetMousePosition(windowID, x, y);
    }

    // The device identifier of the touch-based mouse emulator.
    private const uint32 SDL_TOUCH_MOUSEID = (uint32)(-1);

    // Property values.
    private int32 x;
    private int32 y;
    private int32 wheelDeltaX;
    private int32 wheelDeltaY;
    private bool isRegistered;
    private Window window;

    // State values.
    private InternalButtonState[] states;
    private uint32 buttonStateClicks;
    private uint32 buttonStateDoubleClicks;
    private bool ignoredFirstMouseMotionEvent;
    private bool relativeMode;

	private EventAccessor<MouseButtonEventHandler> mButtonPressed = new .() ~ delete _;
	public override EventAccessor<MouseButtonEventHandler> ButtonPressed=>mButtonPressed;

	private EventAccessor<MouseButtonEventHandler> mButtonReleased = new .() ~ delete _;
	public override EventAccessor<MouseButtonEventHandler> ButtonReleased=>mButtonReleased;

	private EventAccessor<MouseButtonEventHandler> mClick = new .() ~ delete _;
	public override EventAccessor<MouseButtonEventHandler> Click=>mClick;

	private EventAccessor<MouseButtonEventHandler> mDoubleClick = new .() ~ delete _;
	public override EventAccessor<MouseButtonEventHandler> DoubleClick=>mDoubleClick;

	private EventAccessor<MouseMoveEventHandler> mMoved = new .() ~ delete _;
	public override EventAccessor<MouseMoveEventHandler> Moved=>mMoved;

	private EventAccessor<MouseWheelEventHandler> mWheelScrolled = new .() ~ delete _;
	public override EventAccessor<MouseWheelEventHandler> WheelScrolled=>mWheelScrolled;
}