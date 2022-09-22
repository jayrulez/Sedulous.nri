using System;
namespace NRI.Framework.Input.Keyboard;

/// <summary>
/// Represents the method that is called when a keyboard button is pressed or released.
/// </summary>
/// <param name="window">The window in which the input event took place.</param>
/// <param name="device">The <see cref="KeyboardDevice"/> that raised the event.</param>
/// <param name="scancode">The <see cref="Scancode"/> value that represents the key that was pressed.</param>
public delegate void KeyboardButtonEventHandler(Window window, KeyboardDevice device, Scancode scancode);

/// <summary>
/// Represents the method that is called when a keyboard key is pressed.
/// </summary>
/// <param name="window">The window in which the input event took place.</param>
/// <param name="device">The <see cref="KeyboardDevice"/> that raised the event.</param>
/// <param name="key">The <see cref="Key"/> value that represents the key that was pressed.</param>
/// <param name="ctrl">A value indicating whether the Control modifier is active.</param>
/// <param name="alt">A value indicating whether the Alt modifier is active.</param>
/// <param name="shift">A value indicating whether the Shift modifier is active.</param>
/// <param name="repeat">A value indicating whether this is a repeated key press.</param>
public delegate void KeyPressedEventHandler(Window window, KeyboardDevice device, Key key, bool ctrl, bool alt, bool shift, bool @repeat);

/// <summary>
/// Represents the method that is called when a keyboard key is released.
/// </summary>
/// <param name="window">The window in which the input event took place.</param>
/// <param name="device">The <see cref="KeyboardDevice"/> that raised the event.</param>
/// <param name="key">The <see cref="Key"/> value that represents the key that was released.</param>
public delegate void KeyReleasedEventHandler(Window window, KeyboardDevice device, Key key);

/// <summary>
/// Represents the method that is called when text input is available.
/// </summary>
/// <param name="window">The window in which the input event took place.</param>
/// <param name="device">The <see cref="KeyboardDevice"/> that raised the event.</param>
public delegate void TextInputEventHandler(Window window, KeyboardDevice device);

/// <summary>
/// Represents a keyboard device.
/// </summary>
public abstract class KeyboardDevice : InputDevice<Scancode>
{
	/// <summary>
	/// Initializes a new instance of the <see cref="KeyboardDevice"/> class.
	/// </summary>
	/// <param name="app">The Application instance.</param>
	public this(Application app)
		: base(app)
	{
	}

	/// <summary>
	/// Populates the specified <see cref="StringBuilder"/> with the most recent text input.
	/// </summary>
	/// <param name="sb">The <see cref="StringBuilder"/> to populate with text input data.</param>
	/// <param name="append">A value indicating whether to append the text input data to the existing data of <paramref name="sb"/>.</param>
	public abstract void GetTextInput(StringBuilder sb, bool @append = false);

	/// <summary>
	/// Gets a value indicating whether the specified key is currently down.
	/// </summary>
	/// <param name="key">The <see cref="Key"/> to evaluate.</param>
	/// <returns><see langword="true"/> if the key is down; otherwise, <see langword="false"/>.</returns>
	public abstract bool IsKeyDown(Key key);

	/// <summary>
	/// Gets a value indicating whether the specified key is currently up.
	/// </summary>
	/// <param name="key">The <see cref="Key"/> to evaluate.</param>
	/// <returns><see langword="true"/> if the key is up; otherwise, <see langword="false"/>.</returns>
	public abstract bool IsKeyUp(Key key);

	/// <summary>
	/// Gets a value indicating whether the specified key is currently pressed.
	/// </summary>
	/// <remarks>Platforms may send multiple key press events while a key is held down.  Any such 
	/// event after the first is marked as a "repeat" event and should be handled accordingly.</remarks>
	/// <param name="key">The <see cref="Key"/> to evaluate.</param>
	/// <param name="ignoreRepeats">A value indicating whether to ignore repeated key press events on devices which support them.</param>
	/// <returns><see langword="true"/> if the key is pressed; otherwise, <see langword="false"/>.</returns>
	public abstract bool IsKeyPressed(Key key, bool ignoreRepeats = true);

	/// <summary>
	/// Gets a value indicating whether the specified key is currently released.
	/// </summary>
	/// <param name="key">The <see cref="Key"/> to evaluate.</param>
	/// <returns><see langword="true"/> if the key is released; otherwise, <see langword="false"/>.</returns>
	public abstract bool IsKeyReleased(Key key);

	/// <summary>
	/// Gets the current state of the specified key.
	/// </summary>
	/// <param name="key">The <see cref="Key"/> for which to retrieve a state.</param>
	/// <returns>A <see cref="ButtonState"/> value indicating the state of the specified key.</returns>
	public abstract ButtonState GetKeyState(Key key);

	/// <summary>
	/// Gets a value indicating whether one of the Control modifier keys is currently down.
	/// </summary>
	public bool IsControlDown => IsKeyDown(Key.LeftControl) || IsKeyDown(Key.RightControl);

	/// <summary>
	/// Gets a value indicating whether one of the Alt modifier keys is currently down.
	/// </summary>
	public bool IsAltDown => IsKeyDown(Key.LeftAlt) || IsKeyDown(Key.RightAlt);

	/// <summary>
	/// Gets a value indicating whether one of the Shift modifier keys is currently down.
	/// </summary>
	public bool IsShiftDown => IsKeyDown(Key.LeftShift) || IsKeyDown(Key.RightShift);

	/// <summary>
	/// Gets a value indicating whether the Num Lock modifier is currently down.
	/// </summary>
	public abstract bool IsNumLockDown
	{
		get;
	}

	/// <summary>
	/// Gets a value indicating whether the Caps Lock modifier is currently down.
	/// </summary>
	public abstract bool IsCapsLockDown
	{
		get;
	}

	/// <summary>
	/// Occurs when a button is pressed.
	/// </summary>
	public abstract EventAccessor<KeyboardButtonEventHandler> ButtonPressed { get; }

	/// <summary>
	/// Occurs when a button is released.
	/// </summary>
	public abstract EventAccessor<KeyboardButtonEventHandler> ButtonReleased { get; }

	/// <summary>
	/// Occurs when a key is pressed.
	/// </summary>
	/// <remarks>Platforms may send multiple key press events while a key is held down. Any such 
	/// event after the first is marked as a "repeat" event and should be handled accordingly.</remarks>
	public abstract EventAccessor<KeyPressedEventHandler> KeyPressed { get; }

	/// <summary>
	/// Occurs when a key is released.
	/// </summary>
	public abstract EventAccessor<KeyReleasedEventHandler> KeyReleased { get; }

	/// <summary>
	/// Occurs when text input is available.
	/// </summary>
	public abstract EventAccessor<TextInputEventHandler> TextInput { get; }

	/// <summary>
	/// Occurs when text is being edited.
	/// </summary>
	public abstract EventAccessor<TextInputEventHandler> TextEditing { get; }

	/// <summary>
	/// Raises the <see cref="ButtonPressed"/> event.
	/// </summary>
	/// <param name="window">The window that raised the event.</param>
	/// <param name="scancode">The <see cref="Scancode"/> that represents the button that was pressed.</param>
	protected virtual void OnButtonPressed(Window window, Scancode scancode) =>
		ButtonPressed?.[Friend]Invoke(window, this, scancode);

	/// <summary>
	/// Raises the <see cref="ButtonReleased"/> event.
	/// </summary>
	/// <param name="window">The window that raised the event.</param>
	/// <param name="scancode">The <see cref="Scancode"/> that represents the button that was released.</param>
	protected virtual void OnButtonReleased(Window window, Scancode scancode) =>
		ButtonReleased?.[Friend]Invoke(window, this, scancode);

	/// <summary>
	/// Raises the <see cref="KeyPressed"/> event.
	/// </summary>
	/// <remarks>Platforms may send multiple key press events while a key is held down.  Any such 
	/// event after the first is marked as a "repeat" event and should be handled accordingly.</remarks>
	/// <param name="window">The window that raised the event.</param>
	/// <param name="key">The <see cref="Key"/> that was pressed.</param>
	/// <param name="ctrl">A value indicating whether the Control modifier is active.</param>
	/// <param name="alt">A value indicating whether the Alt modifier is active.</param>
	/// <param name="shift">A value indicating whether the Shift modifier is active.</param>
	/// <param name="repeat">A value indicating whether this is a repeated key press.</param>
	protected virtual void OnKeyPressed(Window window, Key key, bool ctrl, bool alt, bool shift, bool @repeat)
	{
		KeyPressed?.[Friend]Invoke(window, this, key, ctrl, alt, shift, @repeat);
	}

	/// <summary>
	/// Raises the <see cref="KeyReleased"/> event.
	/// </summary>
	/// <param name="window">The window that raised the event.</param>
	/// <param name="key">The <see cref="Key"/> that was released.</param>
	protected virtual void OnKeyReleased(Window window, Key key)
	{
		KeyReleased?.[Friend]Invoke(window, this, key);
	}

	/// <summary>
	/// Raises the <see cref="TextInput"/> event.
	/// </summary>
	/// <param name="window">The window that raised the event.</param>
	protected virtual void OnTextInput(Window window)
	{
		TextInput?.[Friend]Invoke(window, this);
	}

	/// <summary>
	/// Raises the <see cref="TextEditing"/> event.
	/// </summary>
	/// <param name="window">The window that raised the event.</param>
	protected virtual void OnTextEditing(Window window)
	{
		TextEditing?.[Friend]Invoke(window, this);
	}
}