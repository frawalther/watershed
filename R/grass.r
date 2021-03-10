#' Start grass in a simple way
#'
#' @param layer A [raster::raster] object to write to the grass session
#' @param layer_name Name of the layer in the grass environment
#' @param gisBase character; the location of the GRASS installation
#' @param home Location to write GRASS settings
#' @param gisDbase Location to write GRASS GIS datasets
#' @param location Grass location name
#' @param mapset Grass mapset name
#' @keywords internal
.start_grass = function(layer, layer_name, gisBase, home = tempdir(), gisDbase = home,
						location = 'watershed', mapset = 'PERMANENT') {
	rgrass7::initGRASS(gisBase, home=home, gisDbase = gisDbase, location = location, 
					   mapset = mapset, override = TRUE)	
	err = rgrass7::execGRASS("g.proj", flags = "c", proj4 = sp::proj4string(layer), intern=TRUE)
	ext = as.character(as.vector(raster::extent(layer)))
	rasres = as.character(raster::res(layer))	
	rgrass7::execGRASS("g.region", n = ext[4], s = ext[3], e = ext[2], w = ext[1], 
					   rows=raster::nrow(layer), cols=raster::ncol(layer), nsres = rasres[2], 
					   ewres = rasres[1])
	.add_raster(layer, layer_name)
}

#' Add a raster to grass
#' @param x A [raster::RasterLayer] or [sp::SpatialPixelsDataFrame]
#' @param name The name of the layer in grass
#' @param overwrite Should the file be overwritten if it exists
#' @keywords internal
.add_raster = function(x, name, overwrite = TRUE) {
	if("RasterLayer" %in% class(x))
		x = .raster_to_spdf(x)
	if(overwrite)
		flags = c(flags, "overwrite")
	rgrass7::writeRAST(x, layerName, flags = flags)
	ws_env$rasters = c(ws_env$rasters, layerName)
}


#' Produce a [sp::SpatialPixelsDataFrame] from a [raster::RasterLayer]
#'
#' @param x A [raster::RasterLayer] object
#' @param complete.cases Boolean, if TRUE only complete (non-na) rows are returned
#' @return A [sp::SpatialPixelsDataFrame]
#' @keywords internal
.raster_to_spdf = function(x, complete.cases=FALSE)
{
	coords = sp::coordinates(x)
	gr = data.frame(cbind(coords, raster::values(x)))
	if(complete.cases)
		gr = gr[complete.cases(gr),]
	sp::coordinates(gr) = c(1,2)
	sp::proj4string(gr) = sp::proj4string(x)
	sp::gridded(gr) = TRUE
	return(gr)
}


#' Try to locate a user's GRASS GIS installation
#' 
#' Locates a grass installation in common locations on Mac, Windows, and Linux. This is normally
#' run automatically when the package is loaded. If multiple
#' installations are present, the function will prefer 7.6, 7.4, and then whatever is most recent.
#' 
#' In some (many?) cases, this function will fail to find a grass installation, or users may wish
#' to specify a different version than what is detected automatically. In these cases, it is possible
#' to manually specify the grass location using `options(gisBase = "path/to/grass")`.
#' 
#' @return The path to the user's grass location, or NULL if not found 
#' @export
find_grass = function() {
	os = Sys.info()['sysname']
	gisBase = NULL
	
	if(grepl("[Ll]inux", os)) {
		## try a system call
		gisBase = sapply(c("grass76", "grass74", "grass78"), function(gr) {
			tryCatch(system2(gr, args = c("--config", "path"), stdout = TRUE, stderr = TRUE),
					 error = function(e) NA)
		})
		# take the first (most preferred) non-na
		gisBase = gisBase[!is.na(gisBase)][1]
	} else {
		if(grepl("[Dd]arwin", os)) {
			appPath = "/Applications"
			suffix = "Contents/Resources"
		} else if(grepl("[Ww]indows", os)) {
			## currently supports the OSGEO4W64 installation
			appPath = file.path("C:", "OSGEO4W64", "apps", "grass")
			suffix = NA
		}
		grassBase = list.files(appPath, pattern='grass', ignore.case = TRUE)
		grassBase = .preferred_grass_version(grassBase)
		gisBase = ifelse(is.na(suffix), file.path(appPath, grassBase), file.path(appPath, grassBase, suffix))
	}
	return(gisBase)
}

#' Choose a preferred version of grass from a list of options
#' @param x A vector of grass home directories
#' @value The most preferred from x
#' @keywords internal
.preferred_grass_version = function(x) {
	gVersion = as.numeric(sub(".*(7)\\.?([0-9]).*(\\.app)?", "\\1\\2", grassBase))
	if(76 %in% gVersion) {
		res = x[gVersion == 76]
	} else if(74 %in% gVersion) {
		res = x[gVersion == 74]
	} else {
		res = x[which.max(gVersion)]
	}
	res
}
