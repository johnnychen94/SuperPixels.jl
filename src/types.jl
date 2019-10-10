"""
    SuperPixel(pixels, pos)
    SuperPixel(img, pos)

A super pixel is a collection of pixels with their position information.

# Fields

* `color::AbstractArray{<:Colorant}` stores its pixel/color information.
* `position::CartesianIndices` stores its position information.

Relative order in `color` and `position` is important; `color[idx]` is the
image pixel at position `position[idx]`.

!!! tip

    There's a helper for each field. For example, `color(sp)` is equivalent to
    `sp.color`. This is useful to enable broadcasting such as `position.(img)`
    where `img` is a `SuperPixel` array.

# Examples

There're various ways to generate a superpixel at `img[1:2, 3:4]`:

```julia
img = rand(Gray, 4, 4)

SuperPixel(img, (1:2, 3:4))

pos = CartesianIndices(1:2, 3:4)
SuperPixel(img[pos], pos)
```

!!! note

    Each pixel in a superpixel is a `Colorant`; `Number` is promoted to `Gray`
    when constructing a `SuperPixel` object.

An array of `SuperPixel`s can be treated as an image, you can use [`synthesize`](@ref)
to generate the potential image contents.

```julia
img = rand(Gray, 4, 4)

img_sp = [SuperPixel(img, (1:2, 1:2)),
          SuperPixel(img, (1:2, 3:4)),
          SuperPixel(img, (3:4, 1:2)),
          SuperPixel(img, (3:4, 3:4))]

segments = [(1:2, 1:2), (1:2, 3:4), (3:4, 1:2), (3:4, 3:4)]
img_sp = [SuperPixel(img, pos) for pos in segments]

synthesize(img_sp) # composite superpixels into a complete image
synthesize(img_sp, Average()) # each superpixel is averaged first
```
"""
struct SuperPixel{T<:Colorant, N, AT<:AbstractArray{T}}
    color::AT
    position
end

function SuperPixel(
    color::AbstractArray{T},
    position::AbstractArray{CartesianIndex{N}}) where {T<:Colorant, N}

    color = length(color) == length(position) ? color : color[position]
    SuperPixel{T, N, typeof(color)}(color, position)
end

SuperPixel(color::AbstractArray{<:Colorant}, pos::Tuple) =
    SuperPixel(color, CartesianIndices(pos))

SuperPixel(pixels::AbstractArray{<:Number}, pos) =
    SuperPixel(Gray.(pixels), pos)

color(sp::SuperPixel) = sp.color
position(sp::SuperPixel) = sp.position


Base.isempty(sp::SuperPixel) = isempty(color(sp))
Base.:(==)(x::SuperPixel, y::SuperPixel) = x.position == y.position && x.color == y.color

color_type(sp::SuperPixel{CT}) where CT <: Colorant = CT
color_type(img::AbstractArray{<:SuperPixel}) = color_type(eltype(img))
color_type(::Type{<:SuperPixel{CT}}) where CT <: Colorant = CT

"""
    imsize(img)

Returns the size of potential image represented by [`SuperPixel`](@ref).
"""
imsize(img::AbstractArray{<:SuperPixel}) = _size(Iterators.flatten(position.(img)))
imsize(img::SuperPixel) = _size(position(img))
imsize(img::AbstractArray) = size(img)
function _size(R)
    I_first, I_last = extrema(R)
    return I_last.I .- I_first.I .+ (1, 1)
end
