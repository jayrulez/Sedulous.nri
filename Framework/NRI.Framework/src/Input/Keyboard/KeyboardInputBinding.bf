using System;
namespace NRI.Framework.Input.Keyboard;

/// <summary>
/// Represents a keyboard input binding.
/// </summary>
public sealed class KeyboardInputBinding : InputBinding
{
    /// <summary>
    /// Initializes a new instance of the <see cref="KeyboardInputBinding"/> class.
    /// </summary>
    /// <param name="app">The Application instance.</param>
    /// <param name="element">The XML element that contains the binding data.</param>
    internal this(Application app/*, XElement element*/)
    {
        //Contract.Require(element, nameof(element));

        this.keyboard = app.GetInput().GetKeyboard();

        this.key = /*element.ElementValueEnum<Key>("Key") ??*/ /*Key*/.None;
        this.control = /*element.ElementValueBoolean("Control") ??*/ false;
        this.alt = /*element.ElementValueBoolean("Alt") ??*/ false;
        this.shift = /*element.ElementValueBoolean("Shift") ??*/ false;

        this.stringRepresentation = BuildStringRepresentation(.. new .());
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="KeyboardInputBinding"/> class.
    /// </summary>
    /// <param name="app">The Application instance.</param>
    /// <param name="key">A <see cref="Key"/> value representing the binding's primary key.</param>
    public this(Application app, Key key)
    {
        //Contract.Require(app, nameof(app));

        if (!app.GetInput().IsKeyboardSupported())
        {
            Runtime.FatalError("Keyboard not supported.");
        }

        this.keyboard = app.GetInput().GetKeyboard();
        this.key = key;

        this.stringRepresentation = BuildStringRepresentation(.. new .());
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="KeyboardInputBinding"/> class.
    /// </summary>
    /// <param name="app">The Application instance.</param>
    /// <param name="key">A <see cref="Key"/> value representing the binding's primary key.</param>
    /// <param name="control">A value indicating whether the binding requires the Control modifier.</param>
    /// <param name="alt">A value indicating whether the binding requires the Alt modifier.</param>
    /// <param name="shift">A value indicating whether the binding requires the Shift modifier.</param>
    public this(Application app, Key key, bool control, bool alt, bool shift)
    {
        if (!app.GetInput().IsKeyboardSupported())
        {
            Runtime.FatalError("Keyboard not supported.");
        }

        this.keyboard = app.GetInput().GetKeyboard();
        this.key = key;
        this.control = control;
        this.alt = alt;
        this.shift = shift;

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
        released = false;
        if (pressed)
        {
            if (!Enabled || keyboard.IsKeyReleased(key) || !AreModifiersSatisfied())
            {
                pressed = false;
                released = true;
                OnReleased();
            }
        }
        else
        {
            if (Enabled && keyboard.IsKeyPressed(key) && AreModifiersSatisfied())
            {
                pressed = true;
                OnPressed();
            }
        }
    }

    /// <inheritdoc/>
    public override bool UsesSameButtons(InputBinding binding)
    {
        if (binding == null) return false;
        if (binding == this) return true;

        var kbib = binding as KeyboardInputBinding;
        if (kbib != null)
        {
            return
                this.Keyboard == kbib.Keyboard &&
                this.Key == kbib.Key &&
                this.IsControlRequired == kbib.IsControlRequired &&
                this.IsAltRequired == kbib.IsAltRequired &&
                this.IsShiftRequired == kbib.IsShiftRequired;
        }

        return false;
    }

    /// <inheritdoc/>
    public override bool UsesSamePrimaryButtons(InputBinding binding)
    {
        if (binding == null) return false;
        if (binding == this) return true;

        var kbib = binding as KeyboardInputBinding;
        if (kbib != null)
        {
            return 
                this.Keyboard == kbib.Keyboard &&
                this.Key == kbib.Key;
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
        return pressed && keyboard.IsKeyPressed(key, ignoreRepeats: ignoreRepeats);
    }

    /// <inheritdoc/>
    public override bool IsReleased()
    {
        return released;
    }

    /// <summary>
    /// Gets the <see cref="KeyboardDevice"/> that created this input binding.
    /// </summary>
    public KeyboardDevice Keyboard
    {
        get { return keyboard; }
    }

    /// <summary>
    /// Gets the <see cref="Key"/> value that represents the binding's primary key.
    /// </summary>
    public Key Key
    {
        get { return key; }
    }

    /// <summary>
    /// Gets a value indicating whether this binding requires the Control modifier.
    /// </summary>
    public bool IsControlRequired
    {
        get { return control; }
    }

    /// <summary>
    /// Gets a value indicating whether this binding requires the Alt modifier.
    /// </summary>
    public bool IsAltRequired
    {
        get { return alt; }
    }

    /// <summary>
    /// Gets a value indicating whether this binding requires the Shift modifier.
    /// </summary>
    public bool IsShiftRequired
    {
        get { return shift; }
    }

    /// <inheritdoc/>
    /*internal override XElement ToXml(String name = null)
    {
        return new XElement(name ?? "Binding", new XAttribute("Type", GetType().FullName),
            new XElement("Key", key),
            new XElement("Control", control),
            new XElement("Alt", alt),
            new XElement("Shift", shift)
        );
    }*/

    /// <inheritdoc/>
    protected override int32 CalculatePriority()
    {
        return
            (control ? 1 : 0) +
            (alt ? 1 : 0) + 
            (shift ? 1 : 0);
    }

    /// <summary>
    /// Gets a value indicating whether the binding's modifier states are satisfied.
    /// </summary>
    /// <returns><see langword="true"/> if the binding's modifier states are satisfied; otherwise, <see langword="false"/>.</returns>
    private bool AreModifiersSatisfied()
    {
        return
            (!control || keyboard.IsControlDown) &&
            (!alt     || keyboard.IsAltDown) &&
            (!shift   || keyboard.IsShiftDown);

    }

    /// <summary>
    /// Appends a separator to the specified string builder if the builder already contains text.
    /// </summary>
    private bool AppendSeparatorIfNecessary(StringBuilder builder, String separator)
    {
        if (builder.Length == 0)
            return false;

        builder.Append(separator);
        return true;
    }

    /// <summary>
    /// Builds a string representation of the key binding.
    /// </summary>
    private void BuildStringRepresentation(String output)
    {
        String separator = Localization.Get("INPUT_BINDING_SEPARATOR", .. scope .());
        var builder = scope StringBuilder();

        if (IsControlRequired)
        {
            AppendSeparatorIfNecessary(builder, separator);
            builder.Append(Localization.Get("KEY_MODIFIER_CONTROL", .. scope .()));
        }

        if (IsAltRequired)
        {
            AppendSeparatorIfNecessary(builder, separator);
            builder.Append(Localization.Get("KEY_MODIFIER_ALT", .. scope .()));
        }

        if (IsShiftRequired)
        {
            AppendSeparatorIfNecessary(builder, separator);
            builder.Append(Localization.Get("KEY_MODIFIER_SHIFT", .. scope .()));
        }

        AppendSeparatorIfNecessary(builder, separator);
        builder.Append(Localization.Get(scope $"KEY_{Key}", .. scope .()));

        builder.ToString(output);
    }

    // Property values.
    private readonly KeyboardDevice keyboard;
    private readonly Key key;
    private readonly bool control;
    private readonly bool alt;
    private readonly bool shift;
    private readonly String stringRepresentation;

    // State values.
    private bool pressed;
    private bool released;
	
	private EventAccessor<InputBindingEventHandler> mPressed = new .() ~ delete _;
	private EventAccessor<InputBindingEventHandler> mReleased = new .() ~ delete _;

	public override EventAccessor<InputBindingEventHandler> Pressed => mPressed;

	public override EventAccessor<InputBindingEventHandler> Released => mReleased;
}