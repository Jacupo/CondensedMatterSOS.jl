function Base.:*(a::SpinVariable, b::SpinVariable)
    if a.id == b.id
        if a.index == b.index
            return true # We want to return `1` but in which type ?
                        # We use `Bool` type as it the type compatible with the most other types in Julia.
        else
            i = a.index
            j = b.index
            pos = mod(i-j,3);
            if pos==2
                return  im*SpinVariable(a.id, mod(i+pos,3))
            elseif pos==1
                return  -im*SpinVariable(a.id, mod(i+pos,3))
            else
                error("Invalid `index` field for variables, we should have 0 <= `a.index`, `b.index` < 3.")
            end
        end
    else
        SpinMonomial([a,b]);
    end
end

function var_op!(op::Function, m::SpinMonomial, variable::SpinVariable)
    site = variable.id
    m_variable = get(m.variables, site, nothing)
    if m_variable === nothing
        coef = true
        m.variables[site] = variable
    else
        term = op(m_variable, variable) # It is either a `Term` or a `Bool`
        if term isa SpinTerm
            coef = coefficient(term)
            m.variables[site] = first(variables(term))
        else
            coef = term
            delete!(m.variables, site)
        end
    end
    return coef
end

function Base.:*(a::SpinMonomial, b::SpinVariable)
    c = deepcopy(a)
    coef = var_op!(*, c, b)
    return coef * c
end
function Base.:*(a::SpinVariable, b::SpinMonomial)
    c = deepcopy(b)
    coef = var_op!((x, y) -> y * x, c, a)
    return coef * c
end

function Base.:*(a::SpinMonomial, b::SpinMonomial)
    c = deepcopy(a)
    coef = true
    for variable in values(b.variables)
        coef *= var_op!(*, c, variable)
    end
    return coef * c
end
MP.multconstant(α, m::SpinMonomial) = SpinTerm(α, m)
MP.multconstant(m::SpinMonomial, α) = SpinTerm(α, m)
function Base.:(==)(a::SpinVariable, b::SpinVariable)
    return (a.id==b.id) && (a.index==b.index)
end
function Base.:(==)(a::SpinMonomial, b::SpinMonomial)
    return a.variables == b.variables
end

function Base.:(==)(var::SpinVariable, term::SpinTerm{T}) where T
    # NOTE that 1*ax and ax are different types. One is SpinVariable{Int64}
    # and the other is SpinVarible. Also note that ax*bx*bx=ax is of type
    # SpinVariable{bool}.
    if isone(coefficient(term))
        return var == term.monomial
    else
        return false
    end
end

function Base.:(==)(term::SpinTerm{T}, var::SpinVariable) where T
    return var == term
end

function MP.variable(mon::SpinMonomial)
    if isone(length(mon.variables))
        return first(values(mon.variables))
    else
        MP._errormono2var()
    end
end

function Base.:(==)(var::SpinVariable, mon::SpinMonomial)
    # If there is more than one SpinVariable in SpinMonomial then they are
    # unequal
    if !isone(length(mon.variables))
        return false
    else
        return var ==  MP.variable(mon)
    end
end


function Base.:(==)(mon::SpinMonomial, var::SpinVariable)
    return var == mon
end

function Base.:(==)(mon::SpinMonomial, term::SpinTerm{T}) where T
    if isone(coefficient(term))
        return mon == term.monomial
    else
        return false
    end
end

function Base.:(==)(term::SpinTerm{T}, mon::SpinMonomial) where T
    return mon == term
end
