// Copyright © 2011-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/hex/licence.volt (BOOST ver. 1.0).
module hex.ui.gl.vga;

import hex.ui.gl.glyph;


fn uploadVGAGlyph(store: GlyphStore, vgaIndex: u8, glyphIndex: u16)
{
	src := cast(const(u8)[])glyphData[vgaIndex];
	uploadVGAGlyph(store, src, glyphIndex);
}

fn uploadVGAGlyph(store: GlyphStore, src: scope const(u8)[], glyphIndex: u16)
{
	stack: u8[80];
	copyVGAGlyph(stack[], src, 8);
	store.uploadGlyph(glyphIndex, stack);
}

fn copyVGAGlyph(target: scope u8[], src: scope const(u8)[], dstStride: u32)
{
	clear: u8 = 0x00;
	full: u8 = 0xff;
	dst: u32;

	foreach (lY; 0 .. GlyphHeight) {
		foreach (lX; 0 .. GlyphWidth) {
			data := (src[lY] >> lX) & 1;
			target[dst++] = data ? full : clear;
		}
		dst += dstStride - GlyphWidth;
	}
}

fn copyVGAGlyphBits(target: scope u8[], vgaIndex: u8)
{
	target[0 .. GlyphHeight] = cast(u8[])glyphData[vgaIndex];
}

enum u32 Width = 128;
enum u32 Height = 160;
enum u32 GlyphWidth = 8;
enum u32 GlyphHeight = 10;
global glyphData: immutable(char)[][256] = [
	"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
	"\x7e\x81\xa5\x81\xbd\x99\x81\x7e\x00\x00",
	"\x7e\xff\xdb\xff\xc3\xe7\xff\x7e\x00\x00",
	"\x6c\xfe\xfe\xfe\x7c\x38\x10\x00\x00\x00",
	"\x10\x38\x7c\xfe\x7c\x38\x10\x00\x00\x00",
	"\x38\x7c\x38\xfe\xfe\xd6\x10\x38\x00\x00",
	"\x10\x38\x7c\xfe\xfe\x7c\x10\x38\x00\x00",
	"\x00\x00\x00\x18\x3c\x3c\x18\x00\x00\x00",
	"\xff\xff\xff\xe7\xc3\xc3\xe7\xff\xff\xfe",
	"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
	"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
	"\xf0\xe0\xf0\xbe\x33\x33\x33\x1e\x00\x00",
	"\x3c\x66\x66\x66\x3c\x18\x7e\x18\x00\x00",
	"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
	"\xfe\xc6\xfe\xc6\xc6\xe6\x67\x03\x00\x00",
	"\x18\xdb\x3c\xe7\xe7\x3c\xdb\x18\x00\x00",
	"\x00\x02\x0e\x3e\xfe\x3e\x0e\x02\x00\x00",
	"\x00\x80\xe0\xf8\xfe\xf8\xe0\x80\x00\x00",
	"\x18\x3c\x7e\x18\x18\x7e\x3c\x18\x00\x00",
	"\x00\x66\x66\x66\x66\x66\x00\x66\x00\x00",
	"\x00\xfe\xdb\xdb\xde\xd8\xd8\xd8\x00\x00",
	"\x7c\x86\x3c\x66\x66\x3c\x61\x3e\x00\x00",
	"\x00\x00\x00\x00\x00\x7e\x7e\x7e\x00\x00",
	"\x18\x3c\x7e\x18\x7e\x3c\x18\xff\x00\x00",
	"\x00\x18\x3c\x7e\x18\x18\x18\x18\x00\x00",
	"\x00\x18\x18\x18\x18\x7e\x3c\x18\x00\x00",
	"\x00\x00\x18\x30\x7e\x30\x18\x00\x00\x00",
	"\x00\x00\x0c\x06\x3f\x06\x0c\x00\x00\x00",
	"\x00\x00\x00\x06\x06\x06\x7e\x00\x00\x00",
	"\x00\x00\x24\x66\xff\x66\x24\x00\x00\x00",
	"\x00\x00\x18\x3c\x7e\xff\xff\x00\x00\x00",
	"\x00\x00\xff\xff\x7e\x3c\x18\x00\x00\x00",
	"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
	"\x18\x18\x18\x18\x18\x18\x00\x18\x00\x00",
	"\x66\x66\x66\x00\x00\x00\x00\x00\x00\x00",
	"\x6c\x6c\xfe\x6c\x6c\xfe\x6c\x6c\x00\x00",
	"\x18\x7c\x06\x3e\x7c\x60\x3e\x18\x00\x00",
	"\x44\x2a\x2a\x14\x28\x54\x54\x22\x00\x00",
	"\x18\x24\x38\x1c\x56\x66\x26\xdc\x00\x00",
	"\x18\x18\x18\x00\x00\x00\x00\x00\x00\x00",
	"\x30\x08\x0c\x0c\x0c\x0c\x08\x30\x00\x00",
	"\x0c\x10\x30\x30\x30\x30\x10\x0c\x00\x00",
	"\x00\x00\x54\x38\x7c\x38\x54\x00\x00\x00",
	"\x00\x00\x18\x18\x7e\x18\x18\x00\x00\x00",
	"\x00\x00\x00\x00\x00\x00\x18\x18\x10\x08",
	"\x00\x00\x00\x00\x7e\x00\x00\x00\x00\x00",
	"\x00\x00\x00\x00\x00\x00\x18\x18\x00\x00",
	"\x40\x60\x30\x18\x0c\x06\x03\x01\x00\x00",
	"\x3c\x66\x66\x76\x6e\x66\x66\x3c\x00\x00",
	"\x1e\x18\x18\x18\x18\x18\x18\x7e\x00\x00",
	"\x3e\x60\x60\x30\x18\x0c\x06\x7e\x00\x00",
	"\x3e\x60\x60\x38\x60\x60\x60\x3e\x00\x00",
	"\x06\x36\x36\x7e\x30\x30\x30\x30\x00\x00",
	"\x7e\x06\x06\x3e\x60\x60\x60\x3e\x00\x00",
	"\x3c\x06\x06\x3e\x66\x66\x66\x3c\x00\x00",
	"\x7e\x60\x60\x30\x18\x0c\x0c\x0c\x00\x00",
	"\x3c\x66\x66\x3c\x3c\x66\x66\x3c\x00\x00",
	"\x3c\x66\x66\x66\x7c\x60\x60\x3c\x00\x00",
	"\x00\x18\x18\x00\x00\x18\x18\x00\x00\x00",
	"\x00\x18\x18\x00\x00\x18\x18\x10\x08\x00",
	"\x00\x20\x10\x08\x04\x08\x10\x20\x00\x00",
	"\x00\x00\x7c\x00\x00\x7c\x00\x00\x00\x00",
	"\x00\x04\x08\x10\x20\x10\x08\x04\x00\x00",
	"\x3e\x60\x60\x38\x0c\x0c\x00\x0c\x00\x00",
	"\x3c\x66\x66\x76\x76\x76\x06\x1c\x00\x00",
	"\x3c\x66\x66\x7e\x66\x66\x66\x66\x00\x00",
	"\x3e\x66\x66\x3e\x66\x66\x66\x3e\x00\x00",
	"\x7c\x06\x06\x06\x06\x06\x06\x7c\x00\x00",
	"\x3e\x66\x66\x66\x66\x66\x66\x3e\x00\x00",
	"\x7e\x06\x06\x1e\x06\x06\x06\x7e\x00\x00",
	"\x7e\x06\x06\x1e\x06\x06\x06\x06\x00\x00",
	"\x7c\x06\x06\x76\x66\x66\x66\x7c\x00\x00",
	"\x66\x66\x66\x7e\x66\x66\x66\x66\x00\x00",
	"\x7e\x18\x18\x18\x18\x18\x18\x7e\x00\x00",
	"\x60\x60\x60\x60\x66\x66\x66\x3c\x00\x00",
	"\x66\x66\x36\x1e\x26\x66\x66\x66\x00\x00",
	"\x06\x06\x06\x06\x06\x06\x06\x7e\x00\x00",
	"\xc6\xee\xd6\xd6\xc6\xc6\xc6\xc6\x00\x00",
	"\x66\x6e\x6e\x76\x76\x66\x66\x66\x00\x00",
	"\x3c\x66\x66\x66\x66\x66\x66\x3c\x00\x00",
	"\x3e\x66\x66\x66\x3e\x06\x06\x06\x00\x00",
	"\x3c\x66\x66\x66\x66\x76\x76\xfc\x00\x00",
	"\x3e\x66\x66\x66\x3e\x66\x66\x66\x00\x00",
	"\x7c\x06\x06\x3e\x7c\x60\x60\x3e\x00\x00",
	"\x7e\x18\x18\x18\x18\x18\x18\x18\x00\x00",
	"\x66\x66\x66\x66\x66\x66\x66\x3c\x00\x00",
	"\x66\x66\x66\x66\x66\x24\x3c\x18\x00\x00",
	"\xc6\xc6\xc6\xc6\xc6\xd6\xd6\x6c\x00\x00",
	"\x66\x66\x3c\x18\x18\x3c\x66\x66\x00\x00",
	"\x66\x66\x66\x24\x3c\x18\x18\x18\x00\x00",
	"\x7e\x70\x30\x18\x18\x0c\x0e\x7e\x00\x00",
	"\x3c\x0c\x0c\x0c\x0c\x0c\x0c\x3c\x00\x00",
	"\x02\x06\x0c\x18\x30\x60\xc0\x80\x00\x00",
	"\x3c\x30\x30\x30\x30\x30\x30\x3c\x00\x00",
	"\x18\x3c\x66\x00\x00\x00\x00\x00\x00\x00",
	"\x00\x00\x00\x00\x00\x00\x00\x7e\x00\x00",
	"\x18\x18\x30\x00\x00\x00\x00\x00\x00\x00",
	"\x00\x00\x3c\x60\x7c\x66\x66\x7c\x00\x00",
	"\x06\x06\x3e\x66\x66\x66\x66\x3e\x00\x00",
	"\x00\x00\x7c\x06\x06\x06\x06\x7c\x00\x00",
	"\x60\x60\x7c\x66\x66\x66\x66\x7c\x00\x00",
	"\x00\x00\x3c\x66\x66\x7e\x06\x7c\x00\x00",
	"\x78\x0c\x7e\x0c\x0c\x0c\x0c\x0c\x00\x00",
	"\x00\x00\x7c\x66\x66\x66\x66\x7c\x62\x3c",
	"\x06\x06\x3e\x66\x66\x66\x66\x66\x00\x00",
	"\x18\x00\x1e\x18\x18\x18\x18\x70\x00\x00",
	"\x60\x00\x60\x60\x60\x60\x60\x60\x62\x3c",
	"\x06\x06\x66\x36\x1e\x1e\x36\x66\x00\x00",
	"\x1e\x18\x18\x18\x18\x18\x18\x70\x00\x00",
	"\x00\x00\x6e\xd6\xd6\xc6\xc6\xc6\x00\x00",
	"\x00\x00\x3e\x66\x66\x66\x66\x66\x00\x00",
	"\x00\x00\x3c\x66\x66\x66\x66\x3c\x00\x00",
	"\x00\x00\x3e\x66\x66\x66\x3e\x06\x06\x06",
	"\x00\x00\x7c\x66\x66\x66\x7c\x60\x60\x60",
	"\x00\x00\x76\x6e\x06\x06\x06\x06\x00\x00",
	"\x00\x00\x7c\x06\x3e\x7c\x60\x3e\x00\x00",
	"\x0c\x0c\x7e\x0c\x0c\x0c\x0c\x78\x00\x00",
	"\x00\x00\x66\x66\x66\x66\x66\x7c\x00\x00",
	"\x00\x00\x66\x66\x66\x66\x24\x18\x00\x00",
	"\x00\x00\xc6\xc6\xc6\xd6\xd6\x6c\x00\x00",
	"\x00\x00\x66\x66\x24\x3c\x66\x66\x00\x00",
	"\x00\x00\x66\x66\x66\x66\x66\x7c\x62\x3c",
	"\x00\x00\x7e\x70\x30\x0c\x0e\x7e\x00\x00",
	"\x30\x18\x08\x0c\x0c\x08\x18\x30\x00\x00",
	"\x18\x18\x18\x18\x18\x18\x18\x18\x00\x00",
	"\x0c\x18\x10\x30\x30\x10\x18\x0c\x00\x00",
	"\x00\x00\x00\x00\x4c\x32\x00\x00\x00\x00",
	"\x00\x00\x18\x18\x24\x24\x42\x7e\x00\x00",
	"\x7c\x06\x06\x06\x06\x06\x06\x7c\x10\x0c",
	"\x66\x00\x66\x66\x66\x66\x66\x7c\x00\x00",
	"\x30\x18\x3c\x66\x66\x7e\x06\x7c\x00\x00",
	"\x3c\x42\x3c\x60\x7c\x66\x66\x7c\x00\x00",
	"\x66\x00\x3c\x60\x7c\x66\x66\x7c\x00\x00",
	"\x0c\x18\x3c\x60\x7c\x66\x66\x7c\x00\x00",
	"\x18\x18\x3c\x60\x7c\x66\x66\x7c\x00\x00",
	"\x00\x00\x7c\x06\x06\x06\x06\x7c\x10\x0c",
	"\x3c\x42\x3c\x66\x66\x7e\x06\x7c\x00\x00",
	"\x66\x00\x3c\x66\x66\x7e\x06\x7c\x00\x00",
	"\x0c\x18\x3c\x66\x66\x7e\x06\x7c\x00\x00",
	"\x66\x00\x1e\x18\x18\x18\x18\x70\x00\x00",
	"\x3c\x42\x00\x1e\x18\x18\x18\x70\x00\x00",
	"\x0c\x18\x00\x18\x18\x18\x18\x70\x00\x00",
	"\x66\x00\x3c\x66\x7e\x66\x66\x66\x00\x00",
	"\x18\x24\x3c\x66\x7e\x66\x66\x66\x00\x00",
	"\x30\x18\x7e\x06\x1e\x06\x06\x7e\x00\x00",
	"\x00\x00\x3c\x5a\x5c\x7a\x1a\x6c\x00\x00",
	"\x7c\x1a\x1a\x7e\x1a\x1a\x1a\x7a\x00\x00",
	"\x3c\x42\x3c\x66\x66\x66\x66\x3c\x00\x00",
	"\x66\x00\x3c\x66\x66\x66\x66\x3c\x00\x00",
	"\x0c\x18\x3c\x66\x66\x66\x66\x3c\x00\x00",
	"\x3c\x42\x00\x66\x66\x66\x66\x7c\x00\x00",
	"\x0c\x18\x00\x66\x66\x66\x66\x7c\x00\x00",
	"\x66\x00\x66\x66\x66\x66\x66\x7c\x62\x3c",
	"\x66\x3c\x66\x66\x66\x66\x66\x3c\x00\x00",
	"\x66\x00\x66\x66\x66\x66\x66\x3c\x00\x00",
	"\x00\x18\x7c\x06\x06\x06\x7c\x18\x00\x00",
	"\x00\x1c\x36\x26\x0f\x06\x66\x3f\x00\x00",
	"\x66\x66\x3c\x7e\x18\x7e\x18\x18\x00\x00",
	"\x1f\x33\x33\x5f\x63\xf3\x63\xe3\x00\x00",
	"\x70\xd8\x18\x3c\x18\x18\x1b\x0e\x00\x00",
	"\x30\x18\x3c\x60\x7c\x66\x66\x7c\x00\x00",
	"\x18\x0c\x00\x0c\x0c\x0c\x0c\x38\x00\x00",
	"\x30\x18\x3c\x66\x66\x66\x66\x3c\x00\x00",
	"\x30\x18\x00\x66\x66\x66\x66\x7c\x00\x00",
	"\x00\x4c\x32\x00\x3e\x66\x66\x66\x00\x00",
	"\x00\x4c\x32\x00\x6e\x7e\x76\x66\x00\x00",
	"\x00\x7c\x66\x66\x7c\x00\x7e\x00\x00\x00",
	"\x00\x3c\x66\x66\x3c\x00\x7e\x00\x00\x00",
	"\x30\x00\x30\x30\x1c\x06\x06\x7c\x00\x00",
	"\x00\x00\x00\x00\x7e\x06\x06\x00\x00\x00",
	"\x00\x00\x00\x00\x7e\x60\x60\x00\x00\x00",
	"\xc6\x67\x36\x7e\xcc\x66\x33\xf0\x00\x00",
	"\xc6\x67\x36\x5e\x6c\x56\xfb\x60\x00\x00",
	"\x18\x00\x18\x18\x18\x18\x18\x18\x00\x00",
	"\x00\x00\xcc\x66\x33\x66\xcc\x00\x00\x00",
	"\x00\x00\x33\x66\xcc\x66\x33\x00\x00\x00",
	"\x11\x44\x11\x44\x11\x44\x11\x44\x11\x44",
	"\x55\xaa\x55\xaa\x55\xaa\x55\xaa\x55\xaa",
	"\xbb\xee\xbb\xee\xbb\xee\xbb\xee\xbb\xee",
	"\x18\x18\x18\x18\x18\x18\x18\x18\x18\x18",
	"\x18\x18\x18\x18\x18\x1f\x18\x18\x18\x18",
	"\x18\x18\x18\x1f\x18\x1f\x18\x18\x18\x18",
	"\x6c\x6c\x6c\x6c\x6c\x6f\x6c\x6c\x6c\x6c",
	"\x00\x00\x00\x00\x00\x7f\x6c\x6c\x6c\x6c",
	"\x00\x00\x00\x1f\x18\x1f\x18\x18\x18\x18",
	"\x6c\x6c\x6c\x6f\x60\x6f\x6c\x6c\x6c\x6c",
	"\x6c\x6c\x6c\x6c\x6c\x6c\x6c\x6c\x6c\x6c",
	"\x00\x00\x00\x7f\x60\x6f\x6c\x6c\x6c\x6c",
	"\x6c\x6c\x6c\x6f\x60\x7f\x00\x00\x00\x00",
	"\x6c\x6c\x6c\x6c\x6c\x7f\x00\x00\x00\x00",
	"\x18\x18\x18\x1f\x18\x1f\x00\x00\x00\x00",
	"\x00\x00\x00\x00\x00\x1f\x18\x18\x18\x18",
	"\x18\x18\x18\x18\x18\xf8\x00\x00\x00\x00",
	"\x18\x18\x18\x18\x18\xff\x00\x00\x00\x00",
	"\x00\x00\x00\x00\x00\xff\x18\x18\x18\x18",
	"\x18\x18\x18\x18\x18\xf8\x18\x18\x18\x18",
	"\x00\x00\x00\x00\x00\xff\x00\x00\x00\x00",
	"\x18\x18\x18\x18\x18\xff\x18\x18\x18\x18",
	"\x18\x18\x18\xf8\x18\xf8\x18\x18\x18\x18",
	"\x6c\x6c\x6c\x6c\x6c\xec\x6c\x6c\x6c\x6c",
	"\x6c\x6c\x6c\xec\x0c\xfc\x00\x00\x00\x00",
	"\x00\x00\x00\xfc\x0c\xec\x6c\x6c\x6c\x6c",
	"\x6c\x6c\x6c\xef\x00\xff\x00\x00\x00\x00",
	"\x00\x00\x00\xff\x00\xef\x6c\x6c\x6c\x6c",
	"\x6c\x6c\x6c\xec\x0c\xec\x6c\x6c\x6c\x6c",
	"\x00\x00\x00\xff\x00\xff\x00\x00\x00\x00",
	"\x6c\x6c\x6c\xef\x00\xef\x6c\x6c\x6c\x6c",
	"\x18\x18\x18\xff\x00\xff\x00\x00\x00\x00",
	"\x6c\x6c\x6c\x6c\x6c\xff\x00\x00\x00\x00",
	"\x00\x00\x00\xff\x00\xff\x18\x18\x18\x18",
	"\x00\x00\x00\x00\x00\xff\x6c\x6c\x6c\x6c",
	"\x6c\x6c\x6c\x6c\x6c\xfc\x00\x00\x00\x00",
	"\x18\x18\x18\xf8\x18\xf8\x00\x00\x00\x00",
	"\x00\x00\x00\xf8\x18\xf8\x18\x18\x18\x18",
	"\x00\x00\x00\x00\x00\xfc\x6c\x6c\x6c\x6c",
	"\x6c\x6c\x6c\x6c\x6c\xff\x6c\x6c\x6c\x6c",
	"\x18\x18\x18\xff\x18\xff\x18\x18\x18\x18",
	"\x18\x18\x18\x18\x18\x1f\x00\x00\x00\x00",
	"\x00\x00\x00\x00\x00\xf8\x18\x18\x18\x18",
	"\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff",
	"\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff",
	"\x0f\x0f\x0f\x0f\x0f\x0f\x0f\x0f\x0f\x0f",
	"\xf0\xf0\xf0\xf0\xf0\xf0\xf0\xf0\xf0\xf0",
	"\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00",
	"\x00\x00\xdc\x76\x36\x36\x76\xdc\x00\x00",
	"\x1c\x26\x26\x36\x66\x66\x66\x36\x00\x00",
	"\x7e\x66\x66\x06\x06\x06\x06\x06\x00\x00",
	"\x00\x00\xfe\x6c\x6c\x6c\x6c\x6c\x00\x00",
	"\x7e\x66\x0c\x18\x18\x0c\x66\x7e\x00\x00",
	"\x00\x00\x7c\x36\x36\x36\x36\x1c\x00\x00",
	"\x00\x00\x66\x66\x66\x66\x66\x3e\x03\x00",
	"\x00\x00\x6c\x3a\x18\x18\x18\x18\x00\x00",
	"\x7e\x18\x3c\x66\x66\x3c\x18\x7e\x00\x00",
	"\x3c\x66\x66\x7e\x66\x66\x66\x3c\x00\x00",
	"\x00\x00\x7c\xc6\xc6\x6c\x6c\xc6\x00\x00",
	"\x00\x70\x18\x30\x7c\x66\x66\x3c\x00\x00",
	"\x00\x00\x7e\xdb\xdb\x7e\x00\x00\x00\x00",
	"\x60\x30\x7e\xdb\xdb\x7e\x06\x03\x00\x00",
	"\x00\x70\x0c\x06\x7e\x06\x0c\x70\x00\x00",
	"\x00\x00\x3c\x66\x66\x66\x66\x66\x00\x00",
	"\x00\x00\x7e\x00\x7e\x00\x7e\x00\x00\x00",
	"\x00\x18\x18\x7e\x18\x18\x00\x7e\x00\x00",
	"\x00\x0c\x18\x30\x18\x0c\x00\x7e\x00\x00",
	"\x00\x30\x18\x0c\x18\x30\x00\x7e\x00\x00",
	"\x38\x6c\x6c\x0c\x0c\x0c\x0c\x0c\x00\x00",
	"\x30\x30\x30\x30\x30\x36\x36\x1c\x00\x00",
	"\x00\x00\x18\x00\x7e\x00\x18\x00\x00\x00",
	"\x00\x00\x4c\x32\x00\x4c\x32\x00\x00\x00",
	"\x00\x1c\x36\x36\x1c\x00\x00\x00\x00\x00",
	"\x00\x00\x00\x00\x18\x18\x00\x00\x00\x00",
	"\x00\x00\x00\x00\x18\x00\x00\x00\x00\x00",
	"\xf0\x30\x30\x30\x37\x36\x3c\x38\x00\x00",
	"\x3e\x66\x66\x66\x66\x00\x00\x00\x00\x00",
	"\x1e\x30\x18\x0c\x3e\x00\x00\x00\x00\x00",
	"\x00\x00\x00\x3c\x3c\x3c\x3c\x00\x00\x00",
	"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
];
