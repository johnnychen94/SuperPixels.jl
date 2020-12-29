"""
    SuperPixel(pixels, pos)
    SuperPixel(img, pos)

A super pixel is a collection of pixels with their position information.

# Fields

* `values::AbstractArray{<:Colorant}` stores its pixel/color information.
* `indices::CartesianIndices` stores its position information.

Relative order in `values` and `indices` is important; `values[idx]` is the
image pixel at position `indices[idx]`.

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
struct SuperPixel{C, N, AT<:AbstractArray{C, N}, R} <: AbstractArray{C, N}
    values::AT
    indices::R

    axes::NTuple{N, UnitRange{Int}}
    function SuperPixel(values::AbstractArray{C, N}, indices) where {C, N}
        new{C, N, typeof(values), typeof(indices)}(values, indices, _sp_axes(indices))
    end
end

@inline _sp_axes(indices::CartesianIndices) = indices.indices
@inline _sp_axes(indices::Tuple) = indices
@inline function _sp_axes(indices::AbstractArray)
    N = length(view(indices, 1))
    ntuple(N) do i
        r = ntuple(length(indices)) do j
            @inbounds indices[j][i]
        end
        UnitRange(extrema(r)...)
    end
end

Base.axes(sp::SuperPixel) = sp.axes
Base.size(sp::SuperPixel) = length.(axes(sp))

Base.@propagate_inbounds function Base.getindex(sp::SuperPixel, ind...)
    # TODO: check whether ind ∈ sp.indices
    getindex(sp.values, ind...)
end
