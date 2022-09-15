// Generated by Sichem at 12/24/2021 8:28:15 PM

using System;
using Hebron.Runtime;

namespace StbImageBeef
{
	extension StbImage
	{
		public const int32 STBI__SCAN_header = 2;
		public const int32 STBI__SCAN_load = 0;
		public const int32 STBI__SCAN_type = 1;
		public const int32 STBI_default = 0;
		public const int32 STBI_grey = 1;
		public const int32 STBI_grey_alpha = 2;
		public const int32 STBI_ORDER_BGR = 1;
		public const int32 STBI_ORDER_RGB = 0;
		public const int32 STBI_rgb = 3;
		public const int32 STBI_rgb_alpha = 4;

		public static uint8[?] stbi__compute_huffman_codes_length_dezigzag =
			.(16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15);

		public static int32 stbi__de_iphone_flag_global;
		public static int32 stbi__de_iphone_flag_local;
		public static int32 stbi__de_iphone_flag_set;
		public static float stbi__h2l_gamma_i = 1.0f / 2.2f;
		public static float stbi__h2l_scale_i = 1.0f;
		public static float stbi__l2h_gamma = 2.2f;
		public static float stbi__l2h_scale = 1.0f;
		public static uint8[?] stbi__process_frame_header_rgb = .( 82, 71, 66 );
		public static uint8[?] stbi__process_marker_tag = .( 65, 100, 111, 98, 101, 0 );
		public static int32[?] stbi__shiftsigned_mul_table = .( 0, 0xff, 0x55, 0x49, 0x11, 0x21, 0x41, 0x81, 0x01 );
		public static int32[?] stbi__shiftsigned_shift_table = .( 0, 0, 0, 1, 0, 2, 4, 6, 0 );
		public static int32 stbi__unpremultiply_on_load_global;
		public static int32 stbi__unpremultiply_on_load_local;
		public static int32 stbi__unpremultiply_on_load_set;
		public static int32 stbi__vertically_flip_on_load_global;
		public static int32 stbi__vertically_flip_on_load_local;
		public static int32 stbi__vertically_flip_on_load_set;

		public static int32 stbi__addsizes_valid(int32 a, int32 b)
		{
			if (b < 0)
				return 0;
			return a <= 2147483647 - b ? 1 : 0;
		}

		[Inline]
		public static int32 stbi__bit_reverse(int32 v, int32 bits)
		{
			return stbi__bitreverse16(v) >> (16 - bits);
		}

		public static int32 stbi__bitcount(uint32 aInput)
		{
			uint32 a = aInput;
			a = (a & 0x55555555) + ((a >> 1) & 0x55555555);
			a = (a & 0x33333333) + ((a >> 2) & 0x33333333);
			a = (a + (a >> 4)) & 0x0f0f0f0f;
			a = a + (a >> 8);
			a = a + (a >> 16);
			return (int32)(a & 0xff);
		}

		[Inline]
		public static int32 stbi__bitreverse16(int32 nInput)
		{
			int32 n = nInput;
			n = ((n & 0xAAAA) >> 1) | ((n & 0x5555) << 1);
			n = ((n & 0xCCCC) >> 2) | ((n & 0x3333) << 2);
			n = ((n & 0xF0F0) >> 4) | ((n & 0x0F0F) << 4);
			n = ((n & 0xFF00) >> 8) | ((n & 0x00FF) << 8);
			return n;
		}

		public static uint8 stbi__blinn_8x8(uint8 x, uint8 y)
		{
			var t = (uint32)((int32)x * (int32)y + 128);
			return (uint8)((t + (t >> 8)) >> 8);
		}

		[Inline]
		public static uint8 stbi__clamp(int32 x)
		{
			if ((uint32)x > 255)
			{
				if (x < 0)
					return 0;
				if (x > 255)
					return 255;
			}

			return (uint8)x;
		}

		public static uint8 stbi__compute_y(int32 r, int32 g, int32 b)
		{
			return (uint8)((r * 77 + g * 150 + 29 * b) >> 8);
		}

		public static uint16 stbi__compute_y_16(int32 r, int32 g, int32 b)
		{
			return (uint16)((r * 77 + g * 150 + 29 * b) >> 8);
		}

		public static uint8* stbi__convert_16_to_8(uint16* orig, int32 w, int32 h, int32 channels)
		{
			int32 i = 0;
			var img_len = w * h * channels;
			uint8* reduced;
			reduced = (uint8*)stbi__malloc((uint64)img_len);
			if (reduced == null)
				return (uint8*)(stbi__err("outofmem") != 0 ? null : null);
			for (i = 0; i < img_len; ++i) reduced[i] = (uint8)((orig[i] >> 8) & 0xFF);

			CRuntime.free(orig);
			return reduced;
		}

		public static uint16* stbi__convert_8_to_16(uint8* orig, int32 w, int32 h, int32 channels)
		{
			int32 i = 0;
			var img_len = w * h * channels;
			uint16* enlarged;
			enlarged = (uint16*)stbi__malloc((uint64)(img_len * 2));
			if (enlarged == null)
				return (uint16*)(uint8*)(stbi__err("outofmem") != 0 ? null : null);
			for (i = 0; i < img_len; ++i) enlarged[i] = (uint16)(((uint16)orig[i] << 8) + orig[i]);

			CRuntime.free(orig);
			return enlarged;
		}

		public static uint8* stbi__convert_format(uint8* data, int32 img_n, int32 req_comp, int32 x, int32 y)
		{
			int32 i = 0;
			int32 j = 0;
			uint8* good;
			if (req_comp == img_n)
				return data;
			good = (uint8*)stbi__malloc_mad3(req_comp, (int32)x, (int32)y, 0);
			if (good == null)
			{
				CRuntime.free(data);
				return (uint8*)(stbi__err("outofmem") != 0 ? null : null);
			}

			for (j = 0; j < (int32)y; ++j)
			{
				var src = data + j * x * img_n;
				var dest = good + j * x * req_comp;
				switch (img_n * 8 + req_comp)
				{
					case 1 * 8 + 2:
						for (i = (int32)(x - 1); i >= 0; --i, src += 1, dest += 2)
						{
							dest[0] = src[0];
							dest[1] = 255;
						}

						break;
					case 1 * 8 + 3:
						for (i = (int32)(x - 1); i >= 0; --i, src += 1, dest += 3) dest[0] = dest[1] = dest[2] = src[0];

						break;
					case 1 * 8 + 4:
						for (i = (int32)(x - 1); i >= 0; --i, src += 1, dest += 4)
						{
							dest[0] = dest[1] = dest[2] = src[0];
							dest[3] = 255;
						}

						break;
					case 2 * 8 + 1:
						for (i = (int32)(x - 1); i >= 0; --i, src += 2, dest += 1) dest[0] = src[0];

						break;
					case 2 * 8 + 3:
						for (i = (int32)(x - 1); i >= 0; --i, src += 2, dest += 3) dest[0] = dest[1] = dest[2] = src[0];

						break;
					case 2 * 8 + 4:
						for (i = (int32)(x - 1); i >= 0; --i, src += 2, dest += 4)
						{
							dest[0] = dest[1] = dest[2] = src[0];
							dest[3] = src[1];
						}

						break;
					case 3 * 8 + 4:
						for (i = (int32)(x - 1); i >= 0; --i, src += 3, dest += 4)
						{
							dest[0] = src[0];
							dest[1] = src[1];
							dest[2] = src[2];
							dest[3] = 255;
						}

						break;
					case 3 * 8 + 1:
						for (i = (int32)(x - 1); i >= 0; --i, src += 3, dest += 1)
							dest[0] = stbi__compute_y(src[0], src[1], src[2]);

						break;
					case 3 * 8 + 2:
						for (i = (int32)(x - 1); i >= 0; --i, src += 3, dest += 2)
						{
							dest[0] = stbi__compute_y(src[0], src[1], src[2]);
							dest[1] = 255;
						}

						break;
					case 4 * 8 + 1:
						for (i = (int32)(x - 1); i >= 0; --i, src += 4, dest += 1)
							dest[0] = stbi__compute_y(src[0], src[1], src[2]);

						break;
					case 4 * 8 + 2:
						for (i = (int32)(x - 1); i >= 0; --i, src += 4, dest += 2)
						{
							dest[0] = stbi__compute_y(src[0], src[1], src[2]);
							dest[1] = src[3];
						}

						break;
					case 4 * 8 + 3:
						for (i = (int32)(x - 1); i >= 0; --i, src += 4, dest += 3)
						{
							dest[0] = src[0];
							dest[1] = src[1];
							dest[2] = src[2];
						}

						break;
					default:
						CRuntime.free(data);
						CRuntime.free(good);
						return (uint8*)(stbi__err("unsupported") != 0 ? null : null);
				}
			}

			CRuntime.free(data);
			return good;
		}

		public static uint16* stbi__convert_format16(uint16* data, int32 img_n, int32 req_comp, int32 x, int32 y)
		{
			int32 i = 0;
			int32 j = 0;
			uint16* good;
			if (req_comp == img_n)
				return data;
			good = (uint16*)stbi__malloc(req_comp * x * y * 2);
			if (good == null)
			{
				CRuntime.free(data);
				return (uint16*)(uint8*)(stbi__err("outofmem") != 0 ? null : null);
			}

			for (j = 0; j < (int32)y; ++j)
			{
				var src = data + j * x * img_n;
				var dest = good + j * x * req_comp;
				switch (img_n * 8 + req_comp)
				{
					case 1 * 8 + 2:
						for (i = (int32)(x - 1); i >= 0; --i, src += 1, dest += 2)
						{
							dest[0] = src[0];
							dest[1] = 0xffff;
						}

						break;
					case 1 * 8 + 3:
						for (i = (int32)(x - 1); i >= 0; --i, src += 1, dest += 3) dest[0] = dest[1] = dest[2] = src[0];

						break;
					case 1 * 8 + 4:
						for (i = (int32)(x - 1); i >= 0; --i, src += 1, dest += 4)
						{
							dest[0] = dest[1] = dest[2] = src[0];
							dest[3] = 0xffff;
						}

						break;
					case 2 * 8 + 1:
						for (i = (int32)(x - 1); i >= 0; --i, src += 2, dest += 1) dest[0] = src[0];

						break;
					case 2 * 8 + 3:
						for (i = (int32)(x - 1); i >= 0; --i, src += 2, dest += 3) dest[0] = dest[1] = dest[2] = src[0];

						break;
					case 2 * 8 + 4:
						for (i = (int32)(x - 1); i >= 0; --i, src += 2, dest += 4)
						{
							dest[0] = dest[1] = dest[2] = src[0];
							dest[3] = src[1];
						}

						break;
					case 3 * 8 + 4:
						for (i = (int32)(x - 1); i >= 0; --i, src += 3, dest += 4)
						{
							dest[0] = src[0];
							dest[1] = src[1];
							dest[2] = src[2];
							dest[3] = 0xffff;
						}

						break;
					case 3 * 8 + 1:
						for (i = (int32)(x - 1); i >= 0; --i, src += 3, dest += 1)
							dest[0] = stbi__compute_y_16(src[0], src[1], src[2]);

						break;
					case 3 * 8 + 2:
						for (i = (int32)(x - 1); i >= 0; --i, src += 3, dest += 2)
						{
							dest[0] = stbi__compute_y_16(src[0], src[1], src[2]);
							dest[1] = 0xffff;
						}

						break;
					case 4 * 8 + 1:
						for (i = (int32)(x - 1); i >= 0; --i, src += 4, dest += 1)
							dest[0] = stbi__compute_y_16(src[0], src[1], src[2]);

						break;
					case 4 * 8 + 2:
						for (i = (int32)(x - 1); i >= 0; --i, src += 4, dest += 2)
						{
							dest[0] = stbi__compute_y_16(src[0], src[1], src[2]);
							dest[1] = src[3];
						}

						break;
					case 4 * 8 + 3:
						for (i = (int32)(x - 1); i >= 0; --i, src += 4, dest += 3)
						{
							dest[0] = src[0];
							dest[1] = src[1];
							dest[2] = src[2];
						}

						break;
					default:
						CRuntime.free(data);
						CRuntime.free(good);
						return (uint16*)(uint8*)(stbi__err("unsupported") != 0 ? null : null);
				}
			}

			CRuntime.free(data);
			return good;
		}

		public static void stbi__float_postprocess(float* result, int32* x, int32* y, int32* comp, int32 req_comp)
		{
			if ((stbi__vertically_flip_on_load_set != 0
				? stbi__vertically_flip_on_load_local
				: stbi__vertically_flip_on_load_global) != 0 && result != null)
			{
				var channels = req_comp != 0 ? req_comp : *comp;
				stbi__vertical_flip(result, *x, *y, channels * sizeof(float));
			}
		}

		public static int32 stbi__get16be(stbi__context s)
		{
			int32 z = stbi__get8(s);
			return (z << 8) + stbi__get8(s);
		}

		public static int32 stbi__get16le(stbi__context s)
		{
			var z = (uint16)stbi__get8(s);
			return z + ((uint16)stbi__get8(s) << 8);
		}

		public static uint32 stbi__get32be(stbi__context s)
		{
			var z = (uint32)stbi__get16be(s);
			return (uint32)((z << 16) + (uint32)stbi__get16be(s));
		}

		public static uint32 stbi__get32le(stbi__context s)
		{
			var z = (uint32)stbi__get16le(s);
			z += (uint32)stbi__get16le(s) << 16;
			return z;
		}

		public static int32 stbi__high_bit(uint32 zInput)
		{
			uint32 z = zInput;
			int32 n = 0;
			if (z == 0)
				return -1;
			if (z >= 0x10000)
			{
				n += 16;
				z >>= 16;
			}

			if (z >= 0x00100)
			{
				n += 8;
				z >>= 8;
			}

			if (z >= 0x00010)
			{
				n += 4;
				z >>= 4;
			}

			if (z >= 0x00004)
			{
				n += 2;
				z >>= 2;
			}

			if (z >= 0x00002)
			{
				n += 1;
				z >>= 1;
			}

			return n;
		}

		public static int32 stbi__info_main(stbi__context s, int32* x, int32* y, int32* comp)
		{
			if (stbi__jpeg_info(s, x, y, comp) != 0)
				return 1;
			if (stbi__png_info(s, x, y, comp) != 0)
				return 1;
			if (stbi__gif_info(s, x, y, comp) != 0)
				return 1;
			if (stbi__bmp_info(s, x, y, comp) != 0)
				return 1;
			if (stbi__psd_info(s, x, y, comp) != 0)
				return 1;
			if (stbi__tga_info(s, x, y, comp) != 0)
				return 1;
			return stbi__err("unknown image type");
		}

		public static int32 stbi__is_16_main(stbi__context s)
		{
			if (stbi__png_is16(s) != 0)
				return 1;
			if (stbi__psd_is16(s) != 0)
				return 1;
			return 0;
		}

		public static float* stbi__ldr_to_hdr(uint8* data, int32 x, int32 y, int32 comp)
		{
			int32 i = 0;
			int32 k = 0;
			int32 n = 0;
			float* output;
			if (data == null)
				return null;
			output = (float*)stbi__malloc_mad4(x, y, comp, sizeof(float), 0);
			if (output == null)
			{
				CRuntime.free(data);
				return (float*)(stbi__err("outofmem") != 0 ? null : null);
			}

			if ((comp & 1) != 0)
				n = comp;
			else
				n = comp - 1;
			for (i = 0; i < x * y; ++i)
				for (k = 0; k < n; ++k)
					output[i * comp + k] =
						(float)(CRuntime.pow(data[i * comp + k] / 255.0f, stbi__l2h_gamma) * stbi__l2h_scale);

			if (n < comp)
				for (i = 0; i < x * y; ++i)
					output[i * comp + n] = data[i * comp + n] / 255.0f;

			CRuntime.free(data);
			return output;
		}

		public static uint16* stbi__load_and_postprocess_16bit(stbi__context s, int32* x, int32* y, int32* comp, int32 req_comp)
		{
			stbi__result_info ri = default;
			var result = stbi__load_main(s, x, y, comp, req_comp, &ri, 16);
			if (result == null)
				return null;
			if (ri.bits_per_channel != 16)
			{
				result = stbi__convert_8_to_16((uint8*)result, *x, *y, req_comp == 0 ? *comp : req_comp);
				ri.bits_per_channel = 16;
			}

			if ((stbi__vertically_flip_on_load_set != 0
				? stbi__vertically_flip_on_load_local
				: stbi__vertically_flip_on_load_global) != 0)
			{
				var channels = req_comp != 0 ? req_comp : *comp;
				stbi__vertical_flip(result, *x, *y, channels * sizeof(uint16));
			}

			return (uint16*)result;
		}

		public static uint8* stbi__load_and_postprocess_8bit(stbi__context s, int32* x, int32* y, int32* comp, int32 req_comp)
		{
			stbi__result_info ri = default;
			var result = stbi__load_main(s, x, y, comp, req_comp, &ri, 8);
			if (result == null)
				return null;
			if (ri.bits_per_channel != 8)
			{
				result = stbi__convert_16_to_8((uint16*)result, *x, *y, req_comp == 0 ? *comp : req_comp);
				ri.bits_per_channel = 8;
			}

			if ((stbi__vertically_flip_on_load_set != 0
				? stbi__vertically_flip_on_load_local
				: stbi__vertically_flip_on_load_global) != 0)
			{
				var channels = req_comp != 0 ? req_comp : *comp;
				stbi__vertical_flip(result, *x, *y, channels * sizeof(uint8));
			}

			return (uint8*)result;
		}

		public static void* stbi__load_main(stbi__context s, int32* x, int32* y, int32* comp, int32 req_comp,
			stbi__result_info* ri, int32 bpc)
		{
			CRuntime.memset(ri, 0, (uint64)sizeof(stbi__result_info));
			ri.bits_per_channel = 8;
			ri.channel_order = STBI_ORDER_RGB;
			ri.num_channels = 0;
			if (stbi__png_test(s) != 0)
				return stbi__png_load(s, x, y, comp, req_comp, ri);
			if (stbi__bmp_test(s) != 0)
				return stbi__bmp_load(s, x, y, comp, req_comp, ri);
			if (stbi__gif_test(s) != 0)
				return stbi__gif_load(s, x, y, comp, req_comp, ri);
			if (stbi__psd_test(s) != 0)
				return stbi__psd_load(s, x, y, comp, req_comp, ri, bpc);
			if (stbi__jpeg_test(s) != 0)
				return stbi__jpeg_load(s, x, y, comp, req_comp, ri);

			if (stbi__tga_test(s) != 0)
				return stbi__tga_load(s, x, y, comp, req_comp, ri);
			return (uint8*)(stbi__err("unknown image type") != 0 ? null : null);
		}

		public static int32 stbi__mad2sizes_valid(int32 a, int32 b, int32 add)
		{
			return stbi__mul2sizes_valid(a, b) != 0 && stbi__addsizes_valid(a * b, add) != 0 ? 1 : 0;
		}

		public static int32 stbi__mad3sizes_valid(int32 a, int32 b, int32 c, int32 add)
		{
			return stbi__mul2sizes_valid(a, b) != 0 && stbi__mul2sizes_valid(a * b, c) != 0 &&
				   stbi__addsizes_valid(a * b * c, add) != 0
				? 1
				: 0;
		}

		public static int32 stbi__mad4sizes_valid(int32 a, int32 b, int32 c, int32 d, int32 add)
		{
			return stbi__mul2sizes_valid(a, b) != 0 && stbi__mul2sizes_valid(a * b, c) != 0 &&
				   stbi__mul2sizes_valid(a * b * c, d) != 0 && stbi__addsizes_valid(a * b * c * d, add) != 0
				? 1
				: 0;
		}

		public static void* stbi__malloc(uint64 size)
		{
			return CRuntime.malloc(size);
		}

		public static void* stbi__malloc(int64 size)
		{
			return CRuntime.malloc(size);
		}

		public static void* stbi__malloc_mad2(int32 a, int32 b, int32 add)
		{
			if (stbi__mad2sizes_valid(a, b, add) == 0)
				return null;
			return stbi__malloc((uint64)(a * b + add));
		}

		public static void* stbi__malloc_mad3(int32 a, int32 b, int32 c, int32 add)
		{
			if (stbi__mad3sizes_valid(a, b, c, add) == 0)
				return null;
			return stbi__malloc((uint64)(a * b * c + add));
		}

		public static void* stbi__malloc_mad4(int32 a, int32 b, int32 c, int32 d, int32 add)
		{
			if (stbi__mad4sizes_valid(a, b, c, d, add) == 0)
				return null;
			return stbi__malloc((uint64)(a * b * c * d + add));
		}

		public static int32 stbi__mul2sizes_valid(int32 a, int32 b)
		{
			if (a < 0 || b < 0)
				return 0;
			if (b == 0)
				return 1;
			return a <= 2147483647 / b ? 1 : 0;
		}

		public static int32 stbi__paeth(int32 a, int32 b, int32 c)
		{
			var p = a + b - c;
			var pa = CRuntime.abs(p - a);
			var pb = CRuntime.abs(p - b);
			var pc = CRuntime.abs(p - c);
			if (pa <= pb && pa <= pc)
				return a;
			if (pb <= pc)
				return b;
			return c;
		}

		public static int32 stbi__shiftsigned(uint32 vInput, int32 shift, int32 bits)
		{
			uint32 v = vInput;
			if (shift < 0)
				v <<= -shift;
			else
				v >>= shift;
			v >>= 8 - bits;
			return (int32)((int32)v * (int32)stbi__shiftsigned_mul_table[bits]) >> (int32)stbi__shiftsigned_shift_table[bits];
		}

		public static void stbi__unpremultiply_on_load_thread(int32 flag_true_if_should_unpremultiply)
		{
			stbi__unpremultiply_on_load_local = flag_true_if_should_unpremultiply;
			stbi__unpremultiply_on_load_set = 1;
		}

		public static void stbi__vertical_flip(void* image, int32 w, int32 h, int32 uint8s_per_pixel)
		{
			int32 row = 0;
			var uint8s_per_row = w * uint8s_per_pixel;
			uint8[2048] temp = ?;
			var uint8s = (uint8*)image;
			for (row = 0; row < h >> 1; row++)
			{
				var row0 = uint8s + row * uint8s_per_row;
				var row1 = uint8s + (h - row - 1) * uint8s_per_row;
				var uint8s_left = (uint64)uint8s_per_row;
				while (uint8s_left != 0)
				{
					var uint8s_copy = uint8s_left < 2048 * sizeof(uint8) ? uint8s_left : 2048 * sizeof(uint8);
					CRuntime.memcpy(&temp[0], row0, uint8s_copy);
					CRuntime.memcpy(row0, row1, uint8s_copy);
					CRuntime.memcpy(row1, &temp[0], uint8s_copy);
					row0 += uint8s_copy;
					row1 += uint8s_copy;
					uint8s_left -= uint8s_copy;
				}
			}
		}

		public static void stbi__vertical_flip_slices(void* image, int32 w, int32 h, int32 z, int32 uint8s_per_pixel)
		{
			int32 slice = 0;
			var slice_size = w * h * uint8s_per_pixel;
			var uint8s = (uint8*)image;
			for (slice = 0; slice < z; ++slice)
			{
				stbi__vertical_flip(uint8s, w, h, uint8s_per_pixel);
				uint8s += slice_size;
			}
		}

		public static void stbi_convert_iphone_png_to_rgb(int32 flag_true_if_should_convert)
		{
			stbi__de_iphone_flag_global = flag_true_if_should_convert;
		}

		public static void stbi_convert_iphone_png_to_rgb_thread(int32 flag_true_if_should_convert)
		{
			stbi__de_iphone_flag_local = flag_true_if_should_convert;
			stbi__de_iphone_flag_set = 1;
		}

		public static void stbi_hdr_to_ldr_gamma(float gamma)
		{
			stbi__h2l_gamma_i = 1 / gamma;
		}

		public static void stbi_hdr_to_ldr_scale(float scale)
		{
			stbi__h2l_scale_i = 1 / scale;
		}

		public static void stbi_ldr_to_hdr_gamma(float gamma)
		{
			stbi__l2h_gamma = gamma;
		}

		public static void stbi_ldr_to_hdr_scale(float scale)
		{
			stbi__l2h_scale = scale;
		}

		public static void stbi_set_flip_vertically_on_load(int32 flag_true_if_should_flip)
		{
			stbi__vertically_flip_on_load_global = flag_true_if_should_flip;
		}

		public static void stbi_set_flip_vertically_on_load_thread(int32 flag_true_if_should_flip)
		{
			stbi__vertically_flip_on_load_local = flag_true_if_should_flip;
			stbi__vertically_flip_on_load_set = 1;
		}

		public static void stbi_set_unpremultiply_on_load(int32 flag_true_if_should_unpremultiply)
		{
			stbi__unpremultiply_on_load_global = flag_true_if_should_unpremultiply;
		}

		public struct stbi__result_info
		{
			public int32 bits_per_channel;
			public int32 num_channels;
			public int32 channel_order;
		}
	}
}