@testset "conversion" begin
    img = rand(Gray{Float32}, 4, 4)
    img_sp = [SuperPixel(img, (1:2, 1:2)),
              SuperPixel(img, (1:2, 3:4)),
              SuperPixel(img, (3:4, 1:2)),
              SuperPixel(img, (3:4, 3:4))]
    @test img == synthesize(img_sp)
    @test img == synthesize(img_sp, Raw())
    @test img == synthesize(Gray{Float32}, img_sp)
    @test img == synthesize(Gray{Float32}, img_sp, Raw())
    @test RGB{Float32}.(img) == synthesize(RGB{Float32}, img_sp)

    # order independent
    img_sp = [SuperPixel(img, (1:2, 1:2)),
              SuperPixel(img, (3:4, 1:2)),
              SuperPixel(img, (1:2, 3:4)),
              SuperPixel(img, (3:4, 3:4))]
    @test img == synthesize(img_sp, Raw())
    @test_nowarn synthesize(img_sp, Average())

    # overlap
    img_sp = [SuperPixel(img, (1:2, 1:2)),
              SuperPixel(img, (1:2, 3:4)),
              SuperPixel(img, (2:4, 1:3)),
              SuperPixel(img, (3:4, 3:4))]
    @test img == synthesize(img_sp, Raw())
    @test_nowarn synthesize(img_sp, Average())
end
