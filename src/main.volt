module main;

import io = watt.io;
import watt.io.file : read;
import watt.path : getExecFile;
import watt.text.format;

import lib.gl;
import hex.core;
import hex.view;
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
	mData: u8[];



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
		mGlyphs := new GlyphStore(GlyphWidth, GlyphHeight);
		foreach (index; 0u .. 256u) {
			uploadVGAGlyph(mGlyphs, cast(u8)index, cast(u16)index);
		}

		// And then setup the renderer.
		mGrid = new GlyphGrid(mRenderer, mGlyphs, mWin.width, mWin.height);

		mapFile(filename);
		mapGlyphs();
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
	}

	fn mapGlyphs()
	{
		glyphSize := hex.ui.gl.vga.GlyphWidth * hex.ui.gl.vga.GlyphHeight;
		mData = new u8[](glyphSize * 256);

		foreach (i; 0u .. 256u) {
			dst := i * glyphSize;
			copyVGAGlyph(mData[dst .. $], 0, 0xDBu, cast(u8)i, 8);
		}

		mView.setup(mData.length, 8, mGrid.numGlyphsY);
	}


private:
	fn getColors(address: size_t, colorType: i32, out fg: Color, out bg: Color)
	{
		if (colorType == DataColor && isHit(address)) {
			bg = Color.Blue;
			fg = Color.Green;
		} else if ((address / mView.width) % 4 < 2) {
			bg = Color.Black;
			fg = Color.White;
		} else {
			bg = Color.DarkGrey;
			fg = Color.White;
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
		mView.setup(mData.length, 16, mGrid.numGlyphsY);
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
		case Unknown: default:
		}
	}

	fn onRender()
	{
		updateAll();
		mGrid.render();
	}

	fn updateAll()
	{
		address := mView.screenTopInBytes;
		foreach (y; 0 .. mGrid.numGlyphsY) {
			if (address >= mData.length) {
				clearLine(address, y);
			} else {
				updateLine(address, y);
			}
			address += mView.width;
		}
	}

	fn updateLine(address: size_t, targetRow: u32)
	{
		fg, bg: Color;
		getColors(address, DecorationColor, out fg, out bg);

		// Start with showing the address.
		column: u32;
		foreach (i; 0u .. (64u/4u)) {
			c := toHex(address >> (64u - 4u - i * 4));
			mGrid.put(column++, targetRow, fg, bg, c);
		}

		// Two spaces
		mGrid.put(column++, targetRow, fg, bg, ' ');
		mGrid.put(column++, targetRow, fg, bg, ' ');

		// Display the data as hex values.
		foreach (i; 0u .. mView.width) {
			sel := i + address;
			getColors(sel, DataColor, out fg, out bg);

			if (sel < mData.length) {
				d := mData[sel];
				mGrid.put(column++, targetRow, fg, bg, toHex(d >> 4u));
				mGrid.put(column++, targetRow, fg, bg, toHex(d >> 0u));
			} else {
				mGrid.put(column++, targetRow, fg, bg, ' ');
				mGrid.put(column++, targetRow, fg, bg, ' ');
			}

			getColors(sel, DecorationColor, out fg, out bg);
			mGrid.put(column++, targetRow, fg, bg, ' ');
			if (i == 7) {
				mGrid.put(column++, targetRow, fg, bg, ' ');
			}
		}

		// Two spaces
		mGrid.put(column++, targetRow, fg, bg, ' ');
		mGrid.put(column++, targetRow, fg, bg, ' ');

		// Draw a separator
		mGrid.put(column++, targetRow, fg, bg, 0x7C);

		// Display the value as VGA characters.
		foreach (i; 0u .. mView.width) {
			sel := i + address;
			getColors(sel, DataColor, out fg, out bg);

			if (sel < mData.length) {
				d := mData[sel];
				mGrid.put(column++, targetRow, fg, bg, d);
			} else {
				mGrid.put(column++, targetRow, fg, bg, '.');
			}
		}

		// Draw a separator
		getColors(address, DecorationColor, out fg, out bg);
		mGrid.put(column++, targetRow, fg, bg, 0x7C);

		// Fill out the screen.
		foreach (i; column .. mGrid.numGlyphsX) {
			mGrid.put(column++, targetRow, fg, bg, ' ');
		}
	}

	fn clearLine(address: size_t, targetRow: u32)
	{
		fg, bg: Color;
		getColors(address, DecorationColor, out fg, out bg);

		foreach (x; 0 .. mGrid.numGlyphsX) {
			mGrid.put(x, targetRow, fg, bg, ' ');
		}
	}

	fn isHit(address: size_t) bool
	{
		return mView.address == address;
	}

	enum HEX_DIGITS = "0123456789abcdef";

	static fn toHex(v: u64) u8
	{
		return HEX_DIGITS[v & 0xf];
	}
}
