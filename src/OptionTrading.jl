module OptionTrading

function monthlyexpiration( date::Date )
    fdom = Dates.firstdayofmonth( date )
    thirdfriday = fdom + Dates.Day(mod(Dates.Friday - Dates.dayofweek(fdom), 7) + 14)
    # 04/18/2014 is a NYSE holiday but not a CBOE expiration date
    if isholiday( :USNYSE, thirdfriday ) && thirdfriday != Date( 2014, 4, 18 )
        thirdfriday = advancebdays( :USNYSE, thirdfriday, -1 )
    end
    increment = Dates.Day(1)
    # as per CBOE regulatory circular RG13-118
    if thirdfriday >= Date( 2015, 2, 1 ) && thirdfriday != Date( 2015, 12, 18 )
        increment = Dates.Day(0)
    end
    return thirdfriday + increment
end

const calcexpirations = Dict(
    Dates.Month => monthlyexpiration,
)

function nextexpiration{T <: Dates.DatePeriod}( date::Date, period::Type{T} )
    calculator = calcexpirations[period]
    expiration = calculator( date )
    if date + Dates.Day(!isbday(:USNYSE,expiration)) >= expiration
        expiration = calculator( date + period(1) )
    end
    return expiration
end

end # module
