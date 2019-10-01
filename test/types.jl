@testset "Type" begin
    @testset "SuperPixel" begin
        for T in (Lab{Float32}, RGB{Float32}, Gray{Float32}, Float32)
            img = rand(T, 4, 4)

            pos = (1:2, 3:4)
            sp1 = SuperPixel(img, pos)
            sp2 = SuperPixel(img[pos...], pos)

            pos = CartesianIndices(pos)
            sp3 = SuperPixel(img, pos)
            sp4 = SuperPixel(img[pos], pos)

            @test eltype(sp1.color) <: Colorant # Number is promoted to Gray
            @test size(sp1.color) == size(sp1.position)
            @test sp1.color == img[sp1.position] # relative order is perserved
            @test sp2 == sp1
            @test sp3 == sp1
            @test sp4 == sp1

            @test color(sp1) == sp1.color
            @test position(sp1) == sp1.position

            @test isempty(sp1) == isempty(sp1.color)
        end
    end
end
