PLOT = true
include("utils.jl")

LEVEL = 3
GRID_CONSTANT = 4
NUM_MODES = 10

SAVE_DATA = true
FIG_DIR = "media/"

##################
## Calculations ##
##################

## Create fractal and grid
@verbose("Create fractal and grid")
grid, number_inside, fractal = get_populated_grid(
    level=LEVEL,
    grid_constant=GRID_CONSTANT,
    return_fractal=true)
# Find inner points and create the eigenmatrix
@verbose("Generate eigenmatrix")
inner_list, mat = create_eigenmatrix(grid, number_inside)
@verbose(mat)
values, vectors = solve_eigenproblem(mat)
@verbose(values, vectors)

@printf "Values calculated for level %i with grid constant %i\n" LEVEL GRID_CONSTANT
println("Mode#&\t omega/v\t")
for (i, value) in enumerate(values)
    @printf "%i&\t%.8E\n" i value
end
println("----")
println("omega/v\t deltaN")
for (i, value) in enumerate(values)
    interesting = i-(1/(4*pi))*value
    @printf "%f\t%6.8f\n" sqrt(value) interesting
end

######################
## Printing to file ##
######################
if SAVE_DATA
    using DelimitedFiles
    DATA_DIR = "datafiles/"
    filename = @sprintf("eigenvalues_level_%i_grid_constant_%i.dat", LEVEL, GRID_CONSTANT)
    full_filename = string(DATA_DIR, filename)
    writedlm(full_filename, values)
end

##############
## Plotting ##
##############

if PLOT==false
    exit()
end
@assert PLOT "Plotting not true"
@verbose("Begin plotting")

x_list, y_list = get_component_lists(fractal)
x_list .-= minimum(x_list)  # Move to fit with grid
y_list .-= minimum(y_list)
y_list = maximum(y_list) .- y_list  # Flip, because that's how colormesh plots
x_list /= maximum(x_list)  # Normalize
y_list /= maximum(y_list)

x = Array{Int}(undef, length(inner_list))
y = Array{Int}(undef, length(inner_list))

for i in eachindex(inner_list)
    x[i], y[i] = Tuple(inner_list[i])
end

# Found by experimenting
vmin = -0.01
vmax = 0.01

for mode in 1:NUM_MODES
    plot_grid = plottable_grid(size(grid), inner_list, real.(vectors[:, mode]))

    # Colormesh
#    plt.figure(figsize=(10,10), dpi=200)
    plt.title(@sprintf("Level l=%i, mode number %i\n \$\\omega/v\$ = %.3f", LEVEL, mode, sqrt(values[mode])))
#    plot_grid = plot_grid[1:10:end, 1:10:end]
    x = range(0, 1, length=size(plot_grid)[1])
    y = x
    plt.pcolormesh(x,y,plot_grid, vmin=vmin, vmax=vmax)
    plt.plot(x_list, y_list, "-", linewidth=0.2, color="black")
    plt.xlabel("\$x/L\$")
    plt.ylabel("\$y/L\$")
    plt.gca().set_aspect("equal")
    plt.savefig(@sprintf("%smode_%i.png", FIG_DIR, mode), dpi=300)
    plt.clf()  # Clear figure

    """
    # Surface
    cmap = plt.cm.coolwarm
    my_map = x-> ifelse(x==255, (0,0,0,0), cmap(x))
    """
#    vmax = maximum(plot_grid)
#    vmin = minimum(plot_grid)
    """
    for i in eachindex(grid)
        if grid[i]==OUTSIDE
            plot_grid[i] = NaN
        end
    end
    """

    surf(x, y, plot_grid, cmap="seismic", vmin=vmin, vmax=vmax)
    plt.plot(x_list, y_list, "-", linewidth=0.4, color="black")
    # #scatter3D(x,y,vectors[:, mode], cmap="coolwarm")
    plt.gca().set_zlim(-0.02, 0.02)
    plt.savefig(@sprintf("%s/surface/mode_%s.png", FIG_DIR, string(mode)), dpi=300)
    plt.clf()
end
@verbose("Done!")
