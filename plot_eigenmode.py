import numpy as np
import matplotlib.pyplot as plt
import sys
import os
from mpl_toolkits.mplot3d import Axes3D

modes = [0, 1, 4]
figdir = "media/"
fig_filetype = "pdf"

if not sys.argv[1]:
    print("Usage: python plot_eigenmode.py <path_to_data_dir>")
datadir = sys.argv[1]
figdir = os.path.join(datadir, figdir)

print("Reading files...", end='')
inner_list = np.loadtxt(datadir+"inner_list.txt", dtype=int)
eigenmodes = np.loadtxt(datadir+"eigenmodes.txt")
eigenvalues = np.loadtxt(datadir+"eigenvalues.txt")
fractal_x, fractal_y = np.loadtxt(datadir+"fractal.txt", unpack=True)
print("done!")

index_max, index_min = np.max(inner_list), np.min(inner_list)
size = index_max + 1
grid = np.ones((size, size))

# Move and resice fractal
fractal_x -= np.min(fractal_x)
fractal_y -= np.min(fractal_y)
fractal_x /= np.max(fractal_x)
fractal_y /= np.max(fractal_y)
fractal_y = 1 - fractal_y

def plot_colormesh(grid):
    plt.pcolormesh(grid_to_plot)
    plt.xticks([])
    plt.yticks([])
    plt.gca().set_aspect("equal")

def plot_wireframe(grid, fractal_x, fractal_y):
    fig = plt.figure()
    ax = fig.add_subplot(111, projection='3d')
    x = np.linspace(0, 1, grid.shape[0])
    y = np.linspace(0, 1, grid.shape[1])
    xx, yy = np.meshgrid(x, y)

    ax.plot_wireframe(xx, yy, np.where(grid == 1, np.nan, grid), color="gray")
    ax.plot(fractal_x, fractal_y, linewidth=0.8, color="darkred")
    ax.grid(False)
    plt.axis("off")
    ax.set_zlim(-0.01, 0.01)

def plot_surface(grid, fractal_x, fractal_y):
    fig = plt.figure()
    ax = fig.add_subplot(111, projection='3d')
    x = np.linspace(0, 1, grid.shape[0])
    y = np.linspace(0, 1, grid.shape[1])
    xx, yy = np.meshgrid(x, y)

    my_map = plt.get_cmap("coolwarm")
    my_map.set_over((0,0,0,0))
    ax.plot_surface(xx, yy, grid, cmap=my_map, vmin=-0.006, vmax=0.006, zorder=8)
    ax.plot(fractal_x, fractal_y, linewidth=0.8, color="darkred")
    ax.grid(False)
    plt.axis("off")
    ax.set_zlim(-0.01, 0.01)

for mode in modes:
    print("Mode", mode)
    print(" .Populating grid")
    for i, index in enumerate(inner_list):
        grid[tuple(index)] = eigenmodes[i, mode]

    print(" .Plotting")
    grid_to_plot = grid
    plot_surface(grid_to_plot, fractal_x, fractal_y)

    plt.show()
    #plt.savefig(figdir + "mode_" + str(mode) +"." + fig_filetype)
