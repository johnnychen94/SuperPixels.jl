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
    imsize,
    # algorithms
    synthesize, Raw, Average

end
