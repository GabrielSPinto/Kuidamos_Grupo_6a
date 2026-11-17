"""Independent NumPy reference model and row-major bus conversion.

A/B: 16 signed int8 entries, flat little-index-first within 128-bit bus:
      element [row, col] occupies bus bits [8*(row*4+col) +: 8].
C:   16 signed int32 entries, similarly [32*(row*4+col) +: 32].
All text vectors carry *unsigned hexadecimal bit patterns*, not decimal signs.
"""
from __future__ import annotations

from typing import Iterable
import numpy as np

DIM = 4


def as_mat(values: Iterable[int]) -> np.ndarray:
    v = list(values)
    if len(v) != 16 or any(not -128 <= int(x) <= 127 for x in v):
        raise ValueError('expected exactly 16 signed int8 values')
    return np.asarray(v, dtype=np.int64).reshape((DIM, DIM))


def matmul(a: Iterable[int], b: Iterable[int]) -> list[int]:
    """Expected signed int32 elements in row-major order; no RTL reuse."""
    c = as_mat(a) @ as_mat(b)
    result = [int(x) for x in c.flat]
    if not all(-(1 << 31) <= x < (1 << 31) for x in result):
        raise OverflowError('output beyond signed int32')
    return result


def pack(elements: Iterable[int], width: int, *, signed: bool = True) -> int:
    values = list(elements)
    low, high = (-(1 << (width - 1)), (1 << (width - 1)) - 1) if signed else (0, (1 << width)-1)
    if any(not low <= int(x) <= high for x in values):
        raise ValueError(f'element outside {width}-bit range')
    bus = 0
    for index, value in enumerate(values):
        bus |= (int(value) & ((1 << width) - 1)) << (width * index)
    return bus


def unpack(bus: int, width: int, count: int = 16, *, signed: bool = True) -> list[int]:
    if bus < 0 or bus >= 1 << (width * count):
        raise ValueError('bus does not fit')
    mask = (1 << width) - 1
    out = []
    for index in range(count):
        val = (bus >> (width * index)) & mask
        if signed and val & (1 << (width - 1)):
            val -= 1 << width
        out.append(val)
    return out


def encode_vector(a: list[int], b: list[int]) -> str:
    c = matmul(a, b)
    return f'{pack(a,8):032x} {pack(b,8):032x} {pack(c,32):0128x}'
