using Images, ImageCore
include("src/Superpixels.jl")

input_image = load("lenna.bmp")
out_superpixels = _slic(SLIC(n_segments=100, compactness=10.0, max_iter=10, enforce_connectivity=false),
                        input_image)
save("foo.png", synthesize(out_superpixels))
