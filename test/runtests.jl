using ImageCore, Images
using Test, Suppressor

refambs = @suppress_out detect_ambiguities(ImageCore, Base)
using SuperPixels
ambs = @suppress_out detect_ambiguities(ImageCore, Base, SuperPixels)

@testset "SuperPixels.jl" begin
    # check if SuperPixels.jl introduces new ambiguities
    @test isempty(setdiff(ambs, refambs))

    include("types.jl")
    include("synthesize.jl")
    include("analyze.jl")
end

nothing
