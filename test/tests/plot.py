from matplotlib import pyplot as plt
import numpy as np
arr = plt.imread('./renders/20k.png').astype(np.uint8)

plt.imshow(arr)
plt.show()
