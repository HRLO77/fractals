import src.fractional_mandelbrot as mandelbrot
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from src import fractions
import numpy as np
import imageio
import asyncio
import warnings
warnings.filterwarnings('ignore')
np.seterr(all="ignore", )
# real, imag = -0.76157365, -0.0847596
real, imag = fractions.fraction(numerator=313230647, denominator=1250000000), fractions.fraction(numerator=56907, denominator=2500000000)
# 0.2505845176040427718957771316508473905552515740661571423212687174479167
# 0.00002276281458802574942404639696751451557095909568791588147481282552083
# other possible zooms,  (-1.62917,-0.0203968)  (0.42884,-0.231345)
# data = np.rot90(new_video.main(-2, 0.5, -1.3, 0, 500, 250, 100))
# w = imageio.get_writer('mandelbrot.mp4', format='FFMPEG', mode='I', fps=30, output_params=['-preset', 'ultrafast', '-tune', 'zerolatency', '-an'], macro_block_size=16, )
iterations = 500
xmin = fractions.fraction(numerator=-2, denominator=1)
xmax = fractions.fraction(numerator=1, denominator=1)
ymin = fractions.fraction(numerator=-14, denominator=10)
ymax = fractions.fraction(numerator=-14, denominator=10)
zoom_const = fractions.fraction(numerator=94, denominator=100)

def thread(yt, yb, lx, rx, i):
    global f, seven
    # x = np.array(mandelbrot.main(yt, yb, lx, rx, 480, 480, 250+i, False), dtype=np.uint32)
    # max = np.max(x)
    # if max > 255:
        # max = 255
    # return np.invert(np.rot90(((x*(max/(250+i))).astype(np.uint8))))
    return np.rot90(mandelbrot.main(yt, yb, lx, rx, 480, 480, 300+round(i*2), True))

async def main():
    global xmin, xmax, ymin, ymax, real, imag
    data = []
    fig, ax = plt.subplots()
    for i in range(iterations):
        data += [asyncio.to_thread(thread, xmin, xmax, ymin, ymax, int(i))]
        ymin = fractions.add_fractions(fractions.mult_fractions(fractions.sub_fractions(ymin, imag), zoom_const), imag)
        ymax = fractions.add_fractions(fractions.mult_fractions(fractions.sub_fractions(ymax, imag), zoom_const), imag)
        xmin = fractions.add_fractions(fractions.mult_fractions(fractions.sub_fractions(xmin, real), zoom_const), real)
        xmax = fractions.add_fractions(fractions.mult_fractions(fractions.sub_fractions(xmax, real), zoom_const), real)
        print(i, end='\r')
        
        # print(yt, yb, lx, rx)
        # time.sleep(1)

    data = np.array(await asyncio.gather(*data, return_exceptions=True, ), dtype=np.uint32)
    print(len(data))
    print("\nWriting...\n")
    def update(n):
        ax.cla()
        ax.imshow(data[n], cmap='binary')
        print(n,end='\r')
    ani = animation.FuncAnimation(fig=fig, func=update, interval=1000/30, frames=range(iterations))
    ani.save('mandelbrot.mp4')
    # for i in (data):
        # w.append_data(i)
    print('\nDone Writing\n')
    # w.close()
    print("")
asyncio.run(main())
# data = pickle.load(open('data.pk', 'rb'))
# pickle.dump(data, open('data.pk', 'wb'))
# plt.imshow(data)
# plt.show()
