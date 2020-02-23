PLOT = false
include("utils.jl")
# Used in grid
BORDER = 0
OUTSIDE = -1

## Test
# Constants and setup
GRID_CONSTANT = 2

for level in [2,3,4]
    println("Level ", level)
    @verbose("Generating grid")
    grid, number_inside, fractal = get_populated_grid(
        level=level,
        grid_constant=GRID_CONSTANT,
        return_fractal=true)

    # Find inner points and create the eigenmatrix
    @verbose("Generate eigenmatrix")
    inner_list, mat = create_eigenmatrix_high_order(grid, number_inside)

    @verbose("Solve eigenproblem")
    values, vectors = solve_eigenproblem(mat)

    @printf "Values calculated for level %i with grid constant %i\n" level GRID_CONSTANT
    println("Mode#&\t omega/v\t")
    for (i, value) in enumerate(values)
        @printf "%i&\t%.8E\n" i value
    end
    println("----")
    println("omega/v\t deltaN")
    for (i, value) in enumerate(values)
        interesting = i-(1/(4*pi))*value
        @printf "%f\t%6.8f\n" sqrt(value) interesting
    end
    println("-----------")
end
