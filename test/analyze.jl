@testset "CreateSuperpixels" begin
    input_image = load("../lenna.bmp")
    #println(color_type(eltype(input_image)))
    out_superpixels = _slic(SLIC(; enforce_connectivity=false),
                        Lab.(input_image))
    synthesize(out_superpixels, Raw())
    #out_superpixels = analyze(slic_handle,
    #                          input_image)
    #save("foo.png", synthesize(out_superpixels))
end
