#!/usr/bin/Rscript

# Take ImageJ output and format to table with labels and area in mm2 
library(dplyr)
library(purrr)
library(tibble)

# Change these to match your paths to the saved data and/or layout
imagej_out <- file.path('sample_data/ij.txt') # tsv from ImageJ
sample_details <- file.path("sample_data/samples.tsv")
discs_per_tank <- rep(48, 3)
output <- file.path('output/area.tsv')

# Import the data saved from imagej analysis
size_df <-read.table(
  imagej_out,
  sep="\t",
  header=F,
  stringsAsFactors = F,
  colClasses = c("character","character","numeric","numeric","integer"),
  col.names = c("no","pic","area","perc_area","slice")
) %>%
  mutate(
    tank = as.integer(substr(pic,nchar(pic),nchar(pic))),
    well = as.integer(unlist(accumulate2(
      slice[-1],  # ..2
      tank[-1],  # ..3
      .init = 1,  # this is the starting value for .x
      ~ if (..2 == 1 & .x == discs_per_tank[..3])
        {.x == 1; return(1)}
      else if (..2 == 1)
        {.x + 1}
      else
        { .x}
    ))),
    time = as.POSIXct(strptime(substr(pic,(nchar(pic)-20),(nchar(pic)-5)),format="%Y-%m-%d_%Hh%M")),
    area = area * (100-perc_area) / 100
  ) %>%
    select(tank, well, time, area)

# Import sample details
sample_list<-read.table(
  sample_details,
  sep="\t",
  header=T,
  stringsAsFactors = F,
  colClasses = c("integer","integer","character")
)

# Join the area and position details to the sample details
size_df <- size_df %>%
  left_join(sample_list, by=c('tank','well'))

write.table(size_df, output, sep='\t', row.names = F)



