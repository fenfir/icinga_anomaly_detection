# load libs
library(xts)
library(influxdbr)
library(AnomalyDetection)
library(foreach)

test <- function() {
  con <- connectToHost("localhost", 8086, "root", "root")
  
  db = "icinga"
  measurement = "icinga.service.ntp_time.offset"
  res <- checkAnomaliesForServiceHosts(con = con, db = db, time="30d", max_anom=0.02, measurement = measurement)
  i <- resultsToInflux(res)
}

connectToHost <- function(host, port, user, pass, db) {
  con <- influxdbr::influx_connection(host = host,
                                      port = port,
                                      user = user,
                                      pass = pass)
}

getMeasurements <- function(con, db) {
  cat("Getting measurements", "\n")
  measurements <- influxdbr::show_measurements(con = con, 
                                               db = db)
  return(measurements)
}

checkAnomaliesForService <- function(con, db, measurement, time, max_anom) {
  cat("Checking for anomalies in", measurement, "over the last", time, "\n")
  title = paste("service=", measurement, sep = "")
  f = sprintf('\"%s\"', measurement)
  
  results <- influx_select(con = con, 
                           db = db, 
                           value = "mean(value)", 
                           from = f, 
                           where = paste("time > now() -", time),
                           group_by = "time(1h) fill(0)",
                           order_desc = TRUE,
                           return_xts = FALSE)
  res = AnomalyDetectionTs(results[[1]], max_anoms = max_anom, direction = 'both', plot = TRUE, title = title) 
  anomCount = nrow(res$anoms)
  if(anomCount > 0) {
    cat(anomCount, 'anomalies detected\n')
  }
  
  return(res)
}

checkAnomaliesForServiceHosts <- function(con, db, measurement, time, max_anoms) {
  cat("Checking for anomalies in", measurement, "over the last", time, "\n")
  f = sprintf('"%s"', measurement)
  
  results <- influx_select(con = con, 
                           db = "icinga", 
                           value = "mean(value)", 
                           from = f, 
                           where = paste("time > now() -", time),
                           group_by = "host, time(1h) fill(0)",
                           order_desc = TRUE,
                           return_xts = FALSE)
  
  returned_res = list()
  returned_res <- checkAnomaliesForHost(results, returned_res, max_anoms, measurement)
  
  return(returned_res)
}

checkAnomaliesForHost <- function(results, returned_res, max_anoms, measurement) {
  if(length(results) == 0)
    return (returned_res)
  
  result = results[[1]]
  host = attr(result, "influx_tags")[[1]]
  title = paste("service=", measurement, ",host=", host, sep = "")
  res = AnomalyDetectionTs(result, direction = 'both', plot = TRUE, title = title, max_anoms = max_anoms) 
  
  anomCount = nrow(res$anoms)
  if(anomCount > 0) {
    cat(anomCount, 'anomalies detected for host =', host, '\n')
  }
  
  returned_res[[length(returned_res)+1]] <- res
  results[[1]] <- NULL
  
  checkAnomaliesForHost(results, returned_res, max_anoms, measurement)
}

resultsToInflux <- function(results) {
  if(length(results) == 0)
    return(list())
  
  influxD <- resultToInflux(results[[1]])
  results[[1]] <- NULL  
  
  return (c(influxD, resultsToInflux(results)))
}

resultToInflux <- function(res) {
  influx <- list()
  plot = res$plot
  result = res$anoms
  
  if(length(result) > 0) {
    for(i in 1:nrow(result)) {
      pos = regexpr(':', plot$labels$title)
      tags = substr(plot$labels$title, 0, pos - 2)
      values = paste("value=", result[i, "anoms"], ",text=Automatic\\ anomaly\\ detection", sep = "")
      timestamp = format(as.numeric(as.POSIXct(result[i, "timestamp"], origin="1970-01-01")) * 1000000, scientific=FALSE)
      line = paste("events.anomalies", tags, values, timestamp)
      
      influx[[i]] <- line
    }
  }
  
  return(influx)
}