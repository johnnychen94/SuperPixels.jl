# An intermediate helper class for synthesize
struct SuperPixelImage{C, N, AT<:AbstractArray{<:SuperPixel}} <: AbstractArray{C, N}
    tiles::AT

    axes::NTuple{N, UnitRange{Int}}
    function SuperPixelImage(tiles::SPI) where SPI<:AbstractArray{<:SuperPixel}
        C = eltype(eltype(SPI))
        N = ndims(eltype(SPI))
        new{C, N, SPI}(tiles, _spi_axes(axes.(tiles)...))
    end
end
SuperPixelImage(img::SuperPixelImage) = img

@inline _spi_axes(indices...) = __spi_axes(first(indices), tail(indices))
@inline function __spi_axes(R1, indices::Tuple)
    # TODO: accelerate this?
    R2 = first(indices)
    R = ntuple(length(R1)) do i
        r1, r2 = R1[i], R2[i]
        min(first(r1), first(r2)):max(last(r1), last(r2))
    end
    __spi_axes(R, tail(indices))
end
@inline __spi_axes(R, indices::Tuple{}) = R

@inline Base.axes(spi::SuperPixelImage) = spi.axes
@inline Base.size(spi::SuperPixelImage) = length.(spi.axes)

### synthesize

abstract type AbstractSynthesizeMethod end

"""
    synthesize([CT], img, [method=Raw()])

Collect pixels in `img` and returns an image of type `Array{CT}`.

Argument `method` controls how pixels are collected, supported methods
are [`Raw`](@ref) and [`Average`](@ref). The default value is `Raw()`.
"""
function synthesize(img::AbstractArray, args...; kwargs...)
    img = SuperPixelImage(img)
    synthesize(eltype(img), img, args...; kwargs...)
end
synthesize(::Type{T}, img::AbstractArray, args...; kwargs...) where T =
    synthesize(T, SuperPixelImage(img), args...; kwargs...)
synthesize(::Type{T}, img::SuperPixelImage, method=Raw(img), args...; kwargs...) where T =
    synthesize(T, img, method, args...; kwargs...)

"""
    Raw <: AbstractSynthesizeMethod
    Raw(fillvalue=0)

Pixel values inside SuperPixel is not changed.

Overlaps between superpixels are averaged. Missing pixels are filled by `fillvalue`.
"""
struct Raw{C<:Union{Number, Colorant}} <: AbstractSynthesizeMethod
    fillvalue::C
end
Raw() = Raw(0)
Raw(img::SuperPixelImage) = Raw(zero(eltype(img)))

function synthesize(::Type{T}, img::SuperPixelImage, S::Raw) where T
    out = zeros(T, size(img))
    count = zeros(Int, size(img)) # overlap counts

    for sp in img.tiles
        isempty(sp) && continue
        R = CartesianIndices(sp.indices)
        out[R] .+= @view sp.values[R]
        count[R] .+= 1
    end

    R = count.==0
    out[R] .= S.fillvalue
    count[R] .= 1
    return out./count
end

"""
    Mean <: AbstractSynthesizeMethod
    Mean(fillvalue=0)

Pixel values inside SuperPixel is averaged.

Overlaps between superpixels are averaged. Missing pixels are filled by `fillvalue`.
"""
struct Average <: AbstractSynthesizeMethod
    fillvalue
end
Average() = Average(0)

function synthesize(::Type{T}, img::SuperPixelImage, S::Average) where T
    averaged_img = map(img.tiles) do sp
        SuperPixel(Fill(mean(sp), axes(sp)), axes(sp))
    end
    return synthesize(T, averaged_img, Raw(S.fillvalue))
end
