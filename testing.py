from os import add_dll_directory
add_dll_directory('/MinGW/bin/')
from tests.unittest import main
main()
exit()
import src.fractional_mandelbrot as fractional_mandelbrot
import src.mandelbrot as mandelbrot
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from src import fractions
from src.fractions import as_double
import time
import numpy as np
import imageio
import asyncio
import warnings
warnings.filterwarnings('ignore')
np.seterr(all="ignore", )
# real, imag = -0.76157365, -0.0847596
9223372036854775807
2505845176040427718

#2509454650592482087342640547804463796997222058204507288191957258460945920067932343217317590785647228784651974204518464228331383156032371079078631455923903051272210295751754005731991039684
real, imag = fractions.fraction(numerator=2505845176040427718957771316508473905552515740661571423212687174479167, denominator=10000000000000000000000000000000000000000000000000000000000000000000000), fractions.fraction(numerator=2276281458802574942404639696751451557095909568791588147481282552083, denominator=100000000000000000000000000000000000000000000000000000000000000000000000)
# 0.2505845176040427718957771316508473905552515740661571423212687174479167
# 0.00002276281458802574942404639696751451557095909568791588147481282552083
# other possible zooms,  (-1.62917,-0.0203968)  (0.42884,-0.231345)
# data = np.rot90(new_video.main(-2, 0.5, -1.3, 0, 500, 250, 100))
# w = imageio.get_writer('mandelbrot.mp4', format='FFMPEG', mode='I', fps=30, output_params=['-preset', 'ultrafast', '-tune', 'zerolatency', '-an'], macro_block_size=16, )
iterations = 1000
xmin = fractions.fraction(numerator=-2, denominator=1)
xmax = fractions.fraction(numerator=1, denominator=1)
ymin = fractions.fraction(numerator=-6, denominator=5)
ymax = fractions.fraction(numerator=6, denominator=5)
zoom_const = fractions.fraction(numerator=19, denominator=20)
b=time.perf_counter()
plt.imshow(fractional_mandelbrot.main((xmin), (xmax), (ymin), (ymax), 320, 240, 1000, False, 2))
print(time.perf_counter()-b)
plt.show()
def thread(yt, yb, lx, rx, i):
    # x = np.array(mandelbrot.main(yt, yb, lx, rx, 480, 480, 250+i, False), dtype=np.uint32)
    # max = np.max(x)
    # if max > 255:
        # max = 255
    # return np.invert(np.rot90(((x*(max/(250+i))).astype(np.uint8))))
    print(i, end='\r')
    if i < 500:  # 17.5 seconds in
        return np.rot90(mandelbrot.main(as_double(yt), as_double(yb), as_double(lx), as_double(rx), 320, 240, 150+round(i*2), False))
    else:
        return np.rot90(fractional_mandelbrot.main(yt, yb, lx, rx, 320, 240, 150+round(i*2), False, 1))

async def main():
    global xmin, xmax, ymin, ymax, real, imag
    data = []
    fig, ax = plt.subplots()

    
    for i in range(iterations):
        xmin = fractions.simplify_fraction(xmin)
        ymin = fractions.simplify_fraction(ymin)
        ymax = fractions.simplify_fraction(ymax)
        xmax = fractions.simplify_fraction(xmax)
        # print(ymin, ymax, xmin, xmax, end='\r')
        # time.sleep(0.01)
        data += [asyncio.to_thread(thread, xmin, xmax, ymin, ymax, int(i))]
        ymin = fractions.add_fractions(fractions.mult_fractions(fractions.sub_fractions(ymin, imag), zoom_const), imag)
        ymax = fractions.add_fractions(fractions.mult_fractions(fractions.sub_fractions(ymax, imag), zoom_const), imag)
        xmin = fractions.add_fractions(fractions.mult_fractions(fractions.sub_fractions(xmin, real), zoom_const), real)
        xmax = fractions.add_fractions(fractions.mult_fractions(fractions.sub_fractions(xmax, real), zoom_const), real)
        

        

    data = np.array(await asyncio.gather(*data, return_exceptions=True, ), dtype=np.uint32)
    print("\nWriting...\n")
    def update(n):
        ax.cla()
        ax.imshow(data[n], cmap='binary')
        # print(n,end='\r')
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
    # for i in (data):
        # w.append_data(i)
    print('\nDone Writing\n')
    # w.close()
asyncio.run(main())
# data = pickle.load(open('data.pk', 'rb'))
# pickle.dump(data, open('data.pk', 'wb'))
# plt.imshow(data)
# plt.show()