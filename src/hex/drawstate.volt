// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/hex/licence.volt (BOOST ver. 1.0).
/**
 * Source file for DrawState struct.
 */
module hex.drawstate;

import hex.ui.gl.glyph;


enum HEX_DIGITS = "0123456789abcdef";

fn toHex(v: u64) u8
{
	return HEX_DIGITS[v & 0xf];
}

struct DrawState
{
public:
	grid: GlyphGrid;
	fg: u32;
	bg: u32;
	targetRow: u32;
	column: u32;


public:
	fn reset(grid: GlyphGrid, targetRow: u32)
	{
		this.fg = 0;
		this.bg = 0;
		this.grid = grid;
		this.targetRow = targetRow;
		this.column = 0;
	}

	fn drawHex2(hex: size_t)
	{
		drawChar(toHex(hex >> 4u));
		drawChar(toHex(hex >> 0u));
	}

	fn drawHex4(hex: size_t)
	{
		drawChar(toHex(hex >> 12u));
		drawChar(toHex(hex >>  8u));
		drawChar(toHex(hex >>  4u));
		drawChar(toHex(hex >>  0u));
	}

	fn drawHex8(hex: size_t)
	{
		shift := 32u;
		foreach (i; 0u .. (32u/4u)) {
			shift -= 4u;
			drawChar(toHex(hex >> shift));
		}
	}

	fn drawHex16(hex: u64)
	{
		shift := 64u;
		foreach (i; 0u .. (64u/4u)) {
			shift -= 4u;
			drawChar(toHex(hex >> shift));
		}
	}

	fn drawChar(c: u8)
	{
		grid.put(column++, targetRow, fg, bg, c);
	}

	fn drawChars(data: scope u8[])
	{
		foreach (d; data) {
			grid.put(column++, targetRow, fg, bg, d);
		}
	}
}
