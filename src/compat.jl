
# Code snippets from https://github.com/JuliaLang/Compat.jl

function _compat(ex::Expr)
    if VERSION < v"0.7.0-DEV.2562"
        if ex.head == :call && ex.args[1] == :finalizer
            ex.args[2], ex.args[3] = ex.args[3], ex.args[2]
        end
    end
    return Expr(ex.head, map(_compat, ex.args)...)
end

_compat(ex) = ex

macro compat(ex)
    esc(_compat(ex))
end

@static if !isdefined(Base, :pairs)
    pairs(collection) = Base.Generator(=>, keys(collection), values(collection))
    pairs(a::Associative) = a

    const IndexValue = Iterators.IndexValue

    pairs(::IndexLinear,    A::AbstractArray) = IndexValue(A, linearindices(A))
    pairs(::IndexCartesian, A::AbstractArray) = IndexValue(A, CartesianRange(indices(A)))

    Base.keys(a::AbstractArray) = CartesianRange(indices(a))
    Base.keys(a::AbstractVector) = linearindices(a)
    Base.keys(s::IndexStyle, A::AbstractArray, B::AbstractArray...) = eachindex(s, A, B...)

    Base.values(itr) = itr
end
