using System;
namespace NRI.Framework.Input;

/// <summary>
/// Represents the method that is called when an <see cref="InputBinding"/> is pressed or released.
/// </summary>
/// <param name="binding">The <see cref="InputBinding"/> that raised the event.</param>
public delegate void InputBindingEventHandler(InputBinding binding);

/// <summary>
/// Represents an input binding.
/// </summary>
public abstract class InputBinding
{
	/// <summary>
	/// Initializes a new instance of the <see cref="InputBinding"/> class.
	/// </summary>
	internal this()
	{
	}

	/// <summary>
	/// Adjusts the input binding's priority by the specified amount.
	/// </summary>
	/// <remarks>Higher values indicate higher priority.</remarks>
	/// <param name="priorityAdjustment">The amount by which to adjust the binding's priority, 
	/// or <see langword="null"/> to reset the input binding's priority adjustment.</param>
	public void AdjustPriority(int32? priorityAdjustment)
	{
		this.priorityAdjustment = priorityAdjustment;
	}

	/// <summary>
	/// Updates the binding's state.
	/// </summary>
	public abstract void Update();

	/// <summary>
	/// Gets a value indicating whether the input binding uses the same device 
	/// and the same button configuration as the specified input binding.
	/// </summary>
	/// <param name="binding">The <see cref="InputBinding"/> to compare against this input binding.</param>
	/// <returns><see langword="true"/> if the specified input binding uses the same device and the same button 
	/// configuration as this input binding; otherwise, <see langword="false"/>.</returns>
	public abstract bool UsesSameButtons(InputBinding binding);

	/// <summary>
	/// Gets a value indicating whether the input binding uses the same device 
	/// and the same primary buttons as the specified input binding.
	/// </summary>
	/// <param name="binding">The <see cref="InputBinding"/> to compare against this input binding.</param>
	/// <returns><see langword="true"/> if the specified input binding uses the same device and the same primary 
	/// buttons as this input binding; otherwise, <see langword="false"/>.</returns>
	public abstract bool UsesSamePrimaryButtons(InputBinding binding);

	/// <summary>
	/// Gets a value indicating whether the binding is down.
	/// </summary>
	/// <returns><see langword="true"/> if the binding is down; otherwise, <see langword="false"/>.</returns>
	public abstract bool IsDown();

	/// <summary>
	/// Gets a value indicating whether the binding is up.
	/// </summary>
	/// <returns><see langword="true"/> if the binding is up; otherwise, <see langword="false"/>.</returns>
	public abstract bool IsUp();

	/// <summary>
	/// Gets a value indicating whether the binding was pressed this frame.
	/// </summary>
	/// <param name="ignoreRepeats">A value indicating whether to ignore repeated button press events on devices which support them.</param>
	/// <returns><see langword="true"/> if the binding was pressed this frame; otherwise, <see langword="false"/>.</returns>
	public abstract bool IsPressed(bool ignoreRepeats = true);

	/// <summary>
	/// Gets a value indicating whether the binding was released this frame.
	/// </summary>
	/// <returns><see langword="true"/> if the binding was released this frame; otherwise, <see langword="false"/>.</returns>
	public abstract bool IsReleased();

	/// <summary>
	/// Gets the binding's current state.
	/// </summary>
	/// <param name="ignoreRepeats">A value indicating whether to ignore repeated button press events on devices which support them.</param>
	/// <returns>A <see cref="ButtonState"/> value indicating the binding's current state.</returns>
	public ButtonState GetState(bool ignoreRepeats = true)
	{
		var state = IsDown() ? ButtonState.Down : ButtonState.Up;

		if (IsPressed(ignoreRepeats))
			state |= ButtonState.Pressed;

		if (IsReleased())
			state |= ButtonState.Released;

		return state;
	}

	/// <summary>
	/// Gets the input binding's priority relative to other input bindings
	/// which use the same primary buttons.
	/// </summary>
	/// <remarks>Higher values indicate higher priority.</remarks>
	public int32 Priority
	{
		get { return priorityAdjustment.GetValueOrDefault() + CalculatePriority(); }
	}

	/// <summary>
	/// Gets a value indicating whether this binding's priority has been adjusted.
	/// </summary>
	public bool PriorityIsAdjusted
	{
		get { return priorityAdjustment.HasValue; }
	}

	/// <summary>
	/// Gets or sets a value indicating whether this binding is enabled.
	/// </summary>
	public bool Enabled
	{
		get { return enabled; }
		set { enabled = value; }
	}

	/// <summary>
	/// Occurs when the binding is pressed.
	/// </summary>
	public abstract EventAccessor<InputBindingEventHandler> Pressed { get; }

	/// <summary>
	/// Occurs when the binding is released.
	/// </summary>
	public abstract EventAccessor<InputBindingEventHandler> Released { get; }

	/// <summary>
	/// Creates an XML element that represents the binding.
	/// </summary>
	/// <param name="name">The name to give to the created XML element.</param>
	/// <returns>An XML element that represents the binding.</returns>
	//internal abstract XElement ToXml(String name = null);

	/// <summary>
	/// Calculates the binding's priority relative to other bindings with the same primary buttons.
	/// </summary>
	/// <returns>The binding's priority relative to other bindings with the same primary buttons.</returns>
	protected abstract int32 CalculatePriority();

	/// <summary>
	/// Raises the <see cref="Pressed"/> event.
	/// </summary>
	protected virtual void OnPressed() =>
		Pressed?.[Friend]Invoke(this);

	/// <summary>
	/// Raises the <see cref="Released"/> event.
	/// </summary>
	protected virtual void OnReleased() =>
		Released?.[Friend]Invoke(this);

	// Property values.
	private int32? priorityAdjustment;
	private bool enabled = true;
}