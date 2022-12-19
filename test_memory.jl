PLOT = false
include("utils.jl")
using Printf
using DelimitedFiles

# ----------------------------------------------------------- #
#                     Constants and setup                     #
# ----------------------------------------------------------- #
LEVEL = 5
GRID_CONSTANT = 1
STENCIL = :five

# End of setup - you shouldn't need to change anything below this linie

info = Dict([
    ("LEVEL", LEVEL),
    ("GRID CONSTANT", GRID_CONSTANT),
    ("STENCIL", STENCIL),
])
print(format_info(info))

if STENCIL==:five
    eigenmatrix_method = create_eigenmatrix
elseif STENCIL==:nine
    eigenmatrix_method = create_eigenmatrix_high_order
else
    throw(ArgumentError("stencil must be :nine or :five, got $(repr(STENCIL))"))
end

println(" .Creating fractal and grid")
grid, number_inside = get_populated_grid(level=LEVEL, grid_constant=GRID_CONSTANT)

println(" .Creating eigenmatrix")
inner_list, eigenmatrix = eigenmatrix_method(grid, number_inside)

size_info = Dict([
    ("Eigenmatrix dimensions", size(eigenmatrix)),
    ("Eigenmatrix sizeof", sizeof(eigenmatrix)),
    ("Eigenmatrix summarysize", Base.summarysize(eigenmatrix)),
])

print(format_info(size_info))
