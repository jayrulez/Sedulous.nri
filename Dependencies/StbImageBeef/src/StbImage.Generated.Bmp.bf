// Generated by Sichem at 12/24/2021 8:28:15 PM

using Hebron.Runtime;

namespace StbImageBeef
{
	extension StbImage
	{
		public static int32 stbi__bmp_info(stbi__context s, int32* x, int32* y, int32* comp)
		{
			void* p;
			stbi__bmp_data info = default;
			info.all_a = 255;
			p = stbi__bmp_parse_header(s, &info);
			if (p == null)
			{
				stbi__rewind(s);
				return 0;
			}

			if (x != null)
				*x = (int32)s.img_x;
			if (y != null)
				*y = (int32)s.img_y;
			if (comp != null)
			{
				if (info.bpp == 24 && info.ma == 0xff000000)
					*comp = 3;
				else
					*comp = info.ma != 0 ? 4 : 3;
			}

			return 1;
		}

		public static void* stbi__bmp_load(stbi__context s, int32* x, int32* y, int32* comp, int32 req_comp,
			stbi__result_info* ri)
		{
			uint8* _out_;
			uint32 mr = 0;
			uint32 mg = 0;
			uint32 mb = 0;
			uint32 ma = 0;
			uint32 all_a = 0;

			// TODO
			uint8[256][4] pal = ?;
			int32 psize = 0;
			int32 i = 0;
			int32 j = 0;
			int32 width = 0;
			int32 flip_vertically = 0;
			int32 pad = 0;
			int32 target = 0;
			stbi__bmp_data info = default;
			info.all_a = 255;
			if (stbi__bmp_parse_header(s, &info) == null)
				return null;
			flip_vertically = (int32)s.img_y > 0 ? 1 : 0;
			s.img_y = CRuntime.abs(s.img_y);
			if (s.img_y > 1 << 24)
				return (uint8*)(stbi__err("too large") != 0 ? null : null);
			if (s.img_x > 1 << 24)
				return (uint8*)(stbi__err("too large") != 0 ? null : null);
			mr = info.mr;
			mg = info.mg;
			mb = info.mb;
			ma = info.ma;
			all_a = info.all_a;
			if (info.hsz == 12)
			{
				if (info.bpp < 24)
					psize = (info.offset - info.extra_read - 24) / 3;
			}
			else
			{
				if (info.bpp < 16)
					psize = (info.offset - info.extra_read - info.hsz) >> 2;
			}

			if (info.bpp == 24 && ma == 0xff000000)
				s.img_n = 3;
			else
				s.img_n = ma != 0 ? 4 : 3;
			if (req_comp != 0 && req_comp >= 3)
				target = req_comp;
			else
				target = s.img_n;
			if (stbi__mad3sizes_valid(target, (int32)s.img_x, (int32)s.img_y, 0) == 0)
				return (uint8*)(stbi__err("too large") != 0 ? null : null);
			_out_ = (uint8*)stbi__malloc_mad3(target, (int32)s.img_x, (int32)s.img_y, 0);
			if (_out_ == null)
				return (uint8*)(stbi__err("outofmem") != 0 ? null : null);
			if (info.bpp < 16)
			{
				int32 z = 0;
				if (psize == 0 || psize > 256)
				{
					CRuntime.free(_out_);
					return (uint8*)(stbi__err("invalid") != 0 ? null : null);
				}

				for (i = 0; i < psize; ++i)
				{
					pal[i][2] = stbi__get8(s);
					pal[i][1] = stbi__get8(s);
					pal[i][0] = stbi__get8(s);
					if (info.hsz != 12)
						stbi__get8(s);
					pal[i][3] = 255;
				}

				stbi__skip(s, info.offset - info.extra_read - info.hsz - psize * (info.hsz == 12 ? 3 : 4));
				if (info.bpp == 1)
				{
					width = (int32)((s.img_x + 7) >> 3);
				}
				else if (info.bpp == 4)
				{
					width = (int32)((s.img_x + 1) >> 1);
				}
				else if (info.bpp == 8)
				{
					width = (int32)s.img_x;
				}
				else
				{
					CRuntime.free(_out_);
					return (uint8*)(stbi__err("bad bpp") != 0 ? null : null);
				}

				pad = -width & 3;
				if (info.bpp == 1)
					for (j = 0; j < (int32)s.img_y; ++j)
					{
						var bit_offset = 7;
						int32 v = stbi__get8(s);
						for (i = 0; i < (int32)s.img_x; ++i)
						{
							var color = (v >> bit_offset) & 0x1;
							_out_[z++] = pal[color][0];
							_out_[z++] = pal[color][1];
							_out_[z++] = pal[color][2];
							if (target == 4)
								_out_[z++] = 255;
							if (i + 1 == (int32)s.img_x)
								break;
							if (--bit_offset < 0)
							{
								bit_offset = 7;
								v = stbi__get8(s);
							}
						}

						stbi__skip(s, pad);
					}
				else
					for (j = 0; j < (int32)s.img_y; ++j)
					{
						for (i = 0; i < (int32)s.img_x; i += 2)
						{
							int32 v = stbi__get8(s);
							int32 v2 = 0;
							if (info.bpp == 4)
							{
								v2 = v & 15;
								v >>= 4;
							}

							_out_[z++] = pal[v][0];
							_out_[z++] = pal[v][1];
							_out_[z++] = pal[v][2];
							if (target == 4)
								_out_[z++] = 255;
							if (i + 1 == (int32)s.img_x)
								break;
							v = info.bpp == 8 ? stbi__get8(s) : v2;
							_out_[z++] = pal[v][0];
							_out_[z++] = pal[v][1];
							_out_[z++] = pal[v][2];
							if (target == 4)
								_out_[z++] = 255;
						}

						stbi__skip(s, pad);
					}
			}
			else
			{
				int32 rshift = 0;
				int32 gshift = 0;
				int32 bshift = 0;
				int32 ashift = 0;
				int32 rcount = 0;
				int32 gcount = 0;
				int32 bcount = 0;
				int32 acount = 0;
				int32 z = 0;
				int32 easy = 0;
				stbi__skip(s, info.offset - info.extra_read - info.hsz);
				if (info.bpp == 24)
					width = (int32)(3 * s.img_x);
				else if (info.bpp == 16)
					width = (int32)(2 * s.img_x);
				else
					width = 0;
				pad = -width & 3;
				if (info.bpp == 24)
					easy = 1;
				else if (info.bpp == 32)
					if (mb == 0xff && mg == 0xff00 && mr == 0x00ff0000 && ma == 0xff000000)
						easy = 2;

				if (easy == 0)
				{
					if (mr == 0 || mg == 0 || mb == 0)
					{
						CRuntime.free(_out_);
						return (uint8*)(stbi__err("bad masks") != 0 ? null : null);
					}

					rshift = stbi__high_bit(mr) - 7;
					rcount = stbi__bitcount(mr);
					gshift = stbi__high_bit(mg) - 7;
					gcount = stbi__bitcount(mg);
					bshift = stbi__high_bit(mb) - 7;
					bcount = stbi__bitcount(mb);
					ashift = stbi__high_bit(ma) - 7;
					acount = stbi__bitcount(ma);
					if (rcount > 8 || gcount > 8 || bcount > 8 || acount > 8)
					{
						CRuntime.free(_out_);
						return (uint8*)(stbi__err("bad masks") != 0 ? null : null);
					}
				}

				for (j = 0; j < (int32)s.img_y; ++j)
				{
					if (easy != 0)
					{
						for (i = 0; i < (int32)s.img_x; ++i)
						{
							uint8 a = 0;
							_out_[z + 2] = stbi__get8(s);
							_out_[z + 1] = stbi__get8(s);
							_out_[z + 0] = stbi__get8(s);
							z += 3;
							a = (uint8)(easy == 2 ? stbi__get8(s) : 255);
							all_a |= a;
							if (target == 4)
								_out_[z++] = a;
						}
					}
					else
					{
						var bpp = info.bpp;
						for (i = 0; i < (int32)s.img_x; ++i)
						{
							var v = bpp == 16 ? (uint32)stbi__get16le(s) : stbi__get32le(s);
							uint32 a = 0;
							_out_[z++] = (uint8)(stbi__shiftsigned(v & mr, rshift, rcount) & 255);
							_out_[z++] = (uint8)(stbi__shiftsigned(v & mg, gshift, gcount) & 255);
							_out_[z++] = (uint8)(stbi__shiftsigned(v & mb, bshift, bcount) & 255);
							a = (uint32)(ma != 0 ? stbi__shiftsigned(v & ma, ashift, acount) : 255);
							all_a |= a;
							if (target == 4)
								_out_[z++] = (uint8)(a & 255);
						}
					}

					stbi__skip(s, pad);
				}
			}

			if (target == 4 && all_a == 0)
				for (i = (int32)(4 * s.img_x * s.img_y - 1); i >= 0; i -= 4)
					_out_[i] = 255;

			if (flip_vertically != 0)
			{
				uint8 t = 0;
				for (j = 0; j < (int32)s.img_y >> 1; ++j)
				{
					var p1 = _out_ + j * (int32)s.img_x * target;
					var p2 = _out_ + ((int32)s.img_y - 1 - j) * (int32)s.img_x * target;
					for (i = 0; i < (int32)s.img_x * target; ++i)
					{
						t = p1[i];
						p1[i] = p2[i];
						p2[i] = t;
					}
				}
			}

			if (req_comp != 0 && req_comp != target)
			{
				_out_ = stbi__convert_format(_out_, target, req_comp, s.img_x, s.img_y);
				if (_out_ == null)
					return _out_;
			}

			*x = (int32)s.img_x;
			*y = (int32)s.img_y;
			if (comp != null)
				*comp = s.img_n;
			return _out_;
		}

		public static void* stbi__bmp_parse_header(stbi__context s, stbi__bmp_data* info)
		{
			int32 hsz = 0;
			if (stbi__get8(s) != 66 || stbi__get8(s) != 77)
				return (uint8*)(stbi__err("not BMP") != 0 ? null : null);
			stbi__get32le(s);
			stbi__get16le(s);
			stbi__get16le(s);
			info.offset = (int32)stbi__get32le(s);
			info.hsz = hsz = (int32)stbi__get32le(s);
			info.mr = info.mg = info.mb = info.ma = 0;
			info.extra_read = 14;
			if (info.offset < 0)
				return (uint8*)(stbi__err("bad BMP") != 0 ? null : null);
			if (hsz != 12 && hsz != 40 && hsz != 56 && hsz != 108 && hsz != 124)
				return (uint8*)(stbi__err("unknown BMP") != 0 ? null : null);
			if (hsz == 12)
			{
				s.img_x = stbi__get16le(s);
				s.img_y = stbi__get16le(s);
			}
			else
			{
				s.img_x = (int32)stbi__get32le(s);
				s.img_y = (int32)stbi__get32le(s);
			}

			if (stbi__get16le(s) != 1)
				return (uint8*)(stbi__err("bad BMP") != 0 ? null : null);
			info.bpp = stbi__get16le(s);
			if (hsz != 12)
			{
				var compress = (int32)stbi__get32le(s);
				if (compress == 1 || compress == 2)
					return (uint8*)(stbi__err("BMP RLE") != 0 ? null : null);
				if (compress >= 4)
					return (uint8*)(stbi__err("BMP JPEG/PNG") != 0 ? null : null);
				if (compress == 3 && info.bpp != 16 && info.bpp != 32)
					return (uint8*)(stbi__err("bad BMP") != 0 ? null : null);
				stbi__get32le(s);
				stbi__get32le(s);
				stbi__get32le(s);
				stbi__get32le(s);
				stbi__get32le(s);
				if (hsz == 40 || hsz == 56)
				{
					if (hsz == 56)
					{
						stbi__get32le(s);
						stbi__get32le(s);
						stbi__get32le(s);
						stbi__get32le(s);
					}

					if (info.bpp == 16 || info.bpp == 32)
					{
						if (compress == 0)
						{
							stbi__bmp_set_mask_defaults(info, compress);
						}
						else if (compress == 3)
						{
							info.mr = stbi__get32le(s);
							info.mg = stbi__get32le(s);
							info.mb = stbi__get32le(s);
							info.extra_read += 12;
							if (info.mr == info.mg && info.mg == info.mb)
								return (uint8*)(stbi__err("bad BMP") != 0 ? null : null);
						}
						else
						{
							return (uint8*)(stbi__err("bad BMP") != 0 ? null : null);
						}
					}
				}
				else
				{
					int32 i = 0;
					if (hsz != 108 && hsz != 124)
						return (uint8*)(stbi__err("bad BMP") != 0 ? null : null);
					info.mr = stbi__get32le(s);
					info.mg = stbi__get32le(s);
					info.mb = stbi__get32le(s);
					info.ma = stbi__get32le(s);
					if (compress != 3)
						stbi__bmp_set_mask_defaults(info, compress);
					stbi__get32le(s);
					for (i = 0; i < 12; ++i) stbi__get32le(s);

					if (hsz == 124)
					{
						stbi__get32le(s);
						stbi__get32le(s);
						stbi__get32le(s);
						stbi__get32le(s);
					}
				}
			}

			return (void*)1;
		}

		public static int32 stbi__bmp_set_mask_defaults(stbi__bmp_data* info, int32 compress)
		{
			if (compress == 3)
				return 1;
			if (compress == 0)
			{
				if (info.bpp == 16)
				{
					info.mr = 31u << 10;
					info.mg = 31u << 5;
					info.mb = 31u << 0;
				}
				else if (info.bpp == 32)
				{
					info.mr = 0xffu << 16;
					info.mg = 0xffu << 8;
					info.mb = 0xffu << 0;
					info.ma = 0xffu << 24;
					info.all_a = 0;
				}
				else
				{
					info.mr = info.mg = info.mb = info.ma = 0;
				}

				return 1;
			}

			return 0;
		}

		public static int32 stbi__bmp_test(stbi__context s)
		{
			var r = stbi__bmp_test_raw(s);
			stbi__rewind(s);
			return r;
		}

		public static int32 stbi__bmp_test_raw(stbi__context s)
		{
			int32 r = 0;
			int32 sz = 0;
			if (stbi__get8(s) != 66)
				return 0;
			if (stbi__get8(s) != 77)
				return 0;
			stbi__get32le(s);
			stbi__get16le(s);
			stbi__get16le(s);
			stbi__get32le(s);
			sz = (int32)stbi__get32le(s);
			r = sz == 12 || sz == 40 || sz == 56 || sz == 108 || sz == 124 ? 1 : 0;
			return r;
		}

		public struct stbi__bmp_data
		{
			public int32 bpp;
			public int32 offset;
			public int32 hsz;
			public uint32 mr;
			public uint32 mg;
			public uint32 mb;
			public uint32 ma;
			public uint32 all_a;
			public int32 extra_read;
		}
	}
}