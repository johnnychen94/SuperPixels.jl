module SuperPixels

using ImageCore, ColorVectorSpace
using ImageCore: GenericImage
using Statistics
import ColorTypes: color_type, color
import Base: position

include("types.jl")
include("synthesize.jl")

export
    # Types
    Pixel, SuperPixel, SuperPixelImage,
    # utils
    color, position, image_size,
    # algorithms
    synthesize, Raw, Average

end
