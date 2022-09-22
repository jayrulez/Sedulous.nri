using System;
namespace NRI.Framework.Input.GamePad;

/// <summary>
/// Represents a game pad input binding.
/// </summary>
public sealed class GamePadInputBinding : InputBinding
{
	/// <summary>
	/// Initializes a new instance of the <see cref="GamePadInputBinding"/> class.
	/// </summary>
	/// <param name="app">The Application instance.</param>
	/// <param name="element">The XML element that contains the binding data.</param>
	internal this(Application app, /*XElement*/ void* element)
	{
		//Contract.Require(app, nameof(app));
		//Contract.Require(element, nameof(element));

		this.mApp = app;
		this.playerIndex = /*element.ElementValueInt32("Player") ??*/ 0;
		this.button = /*element.ElementValueEnum<GamePadButton>("Button") ??*/ GamePadButton.None;

		this.stringRepresentation = BuildStringRepresentation(.. new .());
	}

	/// <summary>
	/// Initializes a new instance of the <see cref="GamePadInputBinding"/> class.
	/// </summary>
	/// <param name="app">The Application instance.</param>
	/// <param name="playerIndex">The index of the player for which to create the binding.</param>
	/// <param name="button">A <see cref="GamePadButton"/> value representing the binding's primary button.</param>
	public this(Application app, int32 playerIndex, GamePadButton button)
		: base()
	{
		///Contract.Require(app, nameof(app));
		//Contract.EnsureRange(playerIndex >= 0, nameof(playerIndex));

		this.mApp = app;
		this.playerIndex = playerIndex;
		this.button = button;

		this.stringRepresentation = BuildStringRepresentation(.. new .());
	}

	/// <inheritdoc/>
	public override void ToString(String str)
	{
		str.Append(stringRepresentation);
	}

	/// <inheritdoc/>
	public override void Update()
	{
		var gamePad = mApp.GetInput().GetGamePadForPlayer(playerIndex);

		released = false;
		if (pressed)
		{
			if (!Enabled || gamePad == null || gamePad.IsButtonReleased(button))
			{
				pressed = false;
				released = true;
				OnReleased();
			}
		}
		else
		{
			if (Enabled && gamePad != null && gamePad.IsButtonPressed(button))
			{
				pressed = true;
				OnPressed();
			}
		}
	}

	/// <inheritdoc/>
	public override bool UsesSameButtons(InputBinding binding)
	{
		if (binding ==  null) return false;
		if (binding ==  this) return true;

		var gpib = binding as GamePadInputBinding;
		if (gpib != null)
		{
			return
				this.PlayerIndex == gpib.PlayerIndex &&
				this.Button == gpib.Button;
		}

		return false;
	}

	/// <inheritdoc/>
	public override bool UsesSamePrimaryButtons(InputBinding binding)
	{
		if (binding ==  null) return false;
		if (binding ==  this) return true;

		var gpib = binding as GamePadInputBinding;
		if (gpib != null)
		{
			return
				this.PlayerIndex == gpib.PlayerIndex &&
				this.Button == gpib.Button;
		}

		return false;
	}

	/// <inheritdoc/>
	public override bool IsDown()
	{
		return pressed;
	}

	/// <inheritdoc/>
	public override bool IsUp()
	{
		return !pressed;
	}

	/// <inheritdoc/>
	public override bool IsPressed(bool ignoreRepeats = true)
	{
		var gamePad = mApp.GetInput().GetGamePadForPlayer(playerIndex);
		return pressed && (gamePad != null && gamePad.IsButtonPressed(button, ignoreRepeats: ignoreRepeats));
	}

	/// <inheritdoc/>
	public override bool IsReleased()
	{
		var gamePad = mApp.GetInput().GetGamePadForPlayer(playerIndex);
		return released && (gamePad == null || gamePad.IsButtonReleased(button));
	}

	/// <summary>
	/// Gets the index of the 
	/// </summary>
	public int32 PlayerIndex
	{
		get { return playerIndex; }
	}

	/// <summary>
	/// Gets the <see cref="GamePadButton"/> value that represents the binding's primary button.
	/// </summary>
	public GamePadButton Button
	{
		get { return button; }
	}

	/// <inheritdoc/>
	/*internal override XElement ToXml(string name = null)
	{
		return new XElement(name ?? "Binding", new XAttribute("Type", GetType().FullName),
			new XElement("Player", playerIndex),
			new XElement("Button", button)
		);
	}*/

	/// <inheritdoc/>
	protected override int32 CalculatePriority()
	{
		return 0;
	}

	/// <summary>
	/// Builds a string representation of the game pad binding.
	/// </summary>
	private void BuildStringRepresentation(String str)
	{
		Localization.Get(scope $"GAME_PAD_BUTTON_{Button}", str);
	}

	// Property values.
	private readonly int32 playerIndex;
	private readonly GamePadButton button;
	private readonly String stringRepresentation;

	// State values.
	private readonly Application mApp;
	private bool pressed;
	private bool released;
	private EventAccessor<InputBindingEventHandler> mPressed = new .() ~ delete _;
	private EventAccessor<InputBindingEventHandler> mReleased = new .() ~ delete _;

	public override EventAccessor<InputBindingEventHandler> Pressed => mPressed;

	public override EventAccessor<InputBindingEventHandler> Released => mReleased;
}