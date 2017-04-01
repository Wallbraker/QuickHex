module main;

import io = watt.io;
import watt.algorithm;
import watt.io.file : read;
import watt.path : getExecFile;
import watt.text.format;

import lib.gl;
import hex.core;
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
	mRenderer: GlyphRenderer;
	mGlyphs: GlyphStore;
	mGrid: GlyphGrid;
	mArgs: string[];
	mCore: Core;
	mWin: Window;
	mFG, mBG, mSelFG, mSelBG: Color;

	mData: u8[];
	mOffsetInRows: i64;
	mMaxOffset: i64;

	mCurX, mCurY: u32;

	enum Color : u32 {
		White = 0xFF_FF_FF_FFu,
		Red   = 0xFF_00_00_FFu,
		Green = 0xFF_00_FF_00u,
		Blue  = 0xFF_FF_00_00u,
		Black = 0xFF_00_00_00u,
	}


public:
	this(args: string[])
	{
		filename := args.length > 1 ? args[1] : getExecFile();

		mArgs = args;

		mCore = Core.create();
		mWin = mCore.createWindow();
		mWin.title = format("QuickHex - %s", filename);
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
			mGlyphs.uploadVGAGlyph(cast(u8)index, cast(u16)index);
		}

		// And then setup the renderer.
		mGrid = new GlyphGrid(mRenderer, mGlyphs, mWin.width, mWin.height);

		// Setup the default colors.
		mFG = Color.White;
		mBG = Color.Black;
		mSelFG = Color.Green;
		mSelBG = Color.Blue;

		mapFile(filename);
	}

	fn run() i32
	{
		return mCore.loop();
	}

	fn mapFile(filename: string)
	{
		mData = cast(u8[])read(filename);
		mMaxOffset = cast(i64)(mData.length / 16);
	}


private:
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
	}

	fn onText(str: const(char)[])
	{
	}

	fn onKeyDown(key: Key, mod: Mod)
	{
		switch (key) with (Key) {
		case Down:     cursorMove(  0,   1); break;
		case Up:       cursorMove(  0,  -1); break;
		case Left:     cursorMove( -1,   0); break;
		case Right:    cursorMove(  1,   0); break;
		case PageUp:   cursorMove(  0, -40); break;
		case PageDown: cursorMove(  0,  40); break;
		case Escape: mCore.signalClose(); break;
		case Unknown: default:
		}
	}

	fn cursorMove(x: i32, y: i32)
	{
		x += cast(i32)mCurX;
		y += cast(i32)mCurY;

		mCurX = cast(u32)max(min(15, x), 0);

		if (y < 0) {
			mCurY = 0;
			moveOffset(y);
		} else if (y >= cast(i32)mGrid.numGlyphsY) {
			diff := (y + 1) - cast(i32)mGrid.numGlyphsY;
			moveOffset(diff);
			mCurY = mGrid.numGlyphsY - 1;
		} else {
			mCurY = cast(u32)y;
		}
	}

	fn moveOffset(diff: i64)
	{
		diff += mOffsetInRows;
		mOffsetInRows = max(min(mMaxOffset, diff), 0);
	}

	fn onRender()
	{
		updateAll();
		mGrid.render();
	}

	fn updateAll()
	{
		address := cast(u64)(mOffsetInRows * 16);
		foreach (y; 0 .. mGrid.numGlyphsY) {
			if (address >= mData.length) {
				clearLine(y);
			} else {
				updateLine(address, y);
			}
			address += 0x10;
		}
	}

	fn updateLine(address: u64, targetRow: u32)
	{
		// Start with showing the address.
		column: u32;
		foreach (i; 0u .. (64u/4u)) {
			c := toHex(address >> (64u - 4u - i * 4));
			mGrid.put(column++, targetRow, mFG, mBG, c);
		}

		// Pad out to column 10.
		column = 18;

		fg, bg: Color;

		// Display the data as hex values.
		foreach (i; 0u .. 16u) {
			getColors(i, targetRow, out fg, out bg);

			sel := i + address;
			if (sel < mData.length) {
				d := mData[sel];
				mGrid.put(column++, targetRow, fg, bg, toHex(d >> 4u));
				mGrid.put(column++, targetRow, fg, bg, toHex(d >> 0u));
			} else {
				mGrid.put(column++, targetRow, fg, bg, ' ');
				mGrid.put(column++, targetRow, fg, bg, ' ');
			}
			column += i == 7 ? 2 : 1;
		}

		// Pad out to column (16 + 2 + 16 * 2 + 1 + 2)
		column = 69;

		// Display the value as VGA characters.
		mGrid.put(column++, targetRow, mFG, mBG, 0x7C);
		foreach (i; 0u .. 16u) {
			getColors(i, targetRow, out fg, out bg);

			sel := i + address;
			if (sel < mData.length) {
				d := mData[sel];
				mGrid.put(column++, targetRow, fg, bg, d);
			} else {
				mGrid.put(column++, targetRow, fg, bg, ' ');
			}
		}

		// Pad out to column (8 + 2 + 16 * 2 + 1 + 2 + 1 + 16)
		column = 86;
		mGrid.put(column++, targetRow, mFG, mBG, 0x7C);
	}

	fn clearLine(targetRow: u32)
	{
		foreach (x; 0 .. mGrid.numGlyphsX) {
			mGrid.put(x, targetRow, mFG, mBG, ' ');
		}

		if (targetRow != mCurY) {
			return;
		}

		// Pad out to column 10.
		column := 18u;

		// Draw the cursor outside of the file.
		foreach (i; 0u .. 16u) {
			if (isHit(i, targetRow)) {
				mGrid.put(column++, targetRow, mSelFG, mSelBG, ' ');
				mGrid.put(column++, targetRow, mSelFG, mSelBG, ' ');
			} else {
				column += 2;
			}
			column += i == 7 ? 2 : 1;
		}
	}

	fn isHit(x: u32, y: u32) bool
	{
		return mCurX == x && mCurY == y;
	}

	fn getColors(x: u32, y: u32, out fg: Color, out bg: Color)
	{
		hit := isHit(x, y);
		fg = hit ? mSelFG : mFG;
		bg = hit ? mSelBG : mBG;
	}

	enum HEX_DIGITS = "0123456789abcdef";

	static fn toHex(v: u64) u8
	{
		return HEX_DIGITS[v & 0xf];
	}
}
