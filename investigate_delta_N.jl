using CurveFit
PLOT = true

include("utils.jl")

# Used in grid
BORDER = 0
OUTSIDE = -1

## Test
# Constants and setup
GRID_CONSTANT = 2

NUM_MODES = 40

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
    delta_N = Array{Float64}(undef, NUM_MODES)
    println("Number inside: ", number_inside)
    for (i, value) in enumerate(values)
        delta_N[i] = number_inside*value/(4*pi) - i + 1
        @printf "%f\t%6.8f\n" sqrt(value) delta_N[i]
    end
    println("-----------")

    ################
    ## Regression ##
    ################
    fit = curve_fit(PowerFit, sqrt.(values), delta_N)
    d = fit.coefs[2]  # Slope
    @printf "Estimate for d: %.3f\n" d

    ##########
    ## Plot ##
    ##########
    plt.title(@sprintf("Calculated at level %i with grid constant %i", level, GRID_CONSTANT))
    plt.scatter(sqrt.(values), delta_N, label="\$\\Delta N(\\omega)\$")
    plt.plot(sqrt.(values), fit.(sqrt.(values)), label=(@sprintf "Curve fit, d = %.3f" d))
    plt.legend()
    plt.show()
end
