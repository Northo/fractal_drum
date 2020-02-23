PLOT = false
include("utils.jl")

# Constants and setup
LEVEL = 6
GRID_CONSTANT = 2

# Used in grid
BORDER = 0
OUTSIDE = -1

## Test
@verbose("Create fractal and grid")
grid, number_inside, fractal = get_populated_grid(
    level=LEVEL,
    grid_constant=GRID_CONSTANT,
    return_fractal=true)
# Find inner points and create the eigenmatrix
@verbose("Generate eigenmatrix")
inner_list, mat = create_eigenmatrix_high_order(grid, number_inside)
println(sizeof(mat))
println(Base.summarysize(mat))
@verbose(mat)
#values, vectors = solve_eigenproblem(mat)
