# SuperPixelImage -> GenericImage
"""
    synthesize([CT], img::SuperPixelImage)

Collect pixels in `img` and returns an image of type `Array{CT}`.

Overlaps between superpixels are averaged. Empty pixels are filled
by zeros.
"""
synthesize(img::SuperPixelImage) = synthesize(color_type(img), img)
function synthesize(::Type{CT}, img::SuperPixelImage) where CT <: Colorant
    out = zeros(CT, image_size(img))
    count = zeros(Int, image_size(img))
    for SP in img
        R = position.(SP)
        out[R] .+= color.(SP)
        count[R] .+= 1
    end
    return out./count
end
