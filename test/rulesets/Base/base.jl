@testset "base" begin
    @testset "Trig" begin
        @testset "Basics" for x = (Float64(π)-0.01, Complex(π, π/2))
            test_scalar(sec, x)
            test_scalar(csc, x)
            test_scalar(cot, x)
            test_scalar(sinpi, x)
            test_scalar(cospi, x)
        end
        @testset "Hyperbolic" for x = (Float64(π)-0.01, Complex(π-0.01, π/2))
            test_scalar(sech, x)
            test_scalar(csch, x)
            test_scalar(coth, x)
        end
        @testset "Degrees" begin
            x = 45.0
            test_scalar(sind, x)
            test_scalar(cosd, x)
            test_scalar(tand, x)
            test_scalar(secd, x)
            test_scalar(cscd, x)
            test_scalar(cotd, x)
        end
        @testset "Inverses" for x = (0.5, Complex(0.5, 0.25))
            test_scalar(asec, 1/x)
            test_scalar(acsc, 1/x)
            test_scalar(acot, 1/x)
        end
        @testset "Inverse hyperbolic" for x = (0.5, Complex(0.5, 0.25),  Complex(-2.1 -3.1im))
            test_scalar(asinh, x)
            test_scalar(acosh, x + 1)  # +1 accounts for domain for real
            test_scalar(atanh, x)
            test_scalar(asech, x)
            test_scalar(acsch, x)
            test_scalar(acoth, x + 1)
        end

        @testset "Inverse degrees" for x = (0.5, Complex(0.5, 0.25))
            test_scalar(asind, x)
            test_scalar(acosd, x)
            test_scalar(atand, x)
            test_scalar(asecd, 1/x)
            test_scalar(acscd, 1/x)
            test_scalar(acotd, 1/x)
        end

        @testset "sinc" for x = (0.0, 0.434, Complex(0.434, 0.25))
            test_scalar(sinc, x)
        end
    end  # Trig

    @testset "Angles" begin
        for x in (-0.1, 6.4, 0.5 + 0.25im)
            test_scalar(deg2rad, x)
            test_scalar(rad2deg, x)
        end
    end

    @testset "Unary complex functions" begin
        for x in (-4.1, 6.4, 0.0, 0.0 + 0.0im, 0.5 + 0.25im)
            test_scalar(real, x)
            test_scalar(imag, x)
            test_scalar(hypot, x)
            test_scalar(adjoint, x)
        end
    end

    @testset "Complex" begin
        test_scalar(Complex, randn())
        test_scalar(Complex, randn(ComplexF64))

        test_frule(Complex, randn(), randn())
        test_rrule(Complex, randn(), randn())
    end

    @testset "*(x, y) (scalar)" begin
        # This is pretty important so testing it fairly heavily
        test_points = (0.0, -2.1, 3.2, 3.7+2.12im, 14.2-7.1im)
        @testset "($x) * ($y)" for
            x in test_points, y in test_points

            # ensure all complex if any complex for FiniteDifferences
            x, y = Base.promote(x, y)

            test_frule(*, x, y)
            test_rrule(*, x, y)
        end
    end

    @testset "ldexp" begin
        for n in (0,1,20)
            test_frule(ldexp, 10rand(), n)
            test_rrule(ldexp, 10rand(), n)
        end
    end

    @testset "\\(x::$T, y::$T) (scalar)" for T in (Float64, ComplexF64)
        test_frule(*, randn(T), randn(T))
        test_rrule(*, randn(T), randn(T))
    end

    @testset "mod" begin
        test_frule(mod, 10rand(), rand())
        test_rrule(mod, 10rand(), rand())
    end

    @testset "identity" for T in (Float64, ComplexF64)
        test_frule(identity, randn(T))
        test_frule(identity, randn(T, 4))
        test_frule(
            identity,
            #Tuple(randn(T, 3)) ⊢ Composite{Tuple{T, T, T}}(randn(T, 3)...)
            Tuple(randn(T, 3))
        )

        test_rrule(identity, randn(T))
        test_rrule(identity, randn(T, 4))
        test_rrule(
            identity,
            Tuple(randn(T, 3)) ⊢ Composite{Tuple{T, T, T}}(randn(T, 3)...);
            output_tangent = Composite{Tuple{T, T, T}}(randn(T, 3)...)
        )
    end

    @testset "Constants" for x in (-0.1, 6.4, 1.0+0.5im, -10.0+0im, 0.0+200im)
        test_scalar(one, x)
        test_scalar(zero, x)
    end

    @testset "muladd(x::$T, y::$T, z::$T)" for T in (Float64, ComplexF64)
        test_frule(muladd, 10randn(), randn(), randn())
        test_rrule(muladd, 10randn(), randn(), randn())
    end

    @testset "fma" begin
        test_frule(fma, 10randn(), randn(), randn())
        test_rrule(fma, 10randn(), randn(), randn())
    end

    @testset "clamp"  begin
        # to left
        test_frule(clamp, 1., 2., 3.)
        test_rrule(clamp, 1., 2., 3.)

        # in the middle
        test_frule(clamp, 2.5, 2., 3.)
        test_rrule(clamp, 2.5, 2., 3.)

        # to right
        test_frule(clamp, 4., 2., 3.)
        test_rrule(clamp, 4., 2., 3.)
    end

    @testset "rounding" begin
        for x in (-0.6, -0.2, 0.1, 0.6)
            # thanks to RoundNearest
            if 0 > x % 1 > 0.5 || -1 < x % 1 <= 0.5
                test_scalar(round, x; fdm=backward_fdm(5,1))
            else
                test_scalar(round, x; fdm=forward_fdm(5,1))
            end
            test_scalar(floor, x; fdm=backward_fdm(5, 1))
            test_scalar(ceil, x; fdm=forward_fdm(5, 1))
        end
    end

    @testset "type" begin
        @test frule((NO_FIELDS, DoesNotExist(), DoesNotExist()), typejoin, Array{Float32,4}, Array{Float32,3}) !== nothing
        @test rrule(typejoin, Array{Float32,4}, Array{Float32,3}) !== nothing
    end

    @testset "Logging" begin
        @test frule((NO_FIELDS, DoesNotExist(), DoesNotExist()), Base.depwarn, "message", :f) !== nothing
        @test rrule(Base.depwarn, "message", :f) !== nothing
    end
end
