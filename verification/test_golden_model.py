"""Independent software-model, packing and fixture correctness checks."""
import random
import unittest
import numpy as np
from golden_model import matmul, pack, unpack, encode_vector
from generate_vectors import directed_cases


class GoldenModelTests(unittest.TestCase):
    def test_zero_identity(self):
        z = [0]*16
        identity = [1 if i//4 == i%4 else 0 for i in range(16)]
        a = list(range(-8, 8))
        self.assertEqual(matmul(a, identity), a)
        self.assertEqual(matmul(identity, a), a)
        self.assertEqual(matmul(a, z), z)

    def test_signed_extremes(self):
        self.assertEqual(matmul([-128]*16, [-128]*16), [65536]*16)
        self.assertEqual(matmul([-128]*16, [127]*16), [-65024]*16)
        self.assertEqual(matmul([127]*16, [-128]*16), [-65024]*16)
        self.assertEqual(matmul([127]*16, [127]*16), [64516]*16)

    def test_row_major_mapping(self):
        a = [-128,-1,0,127] * 4
        self.assertEqual(unpack(pack(a,8),8), a)
        self.assertEqual(pack([1]+[0]*15, 8), 1)
        self.assertEqual(pack([0]*15+[1], 8), 1 << 120)
        c = [-65024,0,65536,1]*4
        self.assertEqual(unpack(pack(c,32),32), c)
        self.assertEqual(pack([1]+[0]*15,32), 1)
        self.assertEqual(pack([0]*15+[1],32), 1 << 480)

    def test_against_separate_scalar_loop(self):
        rng = random.Random(617)
        for _ in range(300):
            a = [rng.randrange(-128, 128) for i in range(16)]
            b = [rng.randrange(-128, 128) for i in range(16)]
            scalar = [sum(a[4*r+k]*b[4*k+c] for k in range(4))
                      for r in range(4) for c in range(4)]
            self.assertEqual(matmul(a,b), scalar)
            self.assertEqual(unpack(pack(matmul(a,b),32),32),scalar)

    def test_encoding_fields(self):
        a,b = directed_cases()[0]
        fields = encode_vector(a,b).split()
        self.assertEqual([len(x) for x in fields],[32,32,128])
        self.assertEqual(unpack(int(fields[0],16),8),a)
        self.assertEqual(unpack(int(fields[1],16),8),b)
        self.assertEqual(unpack(int(fields[2],16),32),matmul(a,b))

    def test_reject_wrong_width(self):
        with self.assertRaises(ValueError): pack([128], 8)
        with self.assertRaises(ValueError): pack([-129], 8)
        with self.assertRaises(ValueError): matmul([0]*15,[0]*16)


if __name__ == '__main__':
    unittest.main(verbosity=2)


class FixtureTests(unittest.TestCase):
    def test_all_vector_lines_match_golden_model(self):
        from pathlib import Path
        root = Path(__file__).resolve().parents[1]
        path = root/'vectors/matmul_vectors.txt'
        self.assertTrue(path.exists())
        total = 0
        with path.open(encoding='ascii') as f:
            for line in f:
                total += 1
                fields = line.split()
                self.assertEqual(len(fields), 3, f'vector {total}')
                a = unpack(int(fields[0],16),8)
                b = unpack(int(fields[1],16),8)
                c = unpack(int(fields[2],16),32)
                self.assertEqual(c, matmul(a,b), f'vector {total}')
        self.assertEqual(total,1044)
