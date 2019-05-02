using OptionTrading
import OptionTrading: DateDict
using Dates
using BusinessDays
using Commas
using Printf

const optiondir = joinpath( homedir(), "data", "TickData", "Processed" )

optiontype = Dict{OptionTrading.roottype, Symbol}()
settlementcache = Dict{OptionTrading.roottype, DateDict{Date,DateTime}}()

lastbday = nothing
bday = nothing
for year in sort(readdir(optiondir))
    global yeardir = joinpath( optiondir, year )
    for month in sort(readdir(yeardir))
        global monthdir = joinpath( yeardir, month )
        for month in sort(readdir(yeardir))
            monthdir = joinpath( yeardir, month )
            for day in readdir(monthdir)
                global daydir = joinpath( monthdir, day )
                
                global bday = Date( parse.(Int,(year, month, day))... )
                if lastbday != nothing
                    @assert( advancebdays( :USNYSE, lastbday, 1 ) == bday )
                end
                global lastbday = bday
            end
        end
    end
end
