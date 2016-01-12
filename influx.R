# load libs
library(xts)
library(influxdbr)
library(AnomalyDetection)
library(foreach)

test <- function() {
  con <- connectToHost("localhost", 8086, "root", "root")
  
  db = "icinga"
  measurement = "icinga.service.ntp_time.offset"
  checkAnomaliesForServiceHosts(con = con, db = db, measurement = measurement)
}

connectToHost <- function(host, port, user, pass, db) {
  con <- influxdbr::influx_connection(host = host,
                                      port = port,
                                      user = user,
                                      pass = pass)
}

getMeasurements <- function(con, db) {
  cat("Getting measurements", "\n")
  measurements <- influxdbr::show_measurements(con = con, db = db)
  return(measurements)
}

checkAnomaliesForService <- function(con, db, measurement, time, max_anom) {
  cat("Checking for anomalies in", measurement, "over the last", time, "\n")
  f = sprintf('\"%s\"', measurement)
  
  results <- influx_select(con = con, 
                           db = db, 
                           value = "mean(value)", 
                           from = f, 
                           where = paste("time > now() -", time),
                           group_by = "time(1h) fill(0)",
                           order_desc = TRUE,
                           return_xts = FALSE)
  res = AnomalyDetectionTs(results[[1]], max_anoms = max_anom, direction = 'both', plot = TRUE, title = measurement) 
#  res = AnomalyDetectionVec(na.approx(results[[1]][,2]), max_anoms = 0.02, period = 24, direction = 'both', plot = TRUE, title = measurement)
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
  returned_res <- checkAnomaliesForHost(results, returned_res, max_anoms)
  
  return(returned_res)
}

checkAnomaliesForHost <- function(results, returned_res, max_anoms) {
  if(length(results) == 0)
    return (returned_res)
  
  result = results[[1]]
  host = attr(result, "influx_tags")[[1]]
  title = sprintf('Anomalies detected for host = %s', host)
  res = AnomalyDetectionTs(result, direction = 'both', plot = TRUE, title = title, max_anoms = max_anoms) 
  
  anomCount = nrow(res$anoms)
  if(anomCount > 0) {
    cat(anomCount, 'anomalies detected for host =', host, '\n')
  }
  
  returned_res[[length(returned_res)+1]] <- res
  results[[1]] <- NULL
  
  checkAnomaliesForHost(results, returned_res, max_anoms)
}