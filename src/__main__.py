import video_src.new_video as new_video
import matplotlib.pyplot as plt
import numpy as np
import imageio
import asyncio
import warnings
warnings.filterwarnings('ignore')
np.seterr(all="ignore", )
real, imag = -0.761574, -0.0847596
# other possible zooms -  (-1.62917,-0.0203968)  (0.42884,-0.231345) 
# data = np.rot90(new_video.main(-2, 0.5, -1.3, 0, 500, 250, 100))
w = imageio.get_writer('mandelbrot.mp4', format='FFMPEG', mode='I', fps=30, output_params=['-preset', 'ultrafast', '-tune', 'zerolatency', '-an'], macro_block_size=16)
iterations = 400
xmin = -2
xmax = 0.5
ymin = -1.3
ymax = 1.3
zoom_const = 0.999
def thread(yt, yb, lx, rx, i):
    return np.rot90(np.array((new_video.main(yt, yb, lx, rx, 640, 640, 200+i*2)), dtype=np.uint8))

async def main():
    global xmin, xmax, ymin, ymax, real, imag
    data = []

    for i in range(iterations):
        data += [asyncio.to_thread(thread, xmin, xmax, ymin, ymax, int(i))]
        ymin = (ymin - imag) * zoom_const + imag
        ymax = (ymax - imag) * zoom_const + imag
        xmin = (xmin - real) * zoom_const + real
        xmax = (xmax - real) * zoom_const + real
        print(i, end='\r')
        
        # print(yt, yb, lx, rx)
        # time.sleep(1)
    c = 0
    for i in (await asyncio.gather(*data, return_exceptions=False)):
        w.append_data(i)
        print(c, end='\r')
        c+=1 
    w.close()
asyncio.run(main())
