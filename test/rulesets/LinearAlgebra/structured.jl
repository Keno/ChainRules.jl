@testset "Structured Matrices" begin
    @testset "/ and \\ on Square Matrixes" begin
        @testset "//, $T on the RHS" for T in (Diagonal, UpperTriangular, LowerTriangular)
            RHS = T(randn(T == Diagonal ? 10 : (10, 10)))
            test_rrule(/, randn(5, 10), RHS)
        end

        @testset "\\ $T on LHS" for T in (Diagonal, UpperTriangular, LowerTriangular)
            LHS = T(randn(T == Diagonal ? 10 : (10, 10)))
            test_rrule(\, LHS, randn(10))
            test_rrule(\, LHS, randn(10, 10))
        end
    end

    @testset "Diagonal" begin
        N = 3
        test_rrule(Diagonal, randn(N); output_tangent=randn(N, N))
        D = Diagonal(randn(N))
        test_rrule(Diagonal, randn(N); output_tangent=D)
        # Concrete type instead of UnionAll
        test_rrule(typeof(D), randn(N); output_tangent=D)

        # TODO: replace this with a `rrule_test` once we have that working
        # see https://github.com/JuliaDiff/ChainRulesTestUtils.jl/issues/24
        res, pb = rrule(Diagonal, [1, 4])
        @test pb(10*res) == (NO_FIELDS, [10, 40])
        comp = Composite{typeof(res)}(; diag=10*res.diag)  # this is the structure of Diagonal
        @test pb(comp) == (NO_FIELDS, [10, 40])
    end
    @testset "dot(x, ::Diagonal, y)" begin
        N = 4
        test_rrule(dot, randn(ComplexF64, N), Diagonal(randn(ComplexF64, N)), randn(ComplexF64, N))
    end
    @testset "::Diagonal * ::AbstractVector" begin
        N = 3
        test_rrule(*, Diagonal(randn(N)), randn(N))
    end
    @testset "diag" begin
        N = 7
        test_rrule(diag, randn(N, N))
        test_rrule(diag, Diagonal(randn(N)))
        test_rrule(diag, randn(N, N) ⊢ Diagonal(randn(N)))
        test_rrule(diag, Diagonal(randn(N)) ⊢ Diagonal(randn(N)))
        VERSION ≥ v"1.3" && @testset "k=$k" for k in (-1, 0, 2)
            test_rrule(diag, randn(N, N), k)
        end
    end
    @testset "diagm" begin
        @testset "without size" begin
            M, N = 7, 9
            s = (8, 8)
            a, ā = randn(M), randn(M)
            b, b̄ = randn(M), randn(M)
            c, c̄ = randn(M - 1), randn(M - 1)
            ȳ = randn(s)
            ps = (0 => a, 1 => b, 0 => c)
            y, back = rrule(diagm, ps...)
            @test y == diagm(ps...)
            ∂self, ∂pa, ∂pb, ∂pc = back(ȳ)
            @test ∂self === NO_FIELDS
            ∂a_fd, ∂b_fd, ∂c_fd = j′vp(_fdm, (a, b, c) -> diagm(0 => a, 1 => b, 0 => c), ȳ, a, b, c)
            for (p, ∂px, ∂x_fd) in zip(ps, (∂pa, ∂pb, ∂pc), (∂a_fd, ∂b_fd, ∂c_fd))
                ∂px = unthunk(∂px)
                @test ∂px isa Composite{typeof(p)}
                @test ∂px.first isa AbstractZero
                @test ∂px.second ≈ ∂x_fd
            end
        end
        VERSION ≥ v"1.3" && @testset "with size" begin
            M, N = 7, 9
            a, ā = randn(M), randn(M)
            b, b̄ = randn(M), randn(M)
            c, c̄ = randn(M - 1), randn(M - 1)
            ȳ = randn(M, N)
            ps = (0 => a, 1 => b, 0 => c)
            y, back = rrule(diagm, M, N, ps...)
            @test y == diagm(M, N, ps...)
            ∂self, ∂M, ∂N, ∂pa, ∂pb, ∂pc = back(ȳ)
            @test ∂self === NO_FIELDS
            @test ∂M === DoesNotExist()
            @test ∂N === DoesNotExist()
            ∂a_fd, ∂b_fd, ∂c_fd = j′vp(_fdm, (a, b, c) -> diagm(M, N, 0 => a, 1 => b, 0 => c), ȳ, a, b, c)
            for (p, ∂px, ∂x_fd) in zip(ps, (∂pa, ∂pb, ∂pc), (∂a_fd, ∂b_fd, ∂c_fd))
                ∂px = unthunk(∂px)
                @test ∂px isa Composite{typeof(p)}
                @test ∂px.first isa AbstractZero
                @test ∂px.second ≈ ∂x_fd
            end
        end
    end
    @testset "$f, $T" for
        f in (Adjoint, adjoint, Transpose, transpose),
        T in (Float64, ComplexF64)

        n = 5
        m = 3
        @testset "$f(::Matrix{$T})" begin
            A = randn(T, n, m)
            Y = f(A)
            Ȳ_mat = randn(T, m, n)
            Ȳ_composite = Composite{typeof(Y)}(parent=collect(f(Ȳ_mat)))

            test_rrule(f, A; output_tangent=Ȳ_mat)

            _, pb = rrule(f, A)
            @test pb(Ȳ_mat) == pb(Ȳ_composite)
        end

        @testset "$f(::Vector{$T})" begin
            a = randn(T, n)
            y = f(a)
            ȳ_mat = randn(T, 1, n)
            ȳ_composite = Composite{typeof(y)}(parent=collect(f(ȳ_mat)))

            test_rrule(f, a; output_tangent=ȳ_mat)

            _, pb = rrule(f, a)
            @test pb(ȳ_mat) == pb(ȳ_composite)
        end

        @testset "$f(::Adjoint{$T, Vector{$T})" begin
            a = randn(T, n)'
            ā = randn(T, n)'
            test_rrule(f, a ⊢ ā; output_tangent=randn(T, n))
        end

        @testset "$f(::Transpose{$T, Vector{$T})" begin
            a = transpose(randn(T, n))
            ā = transpose(randn(T, n))
            test_rrule(f, a ⊢ ā; output_tangent=randn(T, n))
        end
    end
    @testset "$T" for T in (UpperTriangular, LowerTriangular)
        n = 5
        test_rrule(T, randn(n, n); output_tangent=T(randn(n, n)))
    end
    @testset "$Op" for Op in (triu, tril)
        n = 7
        test_rrule(Op, randn(n, n))
        @testset "k=$k" for k in -2:2
            test_rrule(Op, randn(n, n), k)
        end
    end

    @testset "det and logdet $S" for S in (Diagonal, UpperTriangular, LowerTriangular)
        @testset "$op" for op in (det, logdet)
            @testset "$T" for T in (Float64, ComplexF64)
                n = 5
                # rand (not randn) so det will be postive, so logdet will be defined
                X = S(3*rand(T, (n, n)) .+ 1)
                X̄_acc = Diagonal(rand(T, (n, n)))  # sensitivity is always a diagonal for these types
                test_rrule(op, X ⊢ X̄_acc)
            end
            @testset "return type" begin
                X = S(3*rand(6, 6) .+ 1)
                _, op_pullback = rrule(op, X)
                X̄ = op_pullback(2.7)[2]
                @test X̄ isa Diagonal
            end
        end
    end
end
