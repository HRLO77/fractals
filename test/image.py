import src.mandelbrot as mandelbrot
import matplotlib.pyplot as plt
import numpy as np
from PIL import Image
data = np.rot90(mandelbrot.main(-2, 0.5, -1.3, 1.3, 5000, 5000, 500, False))
Image.MAX_IMAGE_PIXELS = None
# i = Image.open(r'C:\Users\owner\Desktop\renders\150k.png')
plt.imshow(data, cmap='flag')

plt.show()