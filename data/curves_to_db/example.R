require(RPostgreSQL)

##############################
# Follow steps in README first
##############################

nb_curves_per_request <- 100 #curves per (select) request

# Init connection with DB
driver <- PostgreSQL(fetch.default.rec = nb_curves_per_request)
con <- dbConnect(driver, user="irsdi", password="irsdi2017",
	host="localhost", port="5432", dbname="edf25m")

# Fill associative array, map index to identifier
indexToID_inDB <- as.character(
	dbGetQuery(con, 'SELECT DISTINCT id FROM series')[,"id"] )

# Function to retrieve curves within some indices range
getCurves <- function(indices)
{
	indices = indices[ indices <= length(indexToID_inDB) ]
	if (length(indices) == 0)
		return (NULL)
	request <- "SELECT curve FROM series WHERE id in ("
	for (i in seq_along(indices))
	{
		request <- paste(request, indexToID_inDB[ indices[i] ],  sep="")
		if (i < length(indices))
			request <- paste(request, ",", sep="")
	}
	request <- paste(request, ")", sep="")
	df_series <- dbGetQuery(con, request)

#weird result: an integer, and then string "{val1,val2,val3,...,valD}" :/
#print(summary(df_series))
df_series
#	matrix(df_series[,"value"], ncol=length(indices))
}

# Test
#curves <- getCurves(c(1:3,7,11))
library(epclust)
res <- claws(getCurves, 50, 15, 500, 500, random=FALSE, ncores_clust=3, verbose=TRUE)

dbDisconnect(con)
unlink(temp_file)
