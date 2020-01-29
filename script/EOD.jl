using Commas
using Dates

const datadir = "/home/atteson/data/options"

function processday( data, t )
    indices = [Dict{Float64,Int}(), Dict{Float64,Int}()]
    for i = 1:length(data.time)
        if data.time[i] <= t && data.qort[i] == CharN('Q')
            indices[(data.porc[i]==CharN('P'))+1][data.strike[i]] = i
        end
    end

    n = sum(length.(indices))
    
    bid = fill( NaN32, n )
    ask = fill( NaN32, n )
    bidsize = fill( 0, n )
    asksize = fill( 0, n )
    put = falses( n )
    expiration = fill( data.expiration[1], n )
    time = fill( Time(0), n )
    
    j = 1
    for i = 1:2
        for (strike,index) in indices[i]
            bid[j] = data.bid[index]
            ask[j] = data.ask[index]
            bidsize[j] = data.bidsize[index]
            asksize[j] = data.asksize[index]
            put[j] = i==2
            time[j] = data.time[index]
            
            j += 1
        end
    end
    return (bid=bid, ask=ask, bidsize=bidsize, asksize=asksize, put=put, expiration=expiration, time=time)
end

function updatedata()
    outdir = joinpath( datadir, "options_16:00" )
    if isdir( outdir )
        results = Commas.readcomma( outdir )
    else
        results = nothing
    end
    for year in readdir( datadir )
        yearpath = joinpath( datadir, year )
        for month in readdir( yearpath )
            monthpath = joinpath( yearpath, month )
            for day in readdir( monthpath )
                daypath = joinpath( monthpath, day )
                println( "Processing $year$month$day at $(now())" )
                for option in readdir( daypath )
                    data = Commas.readcomma( joinpath( daypath, option ) )
                    if results == nothing
                        results = processday( data, Time(16) )
                    else
                        results = vcat( results, processday( data, Time(16) ) )
                    end
                end
                Commas.writecomma( outdir, results )
                results = Commas.readcomma( outdir )
            end
        end
    end
end

updatedata()
