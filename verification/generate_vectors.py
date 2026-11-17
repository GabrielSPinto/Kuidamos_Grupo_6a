#!/usr/bin/env python3
"""Create deterministic mixed directed/random self-checking test vectors."""
from __future__ import annotations
import argparse
from pathlib import Path
import random
from golden_model import encode_vector


def directed_cases():
    z = [0] * 16
    ident = [1 if i//4 == i%4 else 0 for i in range(16)]
    ramp = [(i * 17) % 256 - 128 for i in range(16)]
    chequer = [-128 if i % 2 == 0 else 127 for i in range(16)]
    cases = [
        (z, z), (ident, ident), (ident, ramp), (ramp, ident),
        ([127]*16, [127]*16), ([-128]*16, [-128]*16),
        ([-128]*16, [127]*16), ([127]*16, [-128]*16),
        (chequer, chequer), (ramp, list(reversed(ramp))),
        ([1]*16, [-1]*16), ([0]*16, [127]*16),
    ]
    for i in range(16):
        a = [0]*16; a[i] = -128
        b = [0]*16; b[(i * 7) % 16] = 127
        cases.append((a, b))
    # Additional sparse cases expose row/column ordering errors.
    for i in range(16):
        a = [0]*16; a[i] = 1
        cases.append((a, ident))
    return cases


def generate(path: Path, random_count: int = 1000, seed: int = 0x6A2026) -> int:
    rng = random.Random(seed)
    cases = directed_cases()
    for _ in range(random_count):
        a = [rng.randint(-128, 127) for _ in range(16)]
        b = [rng.randint(-128, 127) for _ in range(16)]
        cases.append((a, b))
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('w', encoding='ascii', newline='\n') as f:
        for a, b in cases:
            f.write(encode_vector(a, b) + '\n')
    print(f'Wrote {len(cases)} test vectors to {path} (seed={seed}, random={random_count}).')
    return len(cases)


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--output', default='vectors/matmul_vectors.txt')
    p.add_argument('--random', type=int, default=1000)
    p.add_argument('--seed', type=lambda s: int(s, 0), default=0x6A2026)
    args = p.parse_args()
    if args.random < 0:
        p.error('--random must be >= 0')
    generate(Path(args.output), args.random, args.seed)
