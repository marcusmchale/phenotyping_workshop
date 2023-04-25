# Take size and calculate lsgr
library(dplyr)
library(tidyr)
library(purrr)
library(broom)
library(ggplot2)

alpha <- 0.05
area_file <- file.path("sample_data/area.tsv")
sgr_filepath <- file.path('sample_data/sgr.tsv')

area <- read.table(
  area_file,
  sep="\t",
  header=T,
  stringsAsFactors = F,
  colClasses = c("integer","integer","character","numeric", "character")
) %>%
  mutate(time = as.POSIXct(time))

dir.create("sample_data/rgr_plots")
plot_rgr_fit <- function(s) {
  p <- ggplot(filter(area, sample==s), aes(x=time, y=log(area), colour=paste(tank,well))) +
     geom_point() +
     stat_smooth(method='lm')
  ggsave(paste0("sample_data/rgr_plots/", s, ".png"), p)
}
lapply(unique(area$sample), plot_rgr_fit)

rgr <- area %>%
  filter(area != 0) %>%
  mutate(days = difftime(time, min(time), units='days')) %>%
  nest(data = c(-tank, -well, -sample)) %>%
  mutate(
    fit = map(data, ~ lm(log(area) ~ days, data=.x)),
    tidied = map(fit, tidy)
  ) %>%
  unnest(tidied) %>%
  filter(term == 'days') %>%
  rename(rgr = estimate) %>%
  select(tank, well, sample, rgr, std.error) %>%
  mutate(tank = factor(tank, levels = c("1","2","3")))

# The rgr fit plots are very useful to identify any issues
# e.g. experimental, image capture or image analysis
# as a shortcut here, we are going to discard data from poorly fit models
rgr_se_density_p <- ggplot(rgr, aes(y=std.error)) +
  geom_density() +
  coord_flip()
ggsave("sample_data/rgr_se_density.png", rgr_se_density_p)

rgr_cutoff <- median(rgr$std.error) + 1.5*IQR(rgr$std.error)
good_rgr <- rgr %>%
  filter(std.error <= rgr_cutoff) %>%
  select(tank, well, sample, rgr, std.error)
good_rgr_se_density_p <- ggplot(good_rgr, aes(y=std.error)) +
  geom_density() +
  coord_flip()
ggsave("sample_data/good_rgr_se_density.png",good_rgr_se_density_p)

rgr_p <- ggplot(good_rgr, aes(x=sample, y=rgr)) +
  geom_boxplot() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
ggsave("sample_data/rgr_summary.png", rgr_p)

anova(lm(rgr ~ sample + tank, data = good_rgr))
rgr_summary <- good_rgr %>%
  group_by(sample) %>%
  summarise(rgr.mean = mean(rgr), sd = sd(rgr, na.rm = T), n = n())

write.table(rgr_summary, "sample_data/rgr_summary.tsv", sep="\t", row.names = F)