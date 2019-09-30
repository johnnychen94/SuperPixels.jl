abstract type AbstractAnalyzeAlgorithm end

analyze(alg::AbstractAnalyzeAlgorithm, img, args...; kwargs...) = alg(img, args...; kwargs...)

"""
    SLIC(;[kw...])

Simple Linear Iterative Clustering (SLIC) algorithm segments image using
an `O(N)` complexity version of k-means clustering in Color-(x,y,z) space.

The implementation details is described in [1].

# Keywords

## `n_segments::Int`

The _approximate_ number of labels in the segmented output image. The default
value is `100`.

## `compatness::Float64`

Balances color proximity and space proximity. Higher values give more weight to
space proximity, making superpixel shapes more square/cubic. The default value
is `10.0`.

!!! tip

    We recommend exploring possible values on a log scale, e.g., `0.01`, `0.1`,
    `1`, `10`, `100`, before refining around a chosen value.

## `max_iter::Int`

Maximum number of iterations of k-means. The default value is `10`.

## `enforce_connectivity::Bool`

Whether the generated segments are connected or not. The default value is `true`.

# References

[1] Radhakrishna Achanta, Appu Shaji, Kevin Smith, Aurelien Lucchi, Pascal Fua, and Sabine Süsstrunk, SLIC Superpixels, _EPFL Technical Report_ no. 149300, June 2010.

[2] Radhakrishna Achanta, Appu Shaji, Kevin Smith, Aurelien Lucchi, Pascal Fua, and Sabine Süsstrunk, SLIC Superpixels Compared to State-of-the-art Superpixel Methods, _IEEE Transactions on Pattern Analysis and Machine Intelligence_, vol. 34, num. 11, p. 2274 – 2282, May 2012.

[3] EPFL (2018, Oct 24). SLIC Superpixels. Retrieved from https://ivrl.epfl.ch/research-2/research-current/research-superpixels/, Sep 29, 2019.
"""
struct SLIC <: AbstractAnalyzeAlgorithm
    n_segments::Int
    compatness::Float64
    max_iter::Int
    enforce_connectivity::Bool
end

function SLIC(; n_segments::Integer = 100,
                compatness::Real = 10.0,
                max_iter::Integer = 10,
                enforce_connectivity::Bool = true)
    SLIC(n_segments, compatness, max_iter, enforce_connectivity)
end

function Base.show(io::IO, alg::SLIC)
    sep = ", "
    print(io, "SLIC(")
    foreach(fieldnames(SLIC)) do x
        name = String(x)
        value = @eval $alg.$x
        print(io, name, "=", value, sep)
    end
    println(io, repeat("\b", length(sep)), ")")
end

_slic(alg::SLIC, img::AbstractArray{<:Number, 2}) = eltype(img).(_slic(alg, Gray.(img)))

function _slic(alg::SLIC, img::AbstractArray{<:Colorant, 2})
    CT = color_type(eltype(img))
    return CT.(_slic(alg, Lab.(img)))
end

function _slic(alg::SLIC, img::AbstractArray{<:Lab, 2})
    m = alg.compatness
    N = length(img)
    S = ceil(Int, sqrt(N/alg.n_segments))
    spatial_weight = m/S
    height, width = size(img)

    raw_img = permutedims(channelview(img), (2, 3, 1)) # [x y c] shape

    # initialize cluster centers with a grid of step S
    x = range(1, step=S, stop=size(img, 1))
    y = range(1, step=S, stop=size(img, 2))
    initial_centers = reshape(CartesianIndex.(Iterators.product(x, y)), :)
    n_segments = length(initial_centers) # _actual_ number of segments

    # xylab array of centers
    segments = zeros(Float32, (n_segments, 5))
    segments[:, 1] = map(xy->xy[1], initial_centers)
    segments[:, 2] = map(xy->xy[2], initial_centers)
    segments[:, 3:5] = raw_img[initial_centers, :]

    # number of pixels in each segment
    n_segment_elems = zeros(Int, n_segments)
    # nearest_distance[x, y] is the distance between pixel (x, y) and its current assigned center
    nearest_distance = fill(Inf, size(img))
    # nearest_segments[x, y] is the label of its assigned center, each center is labeled from 1 to n_segments
    nearest_segments = zeros(Int, size(img))

    for i in 1:alg.max_iter
        changed = false

        for k in 1:n_segments
            cx, cy = segments[k, 1:2]

            x_min = floor(Int, max(cx - 2S, 1))
            x_max = ceil(Int, min(cx + 2S, height))
            y_min = floor(Int, max(cy - 2S, 1))
            y_max = ceil(Int, min(cy + 2S, width))

            # break distance computation into nested for-loop to reuse `dy`
            for y in y_min:y_max
                dy = abs2(cy - y)
                for x in x_min:x_max
                    dx = abs2(cx - x)

                    dist_center = sqrt(dy + dx) * spatial_weight
                    dist_color = 0
                    for c in 3:5
                        t = raw_img[x, y, c-2] - segments[k, c]
                        dist_color += abs2(t)
                    end
                    dist_center += sqrt(dist_color)

                    if dist_center < nearest_distance[x, y]
                        nearest_distance[x, y] = dist_center
                        nearest_segments[x, y] = k
                        changed = true
                    end
                end
            end
        end

        changed || break

        # recompute segment centers

        # sum features for all segments
        n_segment_elems[:] .= 0
        segments[:, 1:2] .= 0
        for I in CartesianIndices(img)
            k = nearest_segments[I]
            n_segment_elems[k] += 1
            segments[k, 1:2] .+= I.I
            segments[k, 3:5] .+= raw_img[I, :]
        end

        # divide by number of elements per segment to obtain mean
        n_segment_elems[n_segment_elems.==0] .= 1
        segments ./= n_segment_elems # broadcast: (n_segments,) -> (n_segments, 5)
    end

    if alg.enforce_connectivity
        nothing # TODO
    end

    sp_img = map(1:n_segments) do i
        SuperPixel(img, findall(nearest_segments .== i))
    end

    return sp_img
end
