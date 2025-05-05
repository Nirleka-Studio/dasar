# This script is taken from Godot engine
# https://github.com/godotengine/godot/blob/master/misc/scripts/ucaps_fetch.py
# Thanks for making my life more easier :D
# I dont know python, so this is my first time working with one.
#   NirlekaDev

#!/usr/bin/env python3

# Script used to dump case mappings from
# the Unicode Character Database to the `ucaps.h` file.
# NOTE: This script is deliberately not integrated into the build system;
# you should run it manually whenever you want to update the data.

import os
import sys
from typing import Final, List, Tuple
from urllib.request import urlopen

if __name__ == "__main__":
    sys.path.insert(1, os.path.join(os.path.dirname(__file__), "../../"))

URL: Final[str] = "https://www.unicode.org/Public/16.0.0/ucd/UnicodeData.txt"


lower_to_upper: List[Tuple[str, str]] = []
upper_to_lower: List[Tuple[str, str]] = []

def parse_unicode_data() -> None:
    lines: List[str] = [line.decode("utf-8") for line in urlopen(URL)]

    for line in lines:
        split_line: List[str] = line.split(";")

        code_value: str = split_line[0].strip()
        uppercase_mapping: str = split_line[12].strip()
        lowercase_mapping: str = split_line[13].strip()

        if uppercase_mapping:
            lower_to_upper.append((f"0x{code_value}", f"0x{uppercase_mapping}"))
        if lowercase_mapping:
            upper_to_lower.append((f"0x{code_value}", f"0x{lowercase_mapping}"))


def make_cap_table(table_name: str, len_name: str, table: List[Tuple[str, str]]) -> str:
    result: str = f"static const int {table_name}[{len_name}][2] = {{\n"

    for first, second in table:
        result += f"\t{{ {first}, {second} }},\n"

    result += "};\n\n"

    return result

def generate_ucaps_lua() -> None:
    parse_unicode_data()

    lua_lines: List[str] = [
        "-- ucaps.lua",
        "-- Auto-generated from ucaps_fetch.py",
        "",
        "local ucaps = {}",
        "",
        "ucaps.lower_to_upper = {"
    ]

    for lo, up in lower_to_upper:
        lo_dec = int(lo, 16)
        up_dec = int(up, 16)
        lua_lines.append(f"    [{lo_dec}] = {up_dec},")  # e.g. [97] = 65,

    lua_lines.append("}")
    lua_lines.append("")
    lua_lines.append("ucaps.upper_to_lower = {")

    for up, lo in upper_to_lower:
        up_dec = int(up, 16)
        lo_dec = int(lo, 16)
        lua_lines.append(f"    [{up_dec}] = {lo_dec},")  # e.g. [65] = 97,

    lua_lines.append("}")
    lua_lines.append("")
    lua_lines.append("function ucaps.to_upper(ch)")
    lua_lines.append("    return ucaps.lower_to_upper[ch] or ch")
    lua_lines.append("end")
    lua_lines.append("")
    lua_lines.append("function ucaps.to_lower(ch)")
    lua_lines.append("    return ucaps.upper_to_lower[ch] or ch")
    lua_lines.append("end")
    lua_lines.append("")
    lua_lines.append("return ucaps")

    lua_path = os.path.join(os.path.dirname(__file__), "../../src/library/string/ucaps.lua")
    with open(lua_path, "w", newline="\n") as f:
        f.write("\n".join(lua_lines))

    print("`ucaps.lua` generated successfully.")


generate_ucaps_lua()