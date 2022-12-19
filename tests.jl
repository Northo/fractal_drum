PLOT = false
include("utils.jl")

grid_constant=1

for level in [1, 2, 3, 4, 5]
    grid, number_inside = get_populated_grid(level=level, grid_constant=grid_constant)
    println(level, ": ", size(grid))
end
