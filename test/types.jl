@testset "Types" begin
    @testset "Pixel" begin
        p = Pixel(Gray(0), (1, 1))

        @test_throws MethodError Pixel(rand(Gray))
        @test p == Pixel(Gray(0), CartesianIndex(1, 1))
        @test p == Pixel(0, (1, 1))
    end

    @testset "SuperPixel" begin
        for T in (Lab{Float32}, RGB{Float32}, Gray{Float32}, Float32)
            img = rand(T, 4, 4)

            # Although conceptually, an image is a large super pixel,
            # it isn't a SuperPixel type
            @test !(img isa SuperPixel)
            @test Pixel.(img, CartesianIndices(img)) isa SuperPixel
        end
    end

    @testset "SuperPixelImage" begin
        for T in (Lab{Float32}, RGB{Float32}, Gray{Float32}, Float32)
            img = rand(T, 4, 4)
            pixels = Pixel.(img, CartesianIndices(img))
            SP_1 = pixels[1:3, 1:3]
            SP_2 = pixels[1:3, 4]
            SP_3 = pixels[4, 1:2]
            SP_4 = pixels[4, 3:4]
            img_sp = [SP_1, SP_2, SP_3, SP_4]

            # Although conceptually, an image is a large super pixel,
            # it isn't a SuperPixelImage type
            @test !(img isa SuperPixelImage)
            @test img_sp isa SuperPixelImage
        end
    end
end
