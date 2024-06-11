using TypstGenerator
using Test

@testset "TypstGenerator.jl" begin
    include("../example/example.jl")

    @test typeof(gen_example()) <: Vector{TypstGenerator.AbstractTypst}

    @test typeof(render_example(gen_example())) <: String

    @test typeof(run_exmaple("../example")) <: Base.Process
end
