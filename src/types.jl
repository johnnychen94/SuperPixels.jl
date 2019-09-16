abstract type AbstractPixel end

"""
    Pixel{CT<:Colorant} <: AbstractPixel

A pixel holds both color and spatial information.

Use [`color`](@ref) and [`position`](@ref) to get the color
and spatial information of `Pixel`.
"""
struct Pixel{CT<:Colorant} <: AbstractPixel
    color::CT
    pos::CartesianIndex
end
Pixel(gray::Number, pos) = Pixel(Gray(gray), pos)
Pixel(color::Colorant, pos::Tuple) = Pixel(color, CartesianIndex(pos))
color_type(::Type{CartesianIndex{CT}}) where CT<:Colorant = CT
""" `color(p::Pixel)` extracts the color information of a [`Pixel`](@ref). """
color(p::Pixel) = p.color
""" `position(p::Pixel` extracts the position information of a [`Pixel`](@ref). """
position(p::Pixel) = p.pos

"""
    SuperPixel{T<:AbstractPixel, N} = AbstractArray{T, N}

A super pixel is a collection of [`Pixel`](@ref)s, where each pixel holds
both color and spatial information.
"""
const SuperPixel{T<:AbstractPixel, N} = AbstractArray{T, N}
color_type(::Type{<:SuperPixel{T}}) where T<:Pixel = color_type(T)

"""
    SuperPixelImage{T<:SuperPixel, N} = AbstractArray{T, N}

A super pixel image is a collection of super pixels [`SuperPixel`](@ref).
"""
const SuperPixelImage{T<:SuperPixel, N} = AbstractArray{T, N}
color_type(::Type{<:SuperPixelImage{T}}) where T<:SuperPixel = color_type(T)
