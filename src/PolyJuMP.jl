__precompile__()

module PolyJuMP

using MultivariatePolynomials
using SemialgebraicSets
using JuMP
export getslack, setpolymodule!

# Polynomial Constraint

export ZeroPoly, NonNegPoly
abstract type PolynomialSet end
struct ZeroPoly <: PolynomialSet end
struct NonNegPoly <: PolynomialSet end
struct NonNegPolyMatrix <: PolynomialSet end

struct PolyConstraint{PT, ST<:PolynomialSet} <: JuMP.AbstractConstraint
    p::PT # typically either be a polynomial or a Matrix of polynomials
    set::ST
end
const PolyConstraintRef = ConstraintRef{Model, PolyConstraint}

# Responsible for getting slack and dual values
abstract type ConstraintDelegate end

function JuMP.addconstraint(m::Model, pc::PolyConstraint; domain::AbstractSemialgebraicSet=FullSpace(), kwargs...)
    delegates = getdelegates(m)
    c = getdefault(m, pc)
    delegate = addpolyconstraint!(m, c.p, c.set, domain; kwargs...)
    push!(delegates, delegate)
    m.internalModelLoaded = false
    PolyConstraintRef(m, length(delegates))
end

getdelegate(c::PolyConstraintRef, s::Symbol) = getdelegates(c.m)[c.idx]
getslack(c::PolyConstraintRef) = getslack(getdelegate(c, :Slack))
JuMP.getdual(c::PolyConstraintRef) = getdual(getdelegate(c, :Dual))

# PolyJuMP Data
type Data
    # Delegates for polynomial constraints created
    delegates::Vector{ConstraintDelegate}
    # Default set for Poly{true}
    nonnegpolyvardefault::Nullable
    # Default set for NonNegPoly
    nonnegpolydefault::Nullable
    # Default set for NonNegPolyMatrix
    nonnegpolymatrixdefault::Nullable
    function Data()
        new(ConstraintDelegate[], nothing, nothing, nothing)
    end
end

function getpolydata(m::JuMP.Model)
    if !haskey(m.ext, :Poly)
        m.ext[:Poly] = Data()
    end
    m.ext[:Poly]
end
getdelegates(m::JuMP.Model) = getpolydata(m).delegates

include("macros.jl")
include("default.jl")
include("default_methods.jl")

end # module
