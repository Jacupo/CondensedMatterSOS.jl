const NAMES = String[]

struct SpinVariable <: MP.AbstractVariable
    id::Int # Spin id, spins with different id commute
    index::Int # 0 means x, 1 means y and 2 means z
end

function spin(name::String)
    push!(NAMES, name)
    id = length(NAMES)
    return SpinVariable(id, 0), SpinVariable(id, 1), SpinVariable(id, 2)
end



struct SpinMonomial <: MP.AbstractMonomial
    variables::SortedDict{Int,SpinVariable};
    function SpinMonomial(vec::Vector{SpinVariable})
        variables   = SortedDict{Int, SpinVariable}()
        for spin in vec
            if in(keys(variables),spin.id)
                error("Monomial with repeated variable")
            end
            push!(variables, spin.id => spin);
        end
        new(variables)
    end
end

function MP.exponents(spin::SpinMonomial)
       #  #Exponents is a vector long as the the biggest site index of the spin
       #  exponents = zeros(Int, last(spin.variables)[1])
       #  for (key,value) in spin.variables
       #      #if the spin is actually present, exponent=1 that is the maximum
       #      exponents[key] = 1;
       #  end
       # return exponents;

       #There must be a 1to1 corresponendence between variables and exponents
       return ones(Int, length(spin.variables))
end

function MP.variables(spin::SpinMonomial)
    var = [];
    for (key,value) in spin.variables
        push!(var,value)
    end
    return var;
end

struct SpinTerm{T} <: MP.AbstractTerm{T}
    coefficient::T
    monomial::SpinMonomial
end

function MP.monomial(term::SpinTerm)
    return term.monomial
end

function MP.coefficient(term::SpinTerm)
    return term.coefficient
end


function build_spin(var)
    if isa(var, Symbol)
        σx = Symbol(string(var) * "x")
        σy = Symbol(string(var) * "y")
        σz = Symbol(string(var) * "z")
        return [σx, σy, σz], :(($(esc(σx)), $(esc(σy)), $(esc(σz))) = spin($"$var"))
    else
        isa(var, Expr) || error("Expected $var to be a variable name")
        Base.Meta.isexpr(var, :ref) || error("Expected $var to be of the form varname[idxset]")
        (2 ≤ length(var.args)) || error("Expected $var to have at least one index set")
        varname = var.args[1]
        prefix = string(varname)
        σx = Symbol(prefix * "x")
        σy = Symbol(prefix * "y")
        σz = Symbol(prefix * "z")
        return [σx, σy, σz], :(($(esc(σx)), $(esc(σy)), $(esc(σz))) = array_spin($prefix, $(esc.(var.args[2:end])...)))
    end
end

function build_spins(args)
    vars = Symbol[]
    exprs = []
    for arg in args
        var, expr = build_spin(arg)
        append!(vars, var)
        push!(exprs, expr)
    end
    return vars, exprs
end

# Variable vector x returned garanteed to be sorted so that if p is built with x then vars(p) == x
macro spin(args...)
    vars, exprs = build_spins(args)
    :($(foldl((x,y) -> :($x; $y), exprs, init=:())); $(Expr(:tuple, esc.(vars)...)))
end