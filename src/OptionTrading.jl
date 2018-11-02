module OptionTrading

using Dates
using BusinessDays
using Commas

function thirdfriday( date::Date, n::Int )
    fdom = Dates.firstdayofmonth( date )
    result = fdom + Dates.Day(mod(Dates.Friday - Dates.dayofweek(fdom), 7) + (n-1)*7)
    # 04/18/2014 is a NYSE holiday but not a CBOE expiration date
    if isholiday( :USNYSE, result ) && result != Date( 2014, 4, 18 )
        result = advancebdays( :USNYSE, result, -1 )
    end
    return result
end

function monthlyexpiration( date::Date )
    friday = thirdfriday( date, 3 )
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

optiontype = Dict{String,Symbol}()
for (t, roots) in optionsoftype
    for root in roots
        optiontype[root] = t
    end
end

function expiration( root::String, expiration::Date )
    ot = optiontype[root]
    if ot == :monthly
        return DateTime( thirdfriday( expiration ), Time(9, 30) )
    else
        error( "Don't know expiration date and time for option type $ot" )
    end
end

end # module