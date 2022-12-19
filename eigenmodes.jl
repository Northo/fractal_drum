PLOT = false
include("utils.jl")
using Printf
using DelimitedFiles

# ----------------------------------------------------------- #
#                     Constants and setup                     #
# ----------------------------------------------------------- #
LEVEL = 4
GRID_CONSTANT = 2
NUMBER_OF_MODES = 10
DATA_DIR = "datafiles/eigenmodes/"
STENCIL = :five

# End of setup - you shouldn't need to change anything below this linie

info = Dict([
    ("LEVEL", LEVEL),
    ("GRID CONSTANT", GRID_CONSTANT),
    ("NUMBER OF MODES", NUMBER_OF_MODES),
    ("DATA DIR", DATA_DIR),
    ("STENCIL", STENCIL),
])
print(format_info(info))

values, vectors, fractal, inner_list = solve_eigenproblem(
    level=LEVEL,
    grid_constant=GRID_CONSTANT,
    number_of_modes=NUMBER_OF_MODES,
    stencil=STENCIL,
    return_inner_list=true
)

fractal_x, fractal_y = get_component_lists(fractal)
# Write to file
# In DATA_DIR, create a new folder containing three files, the modes, the eigenvalues, and the inner list
println(" .Writing to file")

dirname = @sprintf "level_%i_grid_%i_stencil_%s_modes_%i/" LEVEL GRID_CONSTANT STENCIL NUMBER_OF_MODES
dirname = string(DATA_DIR, dirname)
mkpath(dirname)


for (filename, data) in [
    ("inner_list", [index.I for index in inner_list]),  # We want to have tuples, not CartesianIndex
    ("eigenvalues", values),
    ("eigenmodes", vectors),
    ("fractal", [fractal_x fractal_y])
]
    open(string(dirname, filename, ".txt"), "w") do file
        writedlm(file, data)
    end
    println(" .Wrote ", filename, ".txt")
end
