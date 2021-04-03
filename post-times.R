#!/usr/bin/env Rscript

library(tidyverse)
library(lubridate)

# RR post times are a good proxy for actual post times, as they are never updated
# and have hour and minute granularity unlike WP.
rr_times <- list.files("websites/royalroad.com") %>% basename() %>% as_datetime()

summed <- tibble(time = rr_times, wday = wday(time), hour = hour(time)) %>% group_by(wday, hour) %>% summarise(n = n())

ggplot(filter(summed, n > 2), aes(x = hour, y = wday, fill = n)) + geom_raster()

# Post times are typically on weekdays 3 and 7 (0, 6 in cron notation) between hours 4 and 22.
