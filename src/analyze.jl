using DelimitedFiles

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

    # Enforce connectivity
    # Reference: https://github.com/scikit-image/scikit-image/blob/7e4840bd9439d1dfb6beaf549998452c99f97fdd/skimage/segmentation/_slic.pyx#L240-L348
    if alg.enforce_connectivity

        segment_size = height * width / n_segments
        min_size = round(Int, 0.5 * segment_size)
        max_size = round(Int, 3.0 * segment_size)

        dy = [1, -1, 0, 0]
        dx = [0, 0, 1, -1]
        # dz = [] # reversed for supervoxels

        start_label = 1
        mask_label = start_label - 1 # indicates the label of this pixel has not been assigned
        nearest_segments_final = fill(mask_label, height, width)
        current_new_label = start_label

        # used for BFS
        current_segment_size = 1
        bfs_visited = 0

        # store neighboring pixels
        # now set the dimension to 2 because we are using superpixel
        coord_list = fill(0, max_size, 2)
 
        for x = 1:width
            for y = 1:height
                nearest_segments[y, x] == mask_label && continue
                nearest_segments_final[y, x] > mask_label && continue

                adjacent = 0
                label = nearest_segments[y, x]
                nearest_segments_final[y, x] = current_new_label
                current_segment_size = 1
                bfs_visited = 0
                coord_list[bfs_visited + 1, 1] = y
                coord_list[bfs_visited + 1, 2] = x

                # Preform BFS to find the size of superpixel with 
                # same lable number
                while bfs_visited < current_segment_size <= max_size
                    for i = 1:4
                        yy = coord_list[bfs_visited + 1, 1] + dy[i]
                        xx = coord_list[bfs_visited + 1, 2] + dx[i]

                        if 1 <= yy <= height &&  1 <= xx <= width
                            if nearest_segments[yy, xx] == label && nearest_segments_final[yy, xx] == mask_label
                                nearest_segments_final[yy, xx] = current_new_label
                                coord_list[current_segment_size + 1, 1] = yy # <-- index problem in the future
                                coord_list[current_segment_size + 1, 2] = xx # <-- index problem in the future
                                current_segment_size += 1
                                
                                if current_segment_size > max_size break end
                            elseif nearest_segments_final[yy, xx] > mask_label &&
                                   nearest_segments_final[yy, xx] != current_new_label
                                adjacent = nearest_segments_final[yy, xx]
                            end
                        end
                    end
                    bfs_visited += 1
                end

                #for i = 1:current_segment_size println(coord_list[i, 1]) end
                #println(max_size, " ", current_segment_size)

                # merge the superpixel to its neighbor if it is too small
                if current_segment_size < min_size
                    @inbound @simd for i = 1:current_segment_size

                        nearest_segments_final[coord_list[i, 1],
                                     coord_list[i, 2]] = adjacent
                    end
                else
                    current_new_label += 1
                end
            end
        end
        #nearest_segments = copy(nearest_segments_final)
        nearest_segments = nearest_segments_final
    end


    open("superpixels_100_10_compat.txt", "w") do io
        writedlm(io, nearest_segments,' ')
    end

    sp_img = map(1:n_segments) do i
        SuperPixel(img, findall(nearest_segments .== i))
    end

    return sp_img
end
