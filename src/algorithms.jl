abstract type AbstractSuperPixelAlgorithm end

struct SimpleLinearIterativeClustering <: AbstractSuperPixelAlgorithm
    m::Int
    S::Int
end
const SLIC = SimpleLinearIterativeClustering
SLIC() = SLIC(10)

(alg::SLIC)(img::AbstractArray{<:Number, 2}) = alg(Lab.(Gray.(img)))
(alg::SLIC)(img::AbstractArray{<:Colorant, 2}) = alg(Lab.(img))
function (alg::SLIC)(img::AbstractArray{Lab, 2})
    throw("Not Implemented Error")
end

function _dist(x::Pixel, y::Pixel, alg::SLIC)
    m, S = alg.m, alg.S
    d_lab = Euclidean()(x.color, y.color)
    d_xy = sqrt(sum(@. abs2(x.pos.I - y.pos.I)))
    return d_lab + m/S * d_xy
end
