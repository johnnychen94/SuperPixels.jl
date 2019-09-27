abstract type AbstractSynthesizeMethod end

"""
    Raw <: AbstractSynthesizeMethod

Pixel values inside SuperPixel is not changed.
"""
struct Raw <: AbstractSynthesizeMethod end
"""
    Mean <: AbstractSynthesizeMethod

Pixel values inside SuperPixel is averaged.
"""
struct Average <: AbstractSynthesizeMethod end

"""
    synthesize([CT], img, [method=Raw()])

Collect pixels in `img` and returns an image of type `Array{CT}`.

Argument `method` controls how pixels are collected, supported methods
are [`Raw`](@ref) and [`Average`](@ref). The default value is `Raw`.

!!! note
    Overlaps between superpixels are averaged. Empty pixels are filled
    by zeros.
"""
synthesize(img::SuperPixelImage, method = Raw()) = synthesize(color_type(img), img, method)
synthesize(::Type{T}, img::SuperPixelImage, method = Raw()) where T = synthesize(T, img, method)

function synthesize(::Type{CT}, img::SuperPixelImage, ::Raw) where CT <: Union{AbstractRGB, AbstractGray}
    out = zeros(CT, image_size(img))
    count = zeros(Int, image_size(img)) # overlap count
    for SP in img
        isempty(SP) && continue
        R = position.(SP)
        out[R] .+= color.(SP)
        count[R] .+= 1
    end
    return out./count
end

function synthesize(::Type{CT}, img::SuperPixelImage, ::Average) where CT <: Union{AbstractRGB, AbstractGray}
    averaged_img = map(img) do SP
        Pixel.(mean(color.(SP)), position.(SP))
    end
    return synthesize(CT, averaged_img, Raw())
end
