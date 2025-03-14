from os import add_dll_directory
add_dll_directory('/MinGW/bin/')
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import decimal
decimal.getcontext().prec = 85
import time
import numpy as np
import imageio
import asyncio
import warnings
# from tests import unittest
# unittest.main()
print('executing')
import video_copy
plt.imshow(video_copy._data)
plt.show()
exit()
import time
from matplotlib import pyplot as plt

import src.mandelbrot_decimal as mandelbrot_decimal
import src.mandelbrot as mandelbrot
import tests.precision_mandelbrot as mdt
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import decimal
decimal.getcontext().prec = 85
import time
import numpy as np
import imageio
import asyncio
import warnings

warnings.filterwarnings('ignore')
np.seterr(all="ignore", )
real, imag = decimal.Decimal('0.2505845176040427718957771316508473905552515740661571423212687174479167'), decimal.Decimal('0.00002276281458802574942404639696751451557095909568791588147481282552083')
# data = np.rot90(new_video.main(-2, 0.5, -1.3, 0, 500, 250, 100))
# w = imageio.get_writer('mandelbrot.mp4', format='FFMPEG', mode='I', fps=30, output_params=['-preset', 'ultrafast', '-tune', 'zerolatency', '-an'], macro_block_size=16, )
iterations = 1000

xmin = decimal.Decimal('-2.0')
xmax = decimal.Decimal('1.0')
ymin = decimal.Decimal('-1.2')
ymax = decimal.Decimal('1.2')
zoom_const = decimal.Decimal('0.95')
#n_recip = norm_decimal_from_double(1/100)

def thread(yt, yb, lx, rx, i):
    print(i, end='\r')
    if i < 535:  # 17.65 seconds in
        return np.rot90(mandelbrot.main(float(yt), float(yb), float(lx), float(rx), 320, 240, 150+round(i*(2 if i < 200 else (4 if i < 450 else (5)))), False))
    else:
        return np.rot90(mandelbrot_decimal.run(yt, yb, lx, rx, 320, 240, 2700))

async def main():
    global xmin, xmax, ymin, ymax, real, imag
    data = []
    fig, ax = plt.subplots()
    
    for i in range(iterations):
        data += [asyncio.to_thread(thread, xmin, xmax, ymin, ymax, int(i))]
        ymin = (((ymin-imag)*zoom_const)+imag)
        ymax = (((ymax-imag)*zoom_const)+imag)
        xmin = (((xmin-real)*zoom_const)+real)
        xmax = (((xmax-real)*zoom_const)+real)
        
    data = np.array(await asyncio.gather(*data, return_exceptions=True, ), dtype=np.uint32) 
    print("\nWriting...\n")
    def update(n):
        ax.cla()
        ax.imshow(data[n], cmap='binary')
        # print(n,end='\r')cls
        # xmin = fractions.simplify_fraction(xmin)
        # ymin = fractions.simplify_fraction(ymin)
        # ymax = fractions.simplify_fraction(ymax)
        # xmax = fractions.simplify_fraction(xmax)
        # # data += [asyncio.to_thread(thread, xmin, xmax, ymin, ymax, int(i))]
        # ymin = fractions.add_fractions(fractions.mult_fractions(fractions.sub_fractions(ymin, imag), zoom_const), imag)
        # ymax = fractions.add_fractions(fractions.mult_fractions(fractions.sub_fractions(ymax, imag), zoom_const), imag)
        # xmin = fractions.add_fractions(fractions.mult_fractions(fractions.sub_fractions(xmin, real), zoom_const), real)
        # xmax = fractions.add_fractions(fractions.mult_fractions(fractions.sub_fractions(xmax, real), zoom_const), real)
        # ax.imshow(thread(xmin, xmax, ymin, ymax, n))
    ani = animation.FuncAnimation(fig=fig, func=update, interval=1000/30, frames=range(iterations))
    ani.save('mandelbrot.mp4')
    plt.show()
    # for i in (data):
        # w.append_data(i)
    # print('\nDone Writing\n')
    # w.close()
asyncio.run(main())
# data = pickle.load(open('data.pk', 'rb'))
# pickle.dump(data, open('data.pk', 'wb'))
# plt.imshow(data)
# plt.show()
