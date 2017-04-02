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

	fn clearLine(address: size_t, targetRow: u32)
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
}
