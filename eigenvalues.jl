PLOT = false
include("utils.jl")
using Printf
using DelimitedFiles

# ----------------------------------------------------------- #
#                     Constants and setup                     #
# ----------------------------------------------------------- #
LEVEL = 5
GRID_CONSTANT = 2
NUMBER_OF_MODES = 10
DATA_DIR = "datafiles/eigenvalues/"
STENCIL = :nine

# End of setup - you shouldn't need to change anything below this linie

filename = @sprintf "level_%i_grid_%i_stencil_%s_modes_%i.txt" LEVEL GRID_CONSTANT STENCIL NUMBER_OF_MODES
filename = string(DATA_DIR, filename)
println(filename)

info = Dict([
    ("LEVEL", LEVEL),
    ("GRID CONSTANT", GRID_CONSTANT),
    ("NUMBER OF MODES", NUMBER_OF_MODES),
    ("DATA DIR", DATA_DIR),
    ("STENCIL", STENCIL),
])
print(format_info(info))

values, _ = solve_eigenproblem(
    level=LEVEL,
    grid_constant=GRID_CONSTANT,
    number_of_modes=NUMBER_OF_MODES,
    stencil=STENCIL,
    find_vectors=false
)

# Write to file
println(" .Writing to file")
mkpath(DATA_DIR)
open(filename, "w") do file
    writedlm(file, values)
end
println("Wrote eigenvalues to ", filename)
