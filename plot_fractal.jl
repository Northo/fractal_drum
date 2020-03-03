PLOT = true
include("utils.jl")

# Constants and setup
LEVEL = 2
GRID_CONSTANT = 1
FIG_DIR = "modes/"
NUM_MODES = 10

# Used in grid
BORDER = 0
OUTSIDE = -1

fractal = get_fractal(level=LEVEL, grid_constant=GRID_CONSTANT)
x, y = get_component_lists(fractal)

plt.title(@sprintf "Fracal level %i" LEVEL)
plt.plot(x, y)
plt.gca().set_aspect("equal")
plt.savefig(@sprintf "media/fractal_l%i.pdf" LEVEL)
