PLOT = true
include("utils.jl")

# Constants and setup
LEVEL = 2
GRID_CONSTANT = 1
FIG_DIR = "media/"

# Used in grid
BORDER = 0
OUTSIDE = -1

@verbose("Create fractal and grid")
grid, number_inside, fractal = get_populated_grid(
    level=LEVEL,
    grid_constant=GRID_CONSTANT,
    return_fractal=true)
# Find inner points and create the eigenmatrix
@verbose("Generate eigenmatrix")
inner_list, mat = create_eigenmatrix(grid, number_inside)

plt.title(@sprintf "Fracal level %i" LEVEL)
plt.pcolormesh(mat, cmap="OrRd")
plt.gca().set_aspect("equal")
plt.savefig(string(FIG_DIR, "eigenmatrix_level_", LEVEL, ".png"), dpi=300)
