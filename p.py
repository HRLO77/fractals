import pstats, cProfile

from tests import cynum

cProfile.runctx("cynum.testing()", globals(), locals(), "Profile.prof")

s = pstats.Stats("Profile.prof")
s.strip_dirs().sort_stats("time").print_stats()