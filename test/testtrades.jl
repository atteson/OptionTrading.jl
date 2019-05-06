using Commas
using Dates
using OptionTrading

date = Date( 2004, 7, 2 )
(year, month, day) = Dates.format.( date, ["yyyy","mm","dd"] )
expiration = OptionTrading.nextexpiration( date, Month )
expirationstring = Dates.format( expiration, "yyyymmdd" )

datadir = joinpath( homedir(), "data", "options" )
filename = joinpath( datadir, year, month, day, "SPX_$expirationstring" )

data = Commas.readcomma( filename )

ft = data[data.ticker.==(data.ticker[1],), [:time,:qort,:bid,:bidsize,:ask,:asksize]]

ticker = data[data[:qort].!=((UInt8('Q'),),),[:ticker]][:ticker][1]

data[data[:ticker].==(ticker,),[:time,:qort,:bid,:bidsize,:ask,:asksize]]


