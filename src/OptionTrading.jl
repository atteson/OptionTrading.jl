module OptionTrading

using Dates
using BusinessDays
using Commas

struct DateDict{K <: TimeType,V} <: AbstractDict{K,V}
    dict::Dict{Int,V}
end

DateDict{K, V}() where {K,V} = DateDict{K,V}( Dict{Int,V}() )

Base.haskey( dict::DateDict{K,V}, t::K ) where {K,V} =
    haskey( dict.dict, t.instant.periods.value )

Base.getindex( dict::DateDict{K,V}, t::K ) where {K,V} =
    getindex( dict.dict, t.instant.periods.value )

Base.setindex!( dict::DateDict{K,V}, value::V, t::K ) where {K,V} =
    setindex!( dict.dict, value, t.instant.periods.value )

Base.delete!( dict::DateDict{K,V}, t::K ) where {K,V} =
    delete!( dict.dict, t.instant.periods.value )

Base.length( dict::DateDict{K,V} ) where {K,V} = length( dict.dict )

periodtype( ::Type{Dates.UTInstant{P}} ) where {P <: Period} = P

fromint( ::Type{D}, i::Int ) where {D <: TimeType} =
    D( Dates.UTInstant( periodtype( fieldtypes(D)[1] )( i ) ) )

function Base.iterate( dict::DateDict{K,V}, s = 0 ) where {K,V}
    result = iterate( dict.dict, s )
    result == nothing && return result
    ((k, v), s) = result
    return (fromint( K, k ) => v, s )
end

Base.show( io::IO, dict::DateDict{K,V} ) where {K,V} = show( io, dict.dict )

function Base.get( d::Dict{K,V}, k::K ) where {K,V}
    if !haskey( d, k )
        d[k] = V()
    end
    return d[k]
end

function thirdfriday( date::Date )
    fdom = Dates.firstdayofmonth( date )
    result = fdom + Dates.Day(mod(Dates.Friday - Dates.dayofweek(fdom), 7) + 14)
    # 04/18/2014 is a NYSE holiday but not a CBOE expiration date
    if isholiday( :USNYSE, result ) && result != Date( 2014, 4, 18 )
        result = advancebdays( :USNYSE, result, -1 )
    end
    return result
end

function monthlyexpiration( date::Date )
    friday = thirdfriday( date )
    increment = Dates.Day(1)
    # as per CBOE regulatory circular RG13-118
    if friday >= Date( 2015, 2, 1 ) && friday != Date( 2015, 12, 18 )
        increment = Dates.Day(0)
    end
    return friday + increment
end

const calcexpirations = Dict(
    Dates.Month => monthlyexpiration,
)

function nextexpiration( date::Date, period::Type{T} ) where {T <: Dates.DatePeriod}
    calculator = calcexpirations[period]
    expiration = calculator( date )
    if date + Dates.Day(!isbday(:USNYSE,expiration)) >= expiration
        expiration = calculator( date + period(1) )
    end
    return expiration
end

optionsoftype = Dict(
    :monthly => ["SYF", "SYG", "SVP", "SZU", "SXZ", "SXM", "SZP", "SYU", "SXB", "SPV", "SPT", "SYV", "SPZ", "SPQ", "SPX", "SPB", "SXY",],
    :weekly => ["JXA", "JXB", "SPXW",],
    :pm => ["SPXPM",],
    :variancestrip => ["VSTRP",],
    :rangeoption => ["SRO",],
    :quarterly => ["QSE","QZQ","QSZ","SAQ","SLQ","SZQ","SKQ","SQP","SQG",],
    :binary => ["BSZ","BSK","BSF",],
)

roottype = CharN{5}
const optiontype = Dict{roottype,Symbol}()
for (t, roots) in optionsoftype
    for root in roots
        optiontype[roottype( rpad( root, sizeof(roottype) ) )] = t
    end
end

# returns when the settlement value is determined
function settlement( root::roottype, expiration::Date,  optiontype::Dict{roottype, Symbol}, settlementcache::Dict{roottype, DateDict{Date,DateTime}} )
    rootsettlementcache = get( settlementcache, root )

    if !haskey( rootsettlementcache, expiration )
        ot = optiontype[root]
        if ot == :monthly
            date = thirdfriday( expiration )
            if isholiday( :USNYSE, date )
                rootsettlementcache[expiration] = advancebdays( :USNYSE, date, -1 ) + Time(16, 00)
            else
                rootsettlementcache[expiration] = date + Time(9, 30)
            end
        else
            error( "Don't know expiration date and time for option type $ot" )
        end
    end
    result = rootsettlementcache[expiration]
    return result
end

end # module

