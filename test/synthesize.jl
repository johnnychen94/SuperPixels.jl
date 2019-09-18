@testset "conversion" begin
    img = rand(Gray{Float32}, 4, 4)
    pixels = Pixel.(img, CartesianIndices(img))
    img_sp = [pixels[1:2, 1:2], pixels[1:2, 3:4], pixels[3:4, 1:2], pixels[3:4, 3:4]]
    @test img == synthesize(img_sp)
    @test img == synthesize(img_sp, Raw())
    @test img == synthesize(Gray{Float32}, img_sp)
    @test img == synthesize(Gray{Float32}, img_sp, Raw())
    @test RGB{Float32}.(img) == synthesize(RGB{Float32}, img_sp)

    img_sp = [pixels[1:2, 1:2], pixels[3:4, 1:2], pixels[1:2, 3:4], pixels[3:4, 3:4]] # order independent
    @test img == synthesize(img_sp, Raw())
    @test_nowarn synthesize(img_sp, Average())

    img_sp = [pixels[1:3, 1:3], pixels[1:2, 3:4], pixels[2:4, 1:3], pixels[3:4, 3:4]] # overlap
    @test img == synthesize(img_sp, Raw())
    @test_nowarn synthesize(img_sp, Average())
end
