@testset "CreateSuperpixels" begin
    input_image = load("../lenna.bmp")
    #out_superpixels = _slic(SLIC(n_segments=100, compatness=10.0, max_iter=10, enforce_connectivity=false),
    #                    input_image)
    out_superpixels = SLIC(n_segments=100, compatness=10.0, max_iter=10, enforce_connectivity=false)
    save("foo.png", synthesize(out_superpixels))
end
