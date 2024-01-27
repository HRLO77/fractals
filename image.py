import src.mandelbrot_decimal as mandelbrot
import matplotlib.pyplot as plt
import numpy as np
from PIL import Image
import decimal
decimal.getcontext().prec = 73

data = np.rot90(mandelbrot.run(decimal.Decimal(-2),decimal.Decimal(0.5), decimal.Decimal(-1.3), decimal.Decimal(1.3), 320, 240, 100))
Image.MAX_IMAGE_PIXELS = None
# i = Image.open(r'C:\Users\owner\Desktop\renders\150k.png')
plt.imshow(data, cmap='flag')

plt.show()