require(RPostgreSQL)
require(data.table)

nb_curves_per_request <- 100 #curves per (insert) request
tot_nb_curves <- 25e3 #total number of curves
dimension <- 15000 #number of sample points
nb_clust <- 15 #number of clusters
temp_file <- "tmp_curves_batch" #(accessible) temporary file to store curves

# Init connection with DB
driver <- PostgreSQL(fetch.default.rec = nb_curves_per_request)
con <- dbConnect(driver, user="user", password="pwd",
	host="localhost", port="5432", dbname="db")

# Replace next call + func with any custom initialization
ref_centroids <- sapply(1:nb_clust, function(k) cumsum(rnorm(dimension)))
genRandCurves <- function(indices) {
	mat <- sapply(indices, function(i) {
		if (i > tot_nb_curves)
			return (NULL)
		j <- sample(ncol(ref_centroids), 1)
		ref_centroids[,j] + rnorm(dimension)
	})
	# fwrite() write per columns => need to "transpose" mat; but it's quite inefficient...
	lapply(1:dimension, function(i) mat[i,])
}

# Loop: generate nb_curves_per_request curves, store them on a temp file,
# and insert into DB using COPY command (should be faster than insert)
nb_curves <- 0
while (nb_curves < tot_nb_curves)
{
	curves <- genRandCurves((nb_curves+1):(nb_curves+nb_curves_per_request))
	fwrite(curves, temp_file, append=FALSE, sep=",")
	# Required hack: add brackets (PostgreSQL syntax ...)
	system(paste("sed -i 's/\\(.*\\)/{\\1}/g' ",temp_file,sep=''))
	query <- paste("COPY series (curve) FROM '", normalizePath(temp_file), "';", sep='')
	dbSendQuery(con, query)
	nb_curves <- nb_curves + nb_curves_per_request
}

dbDisconnect(con)
unlink(temp_file)
