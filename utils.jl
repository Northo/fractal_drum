using LinearAlgebra
using Arpack
using SparseArrays

VERBOSE = true
if PLOT
    println("Loading PyPlot")
    using PyPlot
    println("PyPlot loaded!")
end

# Constants and setup
LEVEL = 4
GRID_CONSTANT = 3
FIG_DIR = "modes/"
NUM_MODES = 10

# Used in grid
BORDER = 0
OUTSIDE = -1

macro verbose(msg...)
    if VERBOSE
        println(msg...)
    end
end

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
    grid = Array{Int, 2}(undef, L, L)
    for i in eachindex(grid)
        grid[i] = OUTSIDE
    end

    # Set border
    for point in points
        grid[point.x-min_x+1, point.y-min_y+1] = BORDER
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
## scanning out for each cell.
## Assumes a grid constant of at least 2
function check_grid_point(grid, x, y)
    """Checks a point in grid. Does not
    check if allready inside"""
    if grid[x,y]==BORDER
        return BORDER
    end

    if grid[x-1,y]>0
        return 1
    end

    # Count number of times we cross border
    border_crossings = 0
    # Scan left
    for i in 1:x-1
        if grid[x-i, y]==BORDER && grid[x-i, y-1]==BORDER
            border_crossings+=1
        end
    end
    return mod(border_crossings,2)==0 ? OUTSIDE : 1
end

function populate_grid!(grid::Array{Int,2})
    """Takes a grid with an enclosed border"""

    height, width = size(grid)
    number_inside = 0

    # We know that the border of the grid cannot
    # contain inner points. Therefore we do not check them.
    # Take care of edge case
    # for y in 2:height-1
    #     if grid[2,y]!=BORDER && grid[1,y]==BORDER
    #         number_inside += 1
    #         grid[2,y] = number_inside
    #     end
    # end
    for x = 2:width-1, y = 2:height-1
        status = check_grid_point(grid, x, y)
        if status == 1
            number_inside += 1
            grid[x,y] = number_inside
        end
    end
    return number_inside
end

## Second method for deciding inside
## Scans middle out
function populate_grid_middle_out!(grid::Array{Int,2})
    """Takes a grid with an enclosed border,
    and makes internal points inside::Role."""
    # Find center
    height, width = size(grid)
    mid_x = Integer(floor(height/2))
    mid_y = Integer(floor(width/2))

    points_to_check = [(mid_x+1, mid_y),
                       (mid_x-1, mid_y),
                       (mid_x, mid_y+1),
                       (mid_x, mid_y-1)]
    i = 1
    for (x, y) in points_to_check
        if grid[x,y]==BORDER || grid[x,y]>0
            continue
        end
        grid[x,y] = i
        push!(points_to_check, (x+1,y))
        push!(points_to_check, (x-1,y))
        push!(points_to_check, (x,y+1))
        push!(points_to_check, (x,y-1))
        i += 1
    end

    return i - 1  # Number of inner points
end

function get_fractal(;level=2, grid_constant=1)
    fractal = create_square_fractal(level)
    fractal = split_segments(fractal, grid_constant)
    return fractal
end

function get_populated_grid(;level=2,
                            grid_constant=1,
                            return_fractal=false,
                            population_function=populate_grid_middle_out!
                            )
    """level: recursion depth
       grid_constant: number of points per smallest length on fractal"""
    fractal = get_fractal(level=level, grid_constant=grid_constant)
    grid = generate_grid(fractal)
    number_inside = population_function(grid)
    if return_fractal
        return grid, number_inside, fractal
    end
    return grid, number_inside
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

function create_eigenmatrix(grid, number_inside)
    # An alternative would be to
    # use information about how eachindex
    # works to avoid needing the Point array

    # Notice that the values have opposite
    # sign of what you get from 5-point stencil
    # this is because we want - (nabla)^2

    inner_list = Array{CartesianIndex}(undef, number_inside)
    for i in CartesianIndices(grid)
        if grid[i]>0
            inner_list[grid[i]] = i
        end
    end

    I = Array{Int}(undef, number_inside*5)
    J = Array{Int}(undef, number_inside*5)
    V = Array{Int}(undef, number_inside*5)

    index = 1
    for i in eachindex(inner_list)
        I[index] = i
        J[index] = i
        V[index] = 4
        index += 1
        x, y = Tuple(inner_list[i])
        for cell in [(x+1,y), (x-1,y), (x,y+1), (x,y-1)]
            if grid[cell...]>0
                inner_index = grid[cell...]
                I[index] = i
                J[index] = inner_index
                V[index] = -1
                index += 1
            end
        end
    end
    index = index-1
    mat = sparse(I[1:index], J[1:index], V[1:index])
    return inner_list, mat
end

function create_eigenmatrix_high_order(grid, number_inside)
    # An alternative would be to
    # use information about how eachindex
    # works to avoid needing the Point array

    # Notice that the values have opposite
    # sign of what you get from 5-point stencil
    # this is because we want - (nabla)^2

    inner_list = Array{CartesianIndex}(undef, number_inside)
    width, height = size(grid)
    for i in CartesianIndices(grid)
        if grid[i]>0
            inner_list[grid[i]] = i
        end
    end

    I = Array{Float64}(undef, number_inside*9)
    J = Array{Float64}(undef, number_inside*9)
    V = Array{Float64}(undef, number_inside*9)

    index = 1
    for i in eachindex(inner_list)
        I[index] = i
        J[index] = i
        V[index] = 5
        index += 1
        x, y = Tuple(inner_list[i])
        for cell in [(x+1,y), (x-1,y), (x,y+1), (x,y-1)]
            if grid[cell...]>0
                inner_index = grid[cell...]
                I[index] = i
                J[index] = inner_index
                V[index] = -4/3
                index += 1
            end
        end
        for cell in [(x+2,y), (x-2,y), (x,y+2), (x,y-2)]
            if cell[1]==0 || cell[2]==0 || cell[1]==width+1 || cell[2]==height+1
                continue
            end
            if grid[cell...]>0
                inner_index = grid[cell...]
                I[index] = i
                J[index] = inner_index
                V[index] = 1/12
                index += 1
            end
        end
    end
    index = index-1
    mat = sparse(I[1:index], J[1:index], V[1:index])
    return inner_list, mat
end

# function solve_eigenproblem(matrix)
#     values, vectors = eigen(matrix)
#     sort_index = sortperm(values)
#     return values[sort_index], vectors[:, sort_index]
# end

function solve_eigenproblem(matrix)
    values, vectors = eigs(matrix, nev=NUM_MODES, which=:SM)
    return values, vectors
end

function plottable_grid(size, inner_list, vector)
    """
    Parameter:
     size: size of grid to create
     inner_list: list of inner points, in same order as vector
     vector: the value for each point in inner_list"""
    num_grid = zeros(size)
    for i in eachindex(inner_list)
        num_grid[Tuple(inner_list[i])...] = vector[i]
    end
    return num_grid
end
