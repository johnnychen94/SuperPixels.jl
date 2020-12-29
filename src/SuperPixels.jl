module SuperPixels

using Base: tail
using Statistics
using FillArrays
using ImageCore, ColorVectorSpace

include("types.jl")
include("synthesize.jl")

export
    SuperPixel,
    # algorithms
    synthesize, Raw, Average

end
