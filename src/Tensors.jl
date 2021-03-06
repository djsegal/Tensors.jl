__precompile__()

module Tensors

import Base.@pure

export AbstractTensor, SymmetricTensor, Tensor, Vec, FourthOrderTensor, SecondOrderTensor

export otimes, ⊗, ⊡, dcontract, dev, vol, symmetric, skew, minorsymmetric, majorsymmetric
export minortranspose, majortranspose, isminorsymmetric, ismajorsymmetric
export tdot, dott, dotdot
export hessian, gradient, curl, div, laplace
export basevec, eᵢ
export rotate
export tovoigt, tovoigt!, fromvoigt, tomandel, tomandel!, frommandel

#########
# Types #
#########
abstract type AbstractTensor{order, dim, T <: Real} <: AbstractArray{T, order} end

struct SymmetricTensor{order, dim, T, M} <: AbstractTensor{order, dim, T}
    data::NTuple{M, T}
    SymmetricTensor{order, dim, T, M}(data::NTuple) where {order, dim, T, M} = new{order, dim, T, M}(data)
end

struct Tensor{order, dim, T, M} <: AbstractTensor{order, dim, T}
    data::NTuple{M, T}

    # this is needed to make Vec{3, Float64}(f::Function) work properly
    Tensor{order, dim, T, M}(data::NTuple) where {order, dim, T, M} = new{order, dim, T, M}(data)
    Tensor{order, dim, T, M}(f::Function) where {order, dim, T, M} = new{order, dim, T, M}(NTuple{M, T}(ntuple(f, Val{M})))
end

###############
# Typealiases #
###############
const Vec{dim, T, M} = Tensor{1, dim, T, dim}

const AllTensors{dim, T} = Union{SymmetricTensor{2, dim, T}, Tensor{2, dim, T},
                                 SymmetricTensor{4, dim, T}, Tensor{4, dim, T},
                                 Vec{dim, T}}


const SecondOrderTensor{dim, T}   = Union{SymmetricTensor{2, dim, T}, Tensor{2, dim, T}}
const FourthOrderTensor{dim, T}   = Union{SymmetricTensor{4, dim, T}, Tensor{4, dim, T}}
const SymmetricTensors{dim, T}    = Union{SymmetricTensor{2, dim, T}, SymmetricTensor{4, dim, T}}
const NonSymmetricTensors{dim, T} = Union{Tensor{2, dim, T}, Tensor{4, dim, T}, Vec{dim, T}}


##############################
# Utility/Accessor Functions #
##############################
get_data(t::AbstractTensor) = t.data

@pure n_components(::Type{SymmetricTensor{2, dim}}) where {dim} = dim*dim - div((dim-1)*dim, 2)
@pure function n_components(::Type{SymmetricTensor{4, dim}}) where {dim}
    n = n_components(SymmetricTensor{2, dim})
    return n*n
end
@pure n_components(::Type{Tensor{order, dim}}) where {order, dim} = dim^order

@pure get_type(::Type{Type{X}}) where {X} = X

@pure get_base(::Type{<:Tensor{order, dim}})          where {order, dim} = Tensor{order, dim}
@pure get_base(::Type{<:SymmetricTensor{order, dim}}) where {order, dim} = SymmetricTensor{order, dim}

@pure Base.eltype(::Type{Tensor{order, dim, T, M}})          where {order, dim, T, M} = T
@pure Base.eltype(::Type{Tensor{order, dim, T}})             where {order, dim, T}    = T
@pure Base.eltype(::Type{Tensor{order, dim}})                where {order, dim}       = Any
@pure Base.eltype(::Type{SymmetricTensor{order, dim, T, M}}) where {order, dim, T, M} = T
@pure Base.eltype(::Type{SymmetricTensor{order, dim, T}})    where {order, dim, T}    = T
@pure Base.eltype(::Type{SymmetricTensor{order, dim}})       where {order, dim}       = Any


############################
# Abstract Array interface #
############################
Base.IndexStyle(::Type{<:SymmetricTensor}) = IndexCartesian()
Base.IndexStyle(::Type{<:Tensor}) = IndexLinear()

########
# Size #
########
Base.size(::Vec{dim})               where {dim} = (dim,)
Base.size(::SecondOrderTensor{dim}) where {dim} = (dim, dim)
Base.size(::FourthOrderTensor{dim}) where {dim} = (dim, dim, dim, dim)

#########################
# Internal constructors #
#########################
for TensorType in (SymmetricTensor, Tensor)
    for order in (2, 4), dim in (1, 2, 3)
        N = n_components(TensorType{order, dim})
        @eval begin
            @inline $TensorType{$order, $dim}(t::NTuple{$N, T}) where {T} = $TensorType{$order, $dim, T, $N}(t)
            @inline $TensorType{$order, $dim, T1}(t::NTuple{$N, T2}) where {T1, T2} = $TensorType{$order, $dim, T1, $N}(t)
        end
    end
    if TensorType == Tensor
        for dim in (1, 2, 3)
            @eval @inline Tensor{1, $dim}(t::NTuple{$dim, T}) where {T} = Tensor{1, $dim, T, $dim}(t)
        end
    end
end
# Special for Vec
@inline Vec{dim}(data) where {dim} = Tensor{1, dim}(data)

# General fallbacks
@inline          Tensor{order, dim, T}(data::Union{AbstractArray, Tuple, Function}) where {order, dim, T} = convert(Tensor{order, dim, T}, Tensor{order, dim}(data))
@inline SymmetricTensor{order, dim, T}(data::Union{AbstractArray, Tuple, Function}) where {order, dim, T} = convert(SymmetricTensor{order, dim, T}, SymmetricTensor{order, dim}(data))
# @inline          Tensor{order, dim, T, M}(data::Union{AbstractArray, Tuple, Function})  where {order, dim, T, M} = Tensor{order, dim, T}(data)
# @inline SymmetricTensor{order, dim, T, M}(data::Union{AbstractArray, Tuple, Function})  where {order, dim, T, M} = SymmetricTensor{order, dim, T}(data)


using Boot

Boot.include_folder(Tensors, @__FILE__)

end # module
