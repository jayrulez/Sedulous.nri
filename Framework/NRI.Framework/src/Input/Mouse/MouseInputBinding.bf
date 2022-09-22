using System;
namespace NRI.Framework.Input.Mouse;

/// <summary>
/// Represents a mouse input binding.
/// </summary>
public sealed class MouseInputBinding : InputBinding
{
    /// <summary>
    /// Initializes a new instance of the <see cref="MouseInputBinding"/> class.
    /// </summary>
    /// <param name="app">The Application instance.</param>
    /// <param name="element">The XML element that contains the binding data.</param>
    internal this(Application app/*, XElement element*/)
    {
        //Contract.Require(element, nameof(element));

        this.mouse = app.GetInput().GetMouse();

        this.button = /*element.ElementValueEnum<MouseButton>("Button") ??*/ MouseButton.None;
        this.control = /*element.ElementValueBoolean("Control") ??*/ false;
        this.alt = /*element.ElementValueBoolean("Alt") ??*/ false;
        this.shift = /*element.ElementValueBoolean("Shift") ??*/ false;

        this.stringRepresentation = BuildStringRepresentation(.. new .());
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="MouseInputBinding"/> class.
    /// </summary>
    /// <param name="app">The Application instance.</param>
    /// <param name="button">The <see cref="MouseButton"/> value that represents the binding's primary button.</param>
    public this(Application app, MouseButton button)
    {
        //Contract.Require(app, nameof(app));

        if (!app.GetInput().IsMouseSupported())
        {
            Runtime.FatalError("Mouse not supported.");
        }

        this.mouse = app.GetInput().GetMouse();
        this.button = button;

        this.stringRepresentation = BuildStringRepresentation(.. new .());
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="MouseInputBinding"/> class.
    /// </summary>
    /// <param name="app">The Application instance.</param>
    /// <param name="button">The <see cref="MouseButton"/> value that represents the binding's primary button.</param>
    /// <param name="control">A value indicating whether the binding requires the Control modifier.</param>
    /// <param name="alt">A value indicating whether the binding requires the Alt modifier.</param>
    /// <param name="shift">A value indicating whether the binding requires the Shift modifier.</param>
    public this(Application app, MouseButton button, bool control, bool alt, bool shift)
    {
        if (!app.GetInput().IsMouseSupported())
        {
            Runtime.FatalError("Mouse not supported.");
        }

        this.mouse = app.GetInput().GetMouse();
        this.button = button;
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
            if (!Enabled || mouse.IsButtonReleased(button) || !AreModifiersSatisfied())
            {
                pressed = false;
                released = true;
                OnReleased();
            }
        }
        else
        {
            if (Enabled && mouse.IsButtonPressed(button) && AreModifiersSatisfied())
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

        var mib = binding as MouseInputBinding;
        if (mib != null)
        {
            return
                this.Mouse == mib.Mouse &&
                this.Button == mib.Button &&
                this.IsControlRequired == mib.IsControlRequired &&
                this.IsAltRequired == mib.IsAltRequired &&
                this.IsShiftRequired == mib.IsShiftRequired;
        }

        return false;
    }

    /// <inheritdoc/>
    public override bool UsesSamePrimaryButtons(InputBinding binding)
    {
        if (binding == null) return false;
        if (binding == this) return true;

        var mib = binding as MouseInputBinding;
        if (mib != null)
        {
            return
                this.Mouse == mib.Mouse &&
                this.Button == mib.Button;
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
        return pressed && mouse.IsButtonPressed(button, ignoreRepeats: ignoreRepeats);
    }

    /// <inheritdoc/>
    public override bool IsReleased()
    {
        return released;
    }

    /// <summary>
    /// Gets the <see cref="MouseDevice"/> that created this input binding.
    /// </summary>
    public MouseDevice Mouse
    {
        get { return mouse; }
    }

    /// <summary>
    /// Gets the <see cref="MouseButton"/> value that represents the binding's primary button.
    /// </summary>
    public MouseButton Button
    {
        get { return button; }
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
            new XElement("Button", button),
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
            (!control || mouse.IsControlDown) &&
            (!alt     || mouse.IsAltDown) &&
            (!shift   || mouse.IsShiftDown);
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
    /// Builds a string representation of the mouse binding.
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
        builder.Append(Localization.Get("MOUSE_BUTTON_{Button}", .. scope .()));

        builder.ToString(output);
    }

    // Property values.
    private readonly MouseDevice mouse;
    private readonly MouseButton button;
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