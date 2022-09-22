using SDL2;
using NRI.Framework.Input.Keyboard;
using System.Text;
using NRI.Framework.Input;
using System;
namespace NRI.Framework.SDL.Input;

using internal NRI.Framework.SDL.Input;
/// <summary>
/// Represents the SDL2 implementation of the KeyboardDevice class.
/// </summary>
public sealed class SDL2KeyboardDevice : KeyboardDevice
{
    /// <summary>
    /// Initializes a new instance of the SDL2KeyboardDevice class.
    /// </summary>
    /// <param name="app">The Application instance.</param>
    public this(Application app)
        : base(app)
    {
        int32 numkeys = 0;
        SDL.GetKeyboardState(&numkeys);

        this.states = new InternalButtonState[numkeys];

        /*app.Messages.Subscribe(this,
            UltravioletMessages.SoftwareKeyboardShown);
        app.Messages.Subscribe(this,
            UltravioletMessages.SoftwareKeyboardHidden);

        app.Messages.Subscribe(this,
            SDL2UltravioletMessages.SDLEvent);*/
    }

	internal void HandleSoftwareKeyboardEvent(){
		/*if (type == .SoftwareKeyboardShown)
		{
		    SDL.StartTextInput();
		}
		else if (type == .SoftwareKeyboardHidden)
		{
		    SDL.StopTextInput();
		}*/
	}

    /// <inheritdoc/>
    internal void HandleEvent(ref SDL.Event evt)
    {
        switch (evt.type)
            {
                case .KeyDown:
                    {
                        if (!isRegistered)
                            Register();

                        OnKeyDown(ref evt.key);
                    }
                    break;

                case .KeyUp:
                    {
                        if (!isRegistered)
                            Register();

                        OnKeyUp(ref evt.key);
                    }
                    break;

                case .TextEditing:
                    {
                        if (!isRegistered)
                            Register();

                        OnTextEditing(ref evt.edit);
                    }
                    break;

                case .TextInput:
                    {
                        if (isRegistered)
                            Register();

                        OnTextInput(ref evt.text);
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
    public override void GetTextInput(StringBuilder sb, bool @append = false)
    {
        //Contract.EnsureNotDisposed(this, Disposed);

        if (!@append)
            sb.Length = 0;

        for (int i = 0; i < textInputLength; i++)
        {
            sb.Append(textUtf16[i]);
        }
    }

    /// <inheritdoc/>
    public override bool IsButtonDown(Scancode button)
    {
        //Contract.EnsureNotDisposed(this, Disposed);

        var scancode = (int)button;
        return states[scancode].Down;
    }

    /// <inheritdoc/>
    public override bool IsButtonUp(Scancode button)
    {
        //Contract.EnsureNotDisposed(this, Disposed);

        var scancode = (int)button;
        return states[scancode].Up;
    }

    /// <inheritdoc/>
    public override bool IsButtonPressed(Scancode button, bool ignoreRepeats = true)
    {
        //Contract.EnsureNotDisposed(this, Disposed);

        var scancode = (int)button;
        return states[scancode].Pressed || (!ignoreRepeats && states[scancode].Repeated);
    }

    /// <inheritdoc/>
    public override bool IsButtonReleased(Scancode button)
    {
        //Contract.EnsureNotDisposed(this, Disposed);

        var scancode = (int)button;
        return states[scancode].Released;
    }

    /// <inheritdoc/>
    public override bool IsKeyDown(Key key)
    {
        //Contract.EnsureNotDisposed(this, Disposed);

        var scancode = (int)SDL.GetScancodeFromKey((SDL.Keycode)key);
        return states[scancode].Down;
    }

    /// <inheritdoc/>
    public override bool IsKeyUp(Key key)
    {
        //Contract.EnsureNotDisposed(this, Disposed);

        var scancode = (int)SDL.GetScancodeFromKey((SDL.Keycode)key);
        return states[scancode].Up;
    }

    /// <inheritdoc/>
    public override bool IsKeyPressed(Key key, bool ignoreRepeats = true)
    {
        //Contract.EnsureNotDisposed(this, Disposed);

        var scancode = (int)SDL.GetScancodeFromKey((SDL.Keycode)key);
        return states[scancode].Pressed || (!ignoreRepeats && states[scancode].Repeated);
    }

    /// <inheritdoc/>
    public override bool IsKeyReleased(Key key)
    {
        //Contract.EnsureNotDisposed(this, Disposed);

        var scancode = (int)SDL.GetScancodeFromKey((SDL.Keycode)key);
        return states[scancode].Released;
    }

    /// <inheritdoc/>
    public override ButtonState GetKeyState(Key key)
    {
        var state = IsKeyDown(key) ? ButtonState.Down : ButtonState.Up;

        if (IsKeyPressed(key))
            state |= ButtonState.Pressed;

        if (IsKeyReleased(key))
            state |= ButtonState.Released;

        return state;
    }

    /// <inheritdoc/>
    public override bool IsNumLockDown =>  (SDL.GetModState() & .Num) == .Num;

    /// <inheritdoc/>
    public override bool IsCapsLockDown =>  (SDL.GetModState() & .Caps) == .Caps;

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
    /// Handles SDL2's KEYDOWN event.
    /// </summary>
    private void OnKeyDown(ref SDL.KeyboardEvent evt)
    {
        var window = Application.GetWindowSystem().GetWindowByID((int)evt.windowID);
        var mods   = evt.keysym.mod;
        var ctrl   = (mods & .CTRL) != 0;
        var alt    = (mods & .ALT) != 0;
        var shift  = (mods & .SHIFT) != 0;
        var @repeat = evt.isRepeat > 0;

        states[(int)evt.keysym.scancode].OnDown(@repeat);

        if (!@repeat)
        {
            OnButtonPressed(window, (Scancode)evt.keysym.scancode);
        }
        OnKeyPressed(window, (Key)evt.keysym.scancode, ctrl, alt, shift, @repeat);
    }

    /// <summary>
    /// Handles SDL2's KEYUP event.
    /// </summary>
    private void OnKeyUp(ref SDL.KeyboardEvent evt)
    {
        var window = Application.GetWindowSystem().GetWindowByID((int)evt.windowID);

        states[(int)evt.keysym.scancode].OnUp();

        OnButtonReleased(window, (Scancode)evt.keysym.scancode);
        OnKeyReleased(window, (Key)evt.keysym.scancode);
    }

    /// <summary>
    /// Handles SDL2's TEXTEDITING event.
    /// </summary>
    private void OnTextEditing(ref SDL.TextEditingEvent evt)
    {
        var window = Application.GetWindowSystem().GetWindowByID((int)evt.windowID);
        uint8* input = &evt.text;
            if (ConvertTextInputToUtf16(input))
            {
                OnTextEditing(window);
            }
    }

    /// <summary>
    /// Handles SDL2's TEXTINPUT event.
    /// </summary>
    private void OnTextInput(ref SDL.TextInputEvent evt)
    {
        var window = Application.GetWindowSystem().GetWindowByID((int)evt.windowID);
        uint8* input = &evt.text;
            if (ConvertTextInputToUtf16(input))
            {
                OnTextInput(window);
            }
    }

    /// <summary>
    /// Converts inputted text (which is in UTF-8 format) to UTF-16.
    /// </summary>
    /// <param name="input">A pointer to the inputted text.</param>
    /// <returns><see langword="true"/> if the input data was successfully converted; otherwise, <see langword="false"/>.</returns>
    private bool ConvertTextInputToUtf16(uint8* input)
    {
        // Count the number of bytes in the UTF-8 text.
        var p = input;
        var byteCount = 0;
        while (*p++ != 0)
        {
            byteCount++;
        }

        if (byteCount == 0)
            return false;

        // Convert the UTF-8 characters to C#'s expected UTF-16 characters.
        //var bytesUsed = 0;
        //int32 charsUsed = 0;
        var completed = false;
        
		char8* pTextUtf16 = textUtf16.Ptr;
        /*Encoding.UTF8.GetDecoder().Convert(input, byteCount, pTextUtf16, textUtf16.Count, true,
            out bytesUsed, out charsUsed, out completed);*/

		if(UTF8Encoding.UTF16.Encode(scope String((char8*)input), Span<uint8>((uint8*)pTextUtf16, textUtf16.Count)) case .Ok(let charsUsed)){
        	textInputLength = (.)charsUsed;
		}else{
			completed = false;
		}

        if (!completed)
        {
            return false;
        }

        return true;
    }

    /// <summary>
    /// Flags the device as registered.
    /// </summary>
    private void Register()
    {
        var input = (SDL2InputManager)Application.GetInput();
        if (input.RegisterKeyboardDevice(this))
            isRegistered = true;
    }

    // State values.
    private readonly InternalButtonState[] states;
    private readonly char8[] textUtf16 = new char8[32];
    private int32 textInputLength;
    private bool isRegistered;

	private EventAccessor<KeyboardButtonEventHandler> mButtonPressed = new .() ~ delete _;
	public override EventAccessor<KeyboardButtonEventHandler> ButtonPressed=> mButtonPressed;

	private EventAccessor<KeyboardButtonEventHandler> mButtonReleased = new .() ~ delete _;
	public override EventAccessor<KeyboardButtonEventHandler> ButtonReleased=>mButtonReleased;

	private EventAccessor<KeyPressedEventHandler> mKeyPressed = new .() ~ delete _;
	public override EventAccessor<KeyPressedEventHandler> KeyPressed=>mKeyPressed;

	private EventAccessor<KeyReleasedEventHandler> mKeyReleased = new .() ~ delete _;
	public override EventAccessor<KeyReleasedEventHandler> KeyReleased=>mKeyReleased;

	private EventAccessor<TextInputEventHandler> mTextInput = new .() ~ delete _;
	public override EventAccessor<TextInputEventHandler> TextInput=>mTextInput;

	private EventAccessor<TextInputEventHandler> mTextEditing = new .() ~ delete _;
	public override EventAccessor<TextInputEventHandler> TextEditing=>mTextEditing;
}