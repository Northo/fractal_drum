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

function generate_grid(points::Array{Point,1})
    # Find borders for fractal
    # TODO: This could probably be improved by built-in functions
    max_x = min_x = points[1].x
    max_y = min_y = points[1].y
    for point in points
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

for l in 1:3
    println(length(
        create_square_fractal(l)
    ))
end
grid = generate_grid(
    create_square_fractal(2)
)

println("Loading PyPlot")
using PyPlot
println("PyPlot loaded!")

# L = length(points)
# x_list = Array{Int}(undef, L)
# y_list = Array{Int}(undef, L)
# for i in 1:L
#     x_list[i] = points[i].x
#     y_list[i] = points[i].y
# end
# plt.plot(x_list, y_list)


plt.plot(get_components_lists(grid)...)
plt.show()
