"""Conservative source contract checks; NOT a substitute for RTL simulation or synthesis."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
SRC = (ROOT/'rtl/matmul4x4.sv').read_text(encoding='utf8')


class RtlStaticChecks(unittest.TestCase):
    def test_interface_and_clock(self):
        for name in ('clk', 'rst_n', 'start', 'done', 'matrix_a', 'matrix_b', 'matrix_c'):
            self.assertRegex(SRC, r'\b' + name + r'\b')
        self.assertIn('always_ff @(posedge clk)', SRC)
        self.assertIn('if (!rst_n)', SRC)

    def test_no_forbidden_behavioral_constructs(self):
        body = re.sub(r'//[^\n]*|/\*.*?\*/', ' ', SRC, flags=re.S)
        for pattern in (r'\binitial\b',r'\bforce\b',r'\brelease\b',r'\bcasex\b',r'\bcasez\b',r'\binout\b',r'\bforever\b',r'\balways\s*@',r'\b#\s*\d'):
            self.assertNotRegex(body, pattern)

    def test_generates_are_parallel(self):
        self.assertIn('for (row = 0; row < 4;', SRC)
        self.assertIn('for (col = 0; col < 4;', SRC)
        self.assertIn('sum01 + sum23', SRC)
        self.assertIn("matrix_c <= c_comb;", SRC)


if __name__ == '__main__':
    unittest.main(verbosity=2)
