# Role, describes the role of a point in a grid
@enum Role inside outside border

struct Point
    x::Int
    y::Int
    role::Role

    Point(x,y) = new(x,y,outside::Role)
    Point(x,y,role) = new(x,y,role)
end

function Base.:+(x::Point, y::Point)
    return Point(x.x+y.x, x.y+y.y)
end

function Base.:-(x::Point, y::Point)
    return Point(x.x-y.x, x.y-y.y)
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

function generate_grid(L)
    grid = Array{Role, 2}(undef, L, L)
    for i in eachindex(grid)
        grid[i] = outside::Role
    end
end

recursion_level = 2
L = 4^recursion_level

x1 = Point(0,0)
x2 = x1 + Point(L,0)
x3 = x2 + Point(0,L)
x4 = x3 + Point(-L,0)
x5 = x4 + Point(0, -L)

square = [x1,x2,x3,x4,x5]
points = create_fractal(square, recursion_level)

println("Loading PyPlot")
using PyPlot
println("PyPlot loaded!")

L = length(points)
x_list = Array{Int}(undef, L)
y_list = Array{Int}(undef, L)
for i in 1:L
    x_list[i] = points[i].x
    y_list[i] = points[i].y
end

plt.plot(x_list, y_list)
plt.show()
