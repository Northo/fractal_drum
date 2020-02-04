using LinearAlgebra
PLOT = true
VERBOSE = true
if PLOT
    println("Loading PyPlot")
    using PyPlot
    println("PyPlot loaded!")
end

# Constants and setup
LEVEL = 2
GRID_CONSTANT = 4
FIG_DIR = "modes/"
MODES_TO_PLOT = [1, 2, 3, 10, 11, 15, 16]

macro verbose(msg...)
    if VERBOSE
        println(msg...)
    end
end

# Role, describes the role of a point in a grid
@enum Role inside outside border

struct Point
    x::Int
    y::Int
#    role::Role

#    Point(x,y) = new(x,y,outside::Role)
#    Point(x,y,role) = new(x,y,role)
end

function Base.:+(x::Point, y::Point)
    return Point(x.x+y.x, x.y+y.y)
end

function Base.:-(x::Point, y::Point)
    return Point(x.x-y.x, x.y-y.y)
end

function Base.:*(p::Point, n::Int)
    return Point(p.x*n, p.y*n)
end

function generate_square_wave(start::Point, stop::Point)
    """Genereates a square wave on a line segment,
    geiven by start and stop."""
    # Line segment should be either vertical or horizontal
    @assert start.x==stop.x || start.y==stop.y "Segment must be either vertical or horizontal"

    points = Array{Point}(undef, 9)
    points[1] = start
    points[end] = stop

    direction = stop - start
    L = direction.x + direction.y  # We know that either x or y is zero
    @assert mod(L, 4)==0 "Segment not divisable by 4!"
    forward = Point(direction.x/4, direction.y/4)  # The segment we add
    left = Point(-forward.y, forward.x)

    points[2] = start + forward
    points[3] = points[2] + left
    points[4] = points[3] + forward
    points[5] = points[4] - left
    points[6] = points[5] - left
    points[7] = points[6] + forward
    points[8] = points[7] + left
    return points
end

function create_fractal(points::Array{Point}, l::Int)
    out_points = []
    for i::Int in 2:length(points)
        generated = generate_square_wave(points[i-1], points[i])
        if l==1
            append!(out_points, generated)
        else
            append!(out_points, create_fractal(generated, l-1))
        end
    end
    return out_points
end

function generate_grid(points::Array{Point,1})
    # Find borders for fractal
    # TODO: This could probably be improved by built-in functions
    max_x = min_x = points[1].x
    max_y = min_y = points[1].y
    for (i, point) in enumerate(points)
        if point.x > max_x
            max_x = point.x
        elseif point.x < min_x
            min_x = point.x
        end
        if point.y > max_y
            max_y = point.y
        elseif point.y < min_y
            min_y = point.y
        end
    end

    # Initialize grid
    L = max(max_x-min_x, max_y-min_y) + 1
    grid = Array{Role, 2}(undef, L, L)
    for i in eachindex(grid)
        grid[i] = outside::Role
    end

    # Set border
    for point in points
        grid[point.x-min_x+1, point.y-min_y+1] = border::Role
    end

    return grid
end

function create_square_fractal(l::Int)::Array{Point,1}
    recursion_level = l
    L = 4^recursion_level

    x1 = Point(0,0)
    x2 = x1 + Point(L,0)
    x3 = x2 + Point(0,L)
    x4 = x3 + Point(-L,0)
    x5 = x4 + Point(0, -L)

    square = [x1,x2,x3,x4,x5]
    points = create_fractal(square, recursion_level)
    return points
end

function split_segments(points, split_into)
    """Splits an array of points, that make up
    line segments. Each segment is split into
    split_into number of segments, ie. if split_into=2
    two points, one segment, will be turned
    into three points, two segments.

    It is also assumed that the shortest
    line segment has length one, so that,
    in order to keep integer coordinates, all coordinates
    has to be shiftet up, so that the new shortes segment
    also has length one.
    """
    L = length(points)
    new_points = Array{Point,1}(undef, (L-1)*split_into + 1)

    for i in 1:L-1, j in 1:split_into
        new_points[(i-1)*split_into + j] = points[i]*split_into + (points[i+1]-points[i])*(j-1)
    end
    new_points[end] = points[end]
    return new_points
end

function get_component_lists(points)
    len = length(points)
    x_list = Array{Int}(undef, len)
    y_list = Array{Int}(undef, len)

    for i in eachindex(points)
        x_list[i] = points[i].x
        y_list[i] = points[i].y
    end

    return x_list, y_list
end

# Finding inside and outside of structure ###################
## First method of checking,
## scanning out for each cell. Does not work,
## needs directional info.
function check_grid_point(grid, x, y)
    """Checks a point in grid. Does not
    check if allready inside"""
    if grid[x,y]==border
        return border
    end

    if grid[x-1,y]==inside
        return inside
    end

    # Count number of times we cross border
    border_crossings = 0
    # Scan left
    for i in 1:x-2
        cell = grid[x-i, y]
        # If we hit the border, and the cell above or below is border, we know that we cross the border
        if cell==border && (grid[x-i, y+1]==border || grid[x-i, y-1]==border) && grid[x-i-1, y]!=border
            border_crossings+=1
        end
    end

    return mod(border_crossings,2)==0 ? outside : inside
end

function populate_grid!(grid::Array{Role,2})
    """Takes a grid with an enclosed border,
    and makes internal points inside::Role.
    Assumes points not on border are ouside::Role"""

    height, width = size(grid)
    for x = 2:width-1, y = 2:height-1
        grid[x, y] = check_grid_point(grid, x, y)
    end
end

## Second method for deciding inside
## Scans middle out
function populate_grid_middle_out!(grid::Array{Role,2})
    """Takes a grid with an enclosed border,
    and makes internal points inside::Role."""
    # Find center
    height, width = size(grid)
    mid_x = Integer(floor(height/2))
    mid_y = Integer(floor(width/2))

    recursive_check_point!(grid, mid_x, mid_y)
end
function recursive_check_point!(grid, x, y)
    """Inside out check of grid"""
    if grid[x,y]==border || grid[x,y]==inside
        return
    end
    grid[x,y] = inside
    # Traverse to each of the neighbouring points
    recursive_check_point!(grid, x+1, y)  # Right
    recursive_check_point!(grid, x-1, y)  # Left
    recursive_check_point!(grid, x, y+1)  # Above
    recursive_check_point!(grid, x, y-1)  # Below
end

function get_fractal(;level=2, grid_constant=1)
    fractal = create_square_fractal(level)
    fractal = split_segments(fractal, grid_constant)
    return fractal
end

function get_populated_grid(;level=2, grid_constant=1, return_fractal=false)
    """level: recursion depth
       grid_constant: number of points per smallest length on fractal"""
    fractal = get_fractal(level=level, grid_constant=grid_constant)
    grid = generate_grid(fractal)
    populate_grid_middle_out!(grid)
    if return_fractal
        return grid, fractal
    end
    return grid
end

function plot_grid(grid::Array{T}) where {T<:Real}
    plot_grid = Array{T,2}(undef, size(grid))
    for i in eachindex(plot_grid)
        plot_grid[i] = T(grid[i])
    end

    plt.pcolormesh(plot_grid)
    plt.colorbar()
    plt.show()
end

function plot_curve(fractal)
    x,y = get_component_lists(fractal)
    plt.plot(x,y)
    plt.show()
end

using Printf
function plot_by_print(grid)
    """ASCII plot of grid. Requires Printf."""
    width, height = size(grid)
    println(repeat("-", width*3+2))
    for i in eachindex(grid)
        if mod(i-1, width)==0
            print("|")
        end

        @printf("%3c", ['.', ' ', '#'][1+Integer(grid[i])])
        if mod(i, width)==0
            println("|")
        end
    end
    println(repeat("-", width*3+2))
end

function create_eigenmatrix(grid)
    # An alternative would be to
    # use information about how eachindex
    # works to avoid needing the Point array

    # Notice that the values have opposite
    # sign of what you get from 5-point stencil
    # this is because we want - (nabla)^2

    inner_list = []
    for i in CartesianIndices(grid)
        if grid[i]==inside::Role
            append!(inner_list, [Tuple(i)])
        end
    end

    num_inner = length(inner_list)
    mat = zeros(Int, num_inner, num_inner)
    for i in eachindex(inner_list)
        mat[i,i] = 4
        x,y = inner_list[i]
        for cell in [(x+1,y), (x-1,y), (x,y+1), (x,y-1)]
            if cell in inner_list
                inner_index = findfirst(x->x==cell, inner_list)
                mat[i, inner_index] = -1
            end
        end
    end
    return inner_list, mat
end

function solve_eigenproblem(matrix)
    values, vectors = eigen(matrix)
    sort_index = sortperm(values)
    return values[sort_index], vectors[:, sort_index]
end

function plottable_grid(size, inner_list, vector)
    """
    Parameter:
     size: size of grid to create
     inner_list: list of inner points, in same order as vector
     vector: the value for each point in inner_list"""
    num_grid = zeros(size)
    for i in eachindex(inner_list)
        num_grid[inner_list[i]...] = vector[i]
    end
    return num_grid
end


############################################## Main #########################
# Nothing is supposed to be run before this line
# Above this line are all necessary definitions, below are their execution

## Create fractal and grid ##
@verbose("Create fractal and grid")
grid, fractal = get_populated_grid(
    level=LEVEL,
    grid_constant=GRID_CONSTANT,
    return_fractal=true)
# Find inner points and create the eigenmatrix
@verbose("Generate eigenmatrix")
inner_list, mat = create_eigenmatrix(grid)
@verbose(mat)
values, vectors = solve_eigenproblem(mat)
@verbose(values, vectors)

############## Plotting ####################
@assert PLOT "Plotting not true"
@verbose("Begin plotting")
x,y = get_component_lists(fractal)
x .-= minimum(x)  # Move to fit with grid
y .-= minimum(y)

x = Array{Int}(undef, length(inner_list))
y = Array{Int}(undef, length(inner_list))

for i in eachindex(inner_list)
    x[i], y[i] = inner_list[i]
end

for mode in MODES_TO_PLOT
    plot_grid = plottable_grid(size(grid), inner_list, vectors[:, mode])

    # Colormesh
    plt.figure(figsize=(10,10), dpi=200)
    plt.pcolormesh(plot_grid)
    plt.savefig(@sprintf("%smode_%s.png", FIG_DIR, string(mode)))
    plt.clf()  # Clear figure

    # Surface
    #surf(plot_grid, cmap="coolwarm")
    scatter3D(x,y,vectors[:, mode], cmap="coolwarm")
    plt.savefig(@sprintf("%s/surface/mode_%s.png", FIG_DIR, string(mode)))
end
@verbose("Done!")
