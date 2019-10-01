module SuperPixels

using ImageCore, ColorVectorSpace
using Statistics
import ColorTypes: color_type, color
import Base: position

include("types.jl")
include("synthesize.jl")

export
    SuperPixel, color, position,
    # utils
    image_size,
    # algorithms
    synthesize, Raw, Average

end
