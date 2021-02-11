/*
 * This file is part of moss-format.
 *
 * Copyright © 2020-2021 Serpent OS Developers
 *
 * This software is provided 'as-is', without any express or implied
 * warranty. In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 */

module moss.format.binary.legacy;

public import std.stdint : uint32_t;

public import moss.format.binary.archive_header;
public import moss.format.binary.endianness;
public import moss.format.binary.reader;
public import moss.format.binary.writer;

/**
 * Current version of the package format that we target.
 */
const uint32_t mossFormatVersionNumber = 1;

public import moss.format.binary.legacy.content_payload;
public import moss.format.binary.legacy.index;
public import moss.format.binary.legacy.index_payload;
public import moss.format.binary.legacy.layout;
public import moss.format.binary.legacy.layout_payload;
public import moss.format.binary.legacy.meta_payload;
public import moss.format.binary.legacy.payload;
public import moss.format.binary.legacy.record;