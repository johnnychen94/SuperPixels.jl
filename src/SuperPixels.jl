module SuperPixels

using ImageCore
using ImageCore: GenericImage
import ColorTypes: color_type, color

include("types.jl")

export
    Pixel,
    SuperPixel,
    SuperPixelImage

end
