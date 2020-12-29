@testset "CreateSuperpixels" begin
    input_image = load("../lenna.bmp")
    #println(color_type(eltype(input_image)))
    @btime _slic(SLIC(; n_segments=500, compatness=40.0, enforce_connectivity=true), Lab.($input_image))
    #out_superpixels = _slic(SLIC(; n_segments=100, compatness=10.0, enforce_connectivity=true), Lab.(input_image))
    #out_superpixels = _slic(SLIC(; n_segments=500, compatness=40.0, enforce_connectivity=true), Lab.(input_image))
    #synthesize(out_superpixels, Raw())
    #out_superpixels = analyze(slic_handle,
    #                          input_image)
    #save("foo.png", synthesize(out_superpixels))
end
