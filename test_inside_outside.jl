PLOT = false
include("utils.jl")

# Constants and setup
LEVEL = 4
GRID_CONSTANT = 2
FIG_DIR = "modes/"
NUM_MODES = 10

# Used in grid
BORDER = 0
OUTSIDE = -1

## Test
fractal = get_fractal(level=LEVEL, grid_constant=GRID_CONSTANT)
grid = generate_grid(fractal)

grid_middle_out = copy(grid)
grid_scan = copy(grid)

@time number_inside_scan = populate_grid!(grid_scan)
@time number_inside_middle_out = populate_grid_middle_out!(grid_middle_out)
