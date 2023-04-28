#!/usr/bin/Rscript

# Take size and calculate lsgr
library(dplyr)
library(tidyr)
library(purrr)
library(broom)
library(ggplot2)

alpha <- 0.05
area_file <- file.path("output/area.tsv")

area <- read.table(
  area_file,
  sep="\t",
  header=T,
  stringsAsFactors = F,
  colClasses = c("integer","integer","character","numeric", "character")
) %>%
  mutate(time = as.POSIXct(time)) %>%
  filter(
    #!(time < as.POSIXct("2023-04-26 13:00:00 ") & well %in% c(1,4))
    !time < as.POSIXct("2023-04-26 13:00:00 ")
  )

dir.create("output/rgr_plots")
plot_rgr_fit <- function(s) {
  p <- ggplot(filter(area, strain==s), aes(x=time, y=log(area), colour=paste(tank,well))) +
     geom_point() +
     stat_smooth(method='lm')
  ggsave(paste0("output/rgr_plots/", s, ".png"), p)
}
lapply(unique(area$strain), plot_rgr_fit)

rgr <- area %>%
  filter(area != 0) %>%
  mutate(days = difftime(time, min(time), units='days')) %>%
  nest(data = c(-tank, -well, -strain)) %>%
  mutate(
    fit = map(data, ~ lm(log(area) ~ days, data=.x)),
    tidied = map(fit, tidy)
  ) %>%
  unnest(tidied) %>%
  filter(term == 'days') %>%
  rename(rgr = estimate) %>%
  select(tank, well, strain, rgr, std.error) %>%
  mutate(tank = factor(tank, levels = c("1","2","3")))

# The rgr fit plots are very useful to identify any issues
# e.g. experimental, image capture or image analysis
# as a shortcut here, we are going to discard data from poorly fit models
rgr_se_density_p <- ggplot(rgr, aes(y=std.error)) +
  geom_density() +
  coord_flip()
ggsave("output/rgr_se_density.png", rgr_se_density_p)

rgr_cutoff <- median(rgr$std.error) + 1.5*IQR(rgr$std.error)
filtered_rgr <- rgr %>%
  filter(std.error <= rgr_cutoff) %>%
  select(tank, well, strain, rgr, std.error)
filtered_rgr_se_density_p <- ggplot(filtered_rgr, aes(y=std.error)) +
  geom_density() +
  coord_flip()
ggsave("output/filtered_rgr_se_density.png",filtered_rgr_se_density_p)

rgr_p <- ggplot(filtered_rgr, aes(x=strain, y=rgr)) +
  geom_boxplot() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
ggsave("output/rgr_summary.png", rgr_p)

anova(lm(rgr ~ strain + tank, data = filtered_rgr))
rgr_summary <- filtered_rgr %>%
  group_by(strain) %>%
  summarise(rgr.mean = mean(rgr), sd = sd(rgr, na.rm = T), n = n())

write.table(rgr_summary, "output/rgr_summary.tsv", sep="\t", row.names = F)
#!/usr/bin/Rscript

# Take size and calculate lsgr
library(dplyr)
library(tidyr)
library(purrr)
library(broom)
library(ggplot2)

alpha <- 0.05
area_file <- file.path("output/area.tsv")

area <- read.table(
  area_file,
  sep="\t",
  header=T,
  stringsAsFactors = F,
  colClasses = c("integer","integer","character","numeric", "character")
) %>%
  mutate(time = as.POSIXct(time))

dir.create("output/rgr_plots")
plot_rgr_fit <- function(s) {
  p <- ggplot(filter(area, strain==s), aes(x=time, y=log(area), colour=paste(tank,well))) +
     geom_point() +
     stat_smooth(method='lm')
  ggsave(paste0("output/rgr_plots/", s, ".png"), p)
}
lapply(unique(area$strain), plot_rgr_fit)

rgr <- area %>%
  filter(area != 0) %>%
  mutate(days = difftime(time, min(time), units='days')) %>%
  nest(data = c(-tank, -well, -strain)) %>%
  mutate(
    fit = map(data, ~ lm(log(area) ~ days, data=.x)),
    tidied = map(fit, tidy)
  ) %>%
  unnest(tidied) %>%
  filter(term == 'days') %>%
  rename(rgr = estimate) %>%
  select(tank, well, strain, rgr, std.error) %>%
  mutate(tank = factor(tank, levels = c("1","2","3")))

# The rgr fit plots are very useful to identify any issues
# e.g. experimental, image capture or image analysis
# as a shortcut here, we are going to discard data from poorly fit models
rgr_se_density_p <- ggplot(rgr, aes(y=std.error)) +
  geom_density() +
  coord_flip()
ggsave("output/rgr_se_density.png", rgr_se_density_p)

rgr_cutoff <- median(rgr$std.error) + 1.5*IQR(rgr$std.error)
filtered_rgr <- rgr %>%
  filter(std.error <= rgr_cutoff) %>%
  select(tank, well, strain, rgr, std.error)
filtered_rgr_se_density_p <- ggplot(filtered_rgr, aes(y=std.error)) +
  geom_density() +
  coord_flip()
ggsave("output/filtered_rgr_se_density.png",filtered_rgr_se_density_p)

rgr_p <- ggplot(filtered_rgr, aes(x=strain, y=rgr)) +
  geom_boxplot() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
ggsave("output/rgr_summary.png", rgr_p)

#anova(lm(rgr ~ strain + tank, data = filtered_rgr))
rgr_summary <- filtered_rgr %>%
  group_by(strain) %>%
  summarise(rgr.mean = mean(rgr), sd = sd(rgr, na.rm = T), n = n())

write.table(rgr_summary, "output/rgr_summary.tsv", sep="\t", row.names = F)

