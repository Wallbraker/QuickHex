module main;

import io = watt.io;
import watt.io.file : read;
import watt.path : getExecFile;
import watt.text.format;

import lib.gl;
import hex.core;
import hex.view;
import hex.drawstate;
import hex.ui.key;
import hex.ui.gl.glyph;
import hex.ui.gl.vga;


fn main(args: string[]) i32
{
	app := new App(args);
	return app.run();
}


class App
{
private:
	enum Color : u32 {
		White = 0xFF_FF_FF_FFu,
		Red   = 0xFF_00_00_FFu,
		Green = 0xFF_00_FF_00u,
		Blue  = 0xFF_FF_00_00u,
		Black = 0xFF_00_00_00u,

		DarkGrey = 0xFF_10_10_10u,

		AmigaBg    = 0xFF_AF_57_00u,
		AmigaFg    = 0xFF_FF_FF_FFu,
		AmigaSelBg = 0xFF_00_88_FFu,
		AmigaSelFg = 0xFF_20_00_00u,
	}

	enum {
		DataColor,
		DecorationColor,
	}


private:
	mRenderer: GlyphRenderer;
	mGlyphs: GlyphStore;
	mGrid: GlyphGrid;
	mArgs: string[];
	mCore: Core;
	mWin: Window;

	mView: View;
	mDrawBits: bool;
	mData: u8[];

	mEdit: dg();

public:
	this(args: string[])
	{
		filename := args.length > 1 ? args[1] : getExecFile();

		mArgs = args;

		mCore = Core.create();
		mWin = mCore.createWindow();
		mWin.title = "QuickHex";
		mWin.onText = onText;
		mWin.onDestroy = onDestroy;
		mWin.onKeyDown = onKeyDown;
		mWin.onRender = onRender;
		mWin.onResize = onResize;

		// Needed for all other glyph parts.
		mRenderer := new GlyphRenderer();

		// Setup glyph size and store
		mGlyphs = new GlyphStore(GlyphWidth, GlyphHeight);
		foreach (index; 0u .. 256u) {
			uploadVGAGlyph(mGlyphs, cast(u8)index, cast(u16)index);
		}

		// And then setup the renderer.
		mGrid = new GlyphGrid(mRenderer, mGlyphs, mWin.width, mWin.height);

		mEdit = nopEdit;
		mapFile(filename);
	}

	fn run() i32
	{
		return mCore.loop();
	}

	fn mapFile(filename: string)
	{
		mData = cast(u8[])read(filename);
		mWin.title = format("QuickHex - %s", filename);
		mView.setup(mData.length, 16, mGrid.numGlyphsY);
		mDrawBits = false;
		mEdit = nopEdit;
	}

	fn mapGlyphs()
	{
		glyphSize := hex.ui.gl.vga.GlyphHeight;
		mData = new u8[](glyphSize * 256);

		foreach (i; 0u .. 256u) {
			dst := i * glyphSize;
			copyVGAGlyphBits(mData[dst .. $], cast(u8)i);
		}

		mView.setup(mData.length * 8, 8, mGrid.numGlyphsY);
		mDrawBits = true;
		mEdit = editVGA;
	}

	fn dumpVGA()
	{
		foreach (i, d; mData) {
			io.output.writef(`\x%02x`, d);
			if (i % 10 == 9) {
				io.output.writefln("");
			}
		}
		io.output.flush();
	}


private:
	fn editVGA()
	{
		elemt := mView.address / 8;
		shift := mView.address % 8;
		mData[elemt] ^= cast(u8)(1 << shift);

		index := elemt / hex.ui.gl.vga.GlyphHeight;
		start := index * hex.ui.gl.vga.GlyphHeight;
		end := start + hex.ui.gl.vga.GlyphHeight;
		//io.writefln("%s %s %s", index, start, end);
		uploadVGAGlyph(mGlyphs, mData[start .. end], cast(u16)index);
	}

	fn getColors(ref draw: DrawState, address: size_t, colorType: i32)
	{
		if (colorType == DataColor && isHit(address)) {
			draw.bg = Color.Blue;
			draw.fg = Color.Green;
		} else if ((address / mView.width) % 4 < 2) {
			draw.bg = Color.Black;
			draw.fg = Color.White;
		} else {
			draw.bg = Color.DarkGrey;
			draw.fg = Color.White;
		}
	}

	fn onDestroy()
	{
		if (mGlyphs !is null) {
			mGlyphs.close();
			mGlyphs = null;
		}
		if (mRenderer !is null) {
			mRenderer.close();
			mRenderer = null;
		}
	}

	fn onResize()
	{
		glViewport(0, 0, cast(int)mWin.width, cast(int)mWin.height);
		mGrid.setScreenSize(mWin.width, mWin.height);
		// Just reset the numbers of rows.
		mView.setup(mView.size, mView.width, mGrid.numGlyphsY);
	}

	fn onText(str: const(char)[])
	{
	}

	fn onKeyDown(key: Key, mod: Mod)
	{
		switch (key) with (Key) {
		case Down:     mView.add(mView.width); break;
		case Up:       mView.sub(mView.width); break;
		case Left:     mView.sub(         1); break;
		case Right:    mView.add(         1); break;
		case PageUp:   mView.sub(       128); break;
		case PageDown: mView.add(       128); break;
		case Escape: mCore.signalClose(); break;
		case ' ': mEdit(); break;
		case Unknown: default:
		}
	}

	fn onRender()
	{
		if (mDrawBits) {
			drawBits();
		} else {
			drawHex();
		}
		mGrid.render();
	}

	fn drawHex()
	{
		address := mView.screenTopInBytes;
		foreach (y; 0 .. mGrid.numGlyphsY) {
			if (address >= mData.length) {
				drawEmptLine(address, y);
			} else {
				drawHexLine(address, y);
			}
			address += mView.width;
		}
	}

	fn drawHexLine(address: size_t, targetRow: u32)
	{
		draw: DrawState;
		draw.reset(mGrid, targetRow);
		getColors(ref draw, address, DecorationColor);

		// Start with showing the address.
		draw.drawHex16(address);

		// Two spaces
		draw.drawChar(' ');
		draw.drawChar(' ');

		// Display the data as hex values.
		foreach (i; 0u .. mView.width) {
			sel := i + address;
			getColors(ref draw, sel, DataColor);

			if (sel < mData.length) {
				draw.drawHex2(mData[sel]);
			} else {
				draw.drawChar(' ');
				draw.drawChar(' ');
			}

			getColors(ref draw, sel, DecorationColor);
			draw.drawChar(' ');
			if (i == 7) {
				draw.drawChar(' ');
			}
		}

		// Two spaces
		draw.drawChar(' ');
		draw.drawChar(' ');

		// Draw a separator
		draw.drawChar(0x7C);

		// Display the value as VGA characters.
		foreach (i; 0u .. mView.width) {
			sel := i + address;
			getColors(ref draw, sel, DataColor);

			if (sel < mData.length) {
				d := mData[sel];
				draw.drawChar(d);
			} else {
				draw.drawChar('.');
			}
		}

		// Draw a separator
		getColors(ref draw, address, DecorationColor);
		draw.drawChar(0x7C);

		// Fill out the screen.
		foreach (i; draw.column .. mGrid.numGlyphsX) {
			draw.drawChar(' ');
		}
	}

	fn drawBits()
	{
		address := mView.screenTopInBytes;
		foreach (y; 0 .. mGrid.numGlyphsY) {
			if (address >= mView.size) {
				drawEmptLine(address, y);
			} else {
				drawLineBits(address, y);
			}
			address += mView.width;
		}
	}

	fn drawLineBits(address: size_t, targetRow: u32)
	{
		draw: DrawState;
		draw.reset(mGrid, targetRow);
		getColors(ref draw, address, DecorationColor);

		// Start with showing the address.
		draw.drawHex16(address / 8);

		// Two spaces
		draw.drawChar(' ');
		draw.drawChar(' ');

		// Display the data as hex values.
		foreach (i; 0u .. mView.width) {
			viewAddress := i + address;
			elemt := viewAddress / 8;
			shift := viewAddress % 8;

			getColors(ref draw, viewAddress, DataColor);

			if (elemt < mData.length) {
				d := mData[elemt] >> shift & 1;
				draw.drawChar(d ? '1' : '0');
			} else {
				draw.drawChar(' ');
			}

			getColors(ref draw, viewAddress, DecorationColor);
		}

		// Two spaces
		draw.drawChar(' ');
		draw.drawChar(' ');

		// Draw a separator
		draw.drawChar(0x7C);

		// Display the value as VGA characters.
		foreach (i; 0u .. mView.width) {
			viewAddress := i + address;
			elemt := viewAddress / 8;
			shift := viewAddress % 8;

			getColors(ref draw, viewAddress, DataColor);

			if (elemt < mData.length) {
				d := mData[elemt] >> shift & 1;
				draw.drawChar(d ? 0xDB : ' ');
			} else {
				draw.drawChar('.');
			}
		}

		// Draw a separator
		getColors(ref draw, address, DecorationColor);
		draw.drawChar(0x7C);

		if (targetRow < 16) {
			draw.drawChar(' ');
			start := targetRow * 16;
			foreach (i; start .. start + 16) {
				draw.drawChar(cast(u8)i);
			}
		}

		// Fill out the screen.
		foreach (i; draw.column .. mGrid.numGlyphsX) {
			draw.drawChar(' ');
		}
	}

	fn drawEmptLine(address: size_t, targetRow: u32)
	{
		fg, bg: Color;
		draw: DrawState;
		draw.reset(mGrid, targetRow);
		getColors(ref draw, address, DecorationColor);

		foreach (x; 0 .. mGrid.numGlyphsX) {
			mGrid.put(x, targetRow, fg, bg, ' ');
		}
	}

	fn isHit(address: size_t) bool
	{
		return mView.address == address;
	}

	fn nopEdit() {}
}
