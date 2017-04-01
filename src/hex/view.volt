// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/hex/licence.volt (BOOST ver. 1.0).
/**
 * Source file for View struct.
 */
module hex.view;

import watt.algorithm : min, max;


struct View
{
public:
	screenTopInBytes: size_t;
	screenSizeInBytes: size_t;
	address: size_t;
	size: size_t;
	width: size_t;


public:
	fn setup(size: size_t, width: size_t, rows: size_t)
	{
		this.size = size;
		this.width = width;
		this.screenSizeInBytes = rows * width;
		adjust();
	}

	fn add(diff: size_t)
	{
		address = min(size - 1, diff + address);
		adjust();
	}

	fn sub(diff: size_t)
	{
		address = cast(size_t)max(0, cast(i64)address - cast(i64)diff);
		adjust();
	}

	fn adjust()
	{
		if (address < screenTopInBytes) {
			screenTopInBytes = alignDownToWidth(address);
		} else if (address >= screenTopInBytes + screenSizeInBytes) {
			screenTopInBytes = alignDownToWidth(address - screenSizeInBytes + width);
		}
	}

	fn alignDownToWidth(v: size_t) size_t
	{
		return (v / width) * width;
	}
}
