library(RPostgreSQL)
library(data.table)

nb_curves_per_request <- 5     # curves per (insert) request
#tot_nb_curves <- 25e3           # total number of curves
#dimension <- 17519              # number of sample points
#nb_clust <- 15                  # number of clusters
temp_file <- "tmp_curves_batch" # (accessible) temporary file to store curves

# Init connection with DB
driver <- PostgreSQL(fetch.default.rec = nb_curves_per_request)
con    <- dbConnect(driver, user = "irsdi", password = "irsdi2017",
                    host = "localhost", port = "5432", dbname = "edf25m")

setwd("~/tmp/")
ref_centroids <- fread("2009_matrix-dt.csv")
#ref_centroids <- sapply(1:nb_clust, function(k) cumsum(rnorm(dimension)))

genRandCurves <- function(line, times) {
	#ids   <- as.integer(sprintf("%04i", seq_len(times) - 1)) * 1e6 + line[1]
	ids   <- as.integer(sprintf("%010i", (seq_len(times) - 1) * 1e6 + line[1]))
	curve <- as.matrix(line[-1])
	#  simus <- lapply(1:times, function(i) line[-1] * runif(length(curve), .95, 1.05))
	perturbances <- matrix(runif(length(curve) * times, .95, 1.05), nrow = times)
	#curves_sim   <- cbind(ids, t(apply(perturbances, 1, FUN = '*', curve)))
	curves_sim   <- data.frame(ids, t(apply(perturbances, 1, FUN = '*', curve)))
	# series in columns, data as data.frame (as fwrite requests)
	return(curves_sim)
}

# Loop: generate nb_curves_per_request curves, store them on a temp file,
# and insert into DB using COPY command (should be faster than insert)
system.time(
    for (i in seq_len(nrow(ref_centroids))) {
			curves <- genRandCurves(line = as.matrix(ref_centroids[i, ]), times = nb_curves_per_request)
			fwrite(curves, temp_file, append = FALSE, sep = ",", col.names = FALSE)
			# Required hack: add brackets (PostgreSQL syntax ...)
			system(paste("sed -i 's/\\(.*\\)/{\\1}/g' ", temp_file, sep = ''))
			query <- paste("COPY series (curve) FROM '", normalizePath(temp_file), "';", sep = '')
			dbSendQuery(con, query) 
	  }
)

dbDisconnect(con)
unlink(temp_file)
