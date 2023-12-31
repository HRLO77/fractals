# fractals

This repository provides tools for plotting, calculating, and zooming in on the [mandelbrot set](https://en.wikipedia.org/wiki/Mandelbrot_set).

The mandelbrot set is set of points between -2, 0.5 and -1.5i and 1.5i ([i](https://en.wikipedia.org/wiki/Imaginary_number) is the imaginary unit).

Any number (z) on the complex plane, which converges to a cycle when squared and added to its original point is part of the mandelbrot set

This can be represented as the equation: z^2+c

The problem with computing the set to high accuracy however, is the computing limitations and memory usage, which increase significantly for greater quality renderings.

## requirements

Install requirements from  the `requirements.txt` file by running the command `python -m pip install -r requirements.txt`

## building

Binaries for Windows and Linux platforms can be found in `./binaries`, simply drag to the proper locations and run the scripts.

You can build the binaries yourself by running `python cyth.py build_ext --inplace` and change the compiler arguments accordingly.

## rendering

`./image.py` creates a still 5000x5000 pixel image of the mandelbrot set.

`./video.py` zooms in to a point on the mandelbrot set.

Adjust files to your wishes and adjust parameters to change zoom location, resolution, iterations and more!

`./src/mandelbrot.pyx` produces an image of a mandelbrot set, its signature is 

`cpdef public list main(const long double xmin, const long double xmax, const long double ymin, const long double ymax, const unsigned int width, const unsigned int height, const ui_uc maxiter, const bool cap) noexcept:
`

xmin, xmax, ymin & ymax are the boundries of the image based on coordinates in the complex plane.

Width and height are the resolution, samples along the real and imaginary axis.

maxiter is the maximum number of iterations to perform on each point before dropping out, and cap is whether or not you are rendering a video with the produced frame (naively scales all values frm 0 to 255)

## fractions

This repository has its own fractions implementation `./fractions.pxd`. It is NOT a drop-in replacement to the standard `fractions` module. It is significantly faster and unlike quicktions, can be used directly through cimports in cython for maximum speed. `src/fractional_mandelbrot.pyx` is still being implemented to use this file for very precise calculations.

## conclusion

To see some previously made image renders or video zoom, see `./renders`.


Thanks for checking out this repository!
