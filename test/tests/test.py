print('Importing...')
import time
import numpy as np
import matplotlib.pyplot as plt
import os
import threading, queue
import asyncio

import imageio as iio
import imageio
import numpy as np

# All images must be of the same size
# w = iio.get_writer('my_video.mp4', format='FFMPEG', mode='I', fps=30, output_params=['-preset', 'ultrafast', '-tune', 'zerolatency', '-an'], macro_block_size=100)
# for i in range(30*10):
#     w.append_data(((np.random.random_integers(0, 100, (1000,1000)))).astype(np.uint8))
# w.close()
# exit()
# print(zaxpy(a=8j,x=8j,y=8j), (8j**2)+8j)
# exit()
print('Done importing!')
if not os.path.isdir('./tests/'):
    os.mkdir('./tests/')

# q: list|queue.Queue = queue.Queue()

def chunk(i, HL, WL, chunks):
    # x = np.linspace(x_min, x_max, WL//n_chunks)
    # y = np.linspace(y_min, y_max, )
    # X, Y = np.meshgrid(
    #         x[i*chunk_size:(i+1)*chunk_size],
    #         y[y_min:y_max]
    # )
    Y,X = np.ogrid[ -1.3:0:HL*1j, i:(i+chunks):WL*1j]
    return X + 1j*Y

# def mandelbrot_chunk(data, maxit, divtime):
def mandelbrot_chunk(i, maxit, divtime, HL, WL, chunks):
    """Returns an image of the Mandelbrot fractal of size (h,w)."""
    data = chunk(i, HL, WL, chunks)
    z = data
    for i in range(maxit):
        # z = zaxpy(a=z, x=z, y=data)
        z = z*z
        # z = zaxpy(a=z, x=z, y=c)
        # z = ne.evaluate('(z*z)+c')
        z += data
        diverge = (np.abs(z)) > 2
        # diverge = zaxpy(a=np.real(z), x=z, y=f) > 2      # who is diverging
        # div_now = ((z.real*z) > 2) & (divtime==maxit)  # who is diverging now
        divtime[(diverge) & (divtime==maxit)] = i                 # note when
        z[diverge] = 3                        # avoid diverging too much
        # plt.imshow(divtime)
        # plt.show()
    # print('\nFinished computing!')
    # print(time.perf_counter()-b)
    del diverge
    # del div_now
    del z
    # divtime = np.rot90(divtime, 0, (1,0))
    # return divtime
    # return np.append(divtime,np.flipud(divtime)).reshape(HL*2, WL)
    # q.put_nowait((i, divtime))
    return divtime
plt.switch_backend('TkAgg')

async def mandelbrot(height:int, width:int, n_chunks: int=10, iterations:int=100):
    # global q

    # Size per dimension
    # HL = round(((-y_min)*height))
    b = time.perf_counter()
    HL = height//2
    WL = width//n_chunks
    # WL = round(abs((x_min-x_max)*width))
    chunks = (n_chunks)/n_chunks**2

    divtime = iterations + np.zeros((HL, WL), dtype=np.uint8)
    coros = []
    
    for i in np.linspace(-2, 0.5, n_chunks, dtype=np.float16):
        # mandelbrot_chunk(i, iterations, divtime.copy(), HL, WL, chunks)
        # t = threading.Thread(target=mandelbrot_chunk, args=(i, iterations, divtime.copy(), HL, WL, chunks), daemon=True, )
        # t.start()
        coros += [asyncio.to_thread(mandelbrot_chunk, i, iterations, divtime.copy(), HL, WL, chunks)]
        # if round(i)==-2:
        #     # plot = mandelbrot_chunk(chunk(i, HL, WL, n_chunks), iterations, divtime.copy())
        #     plot = mandelbrot_chunk(i, iterations, divtime.copy(), HL, WL, chunks)
        # else:
        #     plot = np.append(plot, (mandelbrot_chunk(i, iterations, divtime.copy(), HL, WL, chunks)), axis=1)
        # do stuff with chunk(i, j)
        # print(i, plot.shape)
    # f = False
    # while not f:
        # f = q.qsize()==n_chunks
    # queue = [q.get_nowait() for i in range(n_chunks)]
    # return np.hstack([i[1] for i in sorted(queue, key=lambda x:x[0])])
    plot = np.hstack(await asyncio.gather(*coros, return_exceptions=False))
    print(time.perf_counter()-b)
    print('rendering...')
    plt.imsave('output.png', plot)
    # return np.append(plot,np.flipud(plot), axis=0)

asyncio.run(mandelbrot(10000, 10000, 1000))
