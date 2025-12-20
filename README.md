# krview

Kravchuk (or Krawtchouk if you prefer spelling from the original paper [[4](#references)]) matrix viewer visualizes Kravchuk matrices modulo prime numbers. Note that Kravchuk matrices are sometimes called MacWilliams matrices [[1](#references)], [[3](#references)].

These matrices emerge in the field of coding theory and are used in numerous applications, however, it is not known how they behave modulo a prime number. Thus visualization is created to present this finite-automata-like phenomenon. Binomial coefficients are closely related to these matrices (in fact, they are included in them) and similar phenomenon for them is described by well-known theorem in Number Theory, namely, [Lucas's theorem](https://en.wikipedia.org/wiki/Lucas%27s_theorem). Similar patterns appear in cellular automata, Pascal’s triangle modulo primes, and other discrete dynamical systems.

*In short:* this application lets you explore surprising self-similar and automaton-like patterns that appear in Kravchuk matrices when computed modulo primes.

This project is inspired by a quite old Wolfram Mathematica notebook [[3](#references)]. As a reference of the theory one can use [[1](#references)] or [[2](#references)].

## Example

Here is an example of the Kravchuk matrix viewer in action:

![Kravchuk Matrix Viewer](assets/pictures/krview.png)

## Features

- Visualize Kravchuk matrices modulo prime numbers
- Support for various prime numbers
- Interactive user interface
- Several color schemes to view the data
- Export images of matrices

### Examples of Color Schemes

- Gogin's scheme

![Gogin's color scheme](assets/pictures/gogin.png)

- Gray-scale scheme

![Gray-scale color scheme](assets/pictures/gray.png)

- logarithmic scheme

![Logarithmic color scheme](assets/pictures/log.png)

- linear hue scheme

![Linear Hue color scheme](assets/pictures/hue.png)

- viridis

![Viridis color scheme](assets/pictures/viridis.png)

- magma

![Magma color scheme](assets/pictures/magma.png)

- plasma

![Plasma color scheme](assets/pictures/plasma.png)

### Keybinds

| Key | Action |
|----|-------|
| Q | Quit |
| C | Change color scheme |
| W/S | Change order |
| A/D | Change modulo |
| E | Export image |

Or more detailed:

- `Q` exits the application
- `C` changes color scheme
- `W` and `S` or `UP` and `DOWN` change the order
- `A` and `D` or `LEFT` and `RIGHT` change the modulo
- `SHIFT` increases speed of change
- `H` or `SPACE` toggles helping screen
- `E` exports the current matrix view as a .jpg image and saves it into assets/screenshots

Note that the size of the image depends on size of the window.

## Installation

To install `krview`, clone the repository and build the project:

```sh
git clone https://github.com/supxinfy/krview.git
cd krview
zig build
```

### Dependencies

#### macOS

Install dependencies using Homebrew:

- Install SDL:

```sh
brew install sdl2 sdl_ttf sdl2_image
```

- Install Zig:
```sh
brew install zig
```
#### Linux

Install dependencies using your package manager. For example, on Ubuntu:
```sh
sudo apt-get install libsdl2-dev libsdl2-ttf-dev libsdl2-image-dev zig
```

This project is actively maintained and tested on Zig 0.15+. See releases for tagged versions.

## Usage

Run the application with:

```sh
zig build run
```
or
```sh
zig build
./zig-out/bin/krview
```

Follow the on-screen instructions to visualize Kravchuk matrices.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Third-party assets

This project bundles [Terminus Font](https://files.ax86.net/terminus-ttf/) version 4.49.3.

Terminus Font is licensed under the [SIL Open Font License](https://openfontlicense.org), Version 1.1. You can find license at `assets/fonts/OFL.txt`.

## References

1. Nikita Gogin and Mika Hirvensalo. Recurrent Construction of MacWilliams and Chebyshev Matrices, TUCS Technical Report, No. 812, February 2007.

2. Philip Feinsilver and Jerzy Kocik. Krawtchouk polynomials and Krawtchouk matrices, Recent Advances in Applied Probability, Springer-Verlag, 2004.

3. N. Gogin, MacWilliams matrix, Mathematica notebook, MathSource, Wolfram Research, 2004. Available at the Wolfram Library Archive: https://library.wolfram.com/infocenter/MathSource/5223/

4. Mykhailo Kravchuk. Sur une généralisation des polynomes d'Hermite, Comptes Rendus Mathématique (in French), 189: 620–622, JFM [55.0799.01](https://zbmath.org/?format=complete&q=an:55.0799.01), 1929.