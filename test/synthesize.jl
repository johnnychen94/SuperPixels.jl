@testset "conversion" begin
    img = rand(Gray{Float32}, 4, 4)
    pixels = Pixel.(img, CartesianIndices(img))

    img_sp1 = [pixels[1:2, 1:2], pixels[1:2, 3:4], pixels[3:4, 1:2], pixels[3:4, 3:4]]
    @test img == synthesize(img_sp1)

    img_sp2 = [pixels[1:2, 1:2], pixels[3:4, 1:2], pixels[1:2, 3:4], pixels[3:4, 3:4]] # order independent
    @test img == synthesize(img_sp2)

    img_sp3 = [pixels[1:3, 1:3], pixels[1:2, 3:4], pixels[2:4, 1:3], pixels[3:4, 3:4]] # overlap
    @test img == synthesize(img_sp3)
end
