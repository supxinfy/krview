# krview

Kravchuk (or Krawtchouk if you prefer French spelling) matrix viewer visualizes Kravchuk matrices modulo prime numbers. Note that Kravchuk matrices are sometimes called MacWilliams matrices [[1](#references)], [[3](#references)].

This project is inspired by quite old Wolfram Mathematica notebook [[3](#references)]. As a reference one can use [[1](#references)] or [[2](#references)].

## Example

Here is an example of the Kravchuk matrix viewer in action:

![Kravchuk Matrix Viewer](assets/pictures/krview.png)

## Features

- Visualize Kravchuk matrices modulo prime numbers
- Support for various prime numbers
- Interactive user interface
- Several color schemes to view the data

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

- `Q` exits the application
- `C` changes color scheme
- `W` and `S` or `UP` and `DOWN` change the order
- `A` and `D` or `LEFT` and `RIGHT` change the modulo
- `SHIFT` increases speed of change
- `H` or `SPACE` toggles helping screen

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
brew install sdl2 sdl_ttf
```

- Install Zig:
```sh
brew install zig
```
#### Linux

Install dependencies using your package manager. For example, on Ubuntu:
```sh
sudo apt-get install libsdl2-dev libsdl2-ttf-dev zig
```

*Note: Zig 0.13.0 used in this project*. Sometime I'll add version control, maybe...

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