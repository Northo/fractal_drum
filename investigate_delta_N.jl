using CurveFit
using DelimitedFiles
PLOT = true
SAVEDATA = true

include("utils.jl")

# Used in grid
BORDER = 0
OUTSIDE = -1

## Test
# Constants and setup
GRID_CONSTANT = 2

NUM_MODES = 1000

DATADIR = "datafiles/delta_N/"

for level in [4]
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
    values = solve_eigenproblem(mat, find_vectors=false)
    values_root = sqrt.(values)

    @printf "Values calculated for level %i with grid constant %i\n" level GRID_CONSTANT
    println("Mode#&\t omega/v\t")
    for (i, value) in enumerate(values)
        @printf "%i&\t%.8E\n" i value
    end
    println("----")
    println("omega/v\t deltaN")
    delta_N = Array{Float64}(undef, NUM_MODES)
    for (i, value) in enumerate(values)
        delta_N[i] = number_inside*value/(4*pi) - i + 1
        @printf "%f\t%6.8f\n" values_root[i] delta_N[i]
    end
    println("-----------")

    ################
    ## Regression ##
    ################
    fit = curve_fit(PowerFit, values_root, delta_N)
    d = fit.coefs[2]  # Slope
    @printf "Estimate for d: %.3f\n" d

    ###########################
    ## Write results to file ##
    ###########################
    if SAVEDATA
        filename = @sprintf("delta_N_values_level_%i_grid_constant_%i_num_modes_%i.txt",
                            level,
                            GRID_CONSTANT,
                            NUM_MODES)
        full_filename = string(DATADIR, filename)
        println("Writing results to ", full_filename)
        open(full_filename, "w") do file; write(file, ""); end  # Empty file
        open(full_filename, "a") do file
            write(file, "# Estimated value of d : ", d, "\n# ------\n")
            # Write eigenmodes
            write(file, "# Mode#\t omega/v\n")
            for (i, value) in enumerate(values_root)
                write(file, @sprintf("%i&\t%.8E\n", i, value))
            end
            write(file, "# ----\n")
            write(file, "# omega/v\t deltaN\n")
            for (i, value) in enumerate(values_root)
                write(file, @sprintf("%f\t%6.8f\n", value, delta_N[i]))
            end
        end  # open file
    end  # if SAVEDATA

    ##########
    ## Plot ##
    ##########
    plt.title(@sprintf("Calculated at level %i with grid constant %i", level, GRID_CONSTANT))
    plt.scatter(sqrt.(values), delta_N, label="\$\\Delta N(\\omega)\$")
    plt.plot(sqrt.(values), fit.(sqrt.(values)), label=(@sprintf "Curve fit, d = %.3f" d))
    plt.legend()
    plt.show()
end
