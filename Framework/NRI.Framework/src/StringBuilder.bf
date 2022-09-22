using System;
namespace NRI.Framework;

class StringBuilder
{
	private String mStr = new .() ~ delete _;

	public int Length
	{
		get => mStr?.Length ?? 0; set
		{
			if (Length <= value)
				mStr.Length = value;
			else
			{
				while (Length < value)
				{
					mStr.Append('\0');
				}
			}
		}
	}

	public void Append(String str)
	{
		mStr.Append(str);
	}

	public void Append(char8 c)
	{
		mStr.Append(c);
	}

	public override void ToString(String str)
	{
		str.Append(mStr);
	}
}