# symmetric, skew-symmetric and symmetric checks
"""
```julia
symmetric(::SecondOrderTensor)
symmetric(::FourthOrderTensor)
```
Computes the symmetric part of a second or fourth order tensor.
For a fourth order tensor, the symmetric part is the same as the minor symmetric part.
Returns a `SymmetricTensor`.

**Example:**

```jldoctest
julia> A = rand(Tensor{2,2})
2×2 Tensors.Tensor{2,2,Float64,4}:
 0.590845  0.566237
 0.766797  0.460085

julia> symmetric(A)
2×2 Tensors.SymmetricTensor{2,2,Float64,3}:
 0.590845  0.666517
 0.666517  0.460085
```
"""
@inline symmetric(S1::SymmetricTensors) = S1

@inline function symmetric(S::Tensor{2, dim}) where {dim}
    SymmetricTensor{2, dim}(@inline function(i, j) @inboundsret i == j ? S[i,j] : (S[i,j] + S[j,i]) / 2 end)
end



"""
```julia
minorsymmetric(::FourthOrderTensor)
```
Computes the minor symmetric part of a fourth order tensor, returns a `SymmetricTensor{4}`.
"""
@inline function minorsymmetric(S::Tensor{4, dim}) where {dim}
    SymmetricTensor{4, dim}(
        @inline function(i, j, k, l)
            @inbounds if i == j && k == l
                return S[i,j,k,l]
            else
                return (S[i,j,k,l] + S[j,i,k,l] + S[i,j,k,l] + S[i,j,l,k]) / 4
            end
        end
    )
end

@inline minorsymmetric(S::SymmetricTensors) = S

@inline symmetric(S::Tensor{4}) = minorsymmetric(S)

"""
```julia
majorsymmetric(::FourthOrderTensor)
```
Computes the major symmetric part of a fourth order tensor, returns a `Tensor{4}`.
"""
@inline function majorsymmetric(S::FourthOrderTensor{dim}) where {dim}
    Tensor{4, dim}(
        @inline function(i, j, k, l)
            @inbounds if i == j == k == l || i == k && j == l
                return S[i,j,k,l]
            else
                return (S[i,j,k,l] + S[k,l,i,j]) / 2
            end
        end
    )
end

"""
```julia
skew(::SecondOrderTensor)
```
Computes the skew-symmetric (anti-symmetric) part of a second order tensor, returns a `Tensor{2}`.
"""
@inline skew(S1::Tensor{2}) = (S1 - S1.') / 2
@inline skew(S1::SymmetricTensor{2,dim,T}) where {dim, T} = zero(Tensor{2,dim,T})

# Symmetry checks
@inline Base.issymmetric(t::Tensor{2, 1}) = true
@inline Base.issymmetric(t::Tensor{2, 2}) = @inboundsret t[1,2] == t[2,1]

@inline function Base.issymmetric(t::Tensor{2, 3})
    return @inboundsret t[1,2] == t[2,1] && t[1,3] == t[3,1] && t[2,3] == t[3,2]
end

function isminorsymmetric(t::Tensor{4, dim}) where {dim}
    @inbounds for l in 1:dim, k in l:dim, j in 1:dim, i in j:dim
        if t[i,j,k,l] != t[j,i,k,l] || t[i,j,k,l] != t[i,j,l,k]
            return false
        end
    end
    return true
end

isminorsymmetric(::SymmetricTensor{4}) = true

function ismajorsymmetric(t::FourthOrderTensor{dim}) where {dim}
    @inbounds for l in 1:dim, k in l:dim, j in 1:dim, i in j:dim
        if t[i,j,k,l] != t[k,l,i,j]
            return false
        end
    end
    return true
end

Base.issymmetric(t::Tensor{4}) = isminorsymmetric(t)

Base.issymmetric(::SymmetricTensors) = true
