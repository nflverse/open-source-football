# Read in data
pbp <- map_df(2015 : 2019, ~{
  readRDS(
    url(
      glue::glue("https://raw.githubusercontent.com/guga31bb/nflfastR-data/master/data/play_by_play_{.}.rds")
    )
  ) %>%
    # just keep real plays
    filter(!is.na(posteam))
}) %>%
  mutate(time_of_day = lubridate::parse_date_time(time_of_day, orders = "HMS")) %>%
  filter(
    # delays in middle of drive messes everything up
    !game_id %in% c("2018_01_TEN_MIA", "2017_02_DAL_DEN", "2017_04_CHI_GB", "2016_04_DEN_TB", "2016_03_LA_TB"),
    # drive 9 jumps ahead a lot of hours for no reason
    game_id != "2015_12_BAL_CLE",
    # idk these are messed up for some reason
    game_id != "2017_11_JAX_CLE",
    game_id != "2015_15_NYJ_DAL",
    game_id != "2017_02_CLE_BAL",
    game_id != "2015_03_CIN_BAL",
    game_id != '2016_06_IND_HOU'
  ) %>%
  group_by(game_id) %>%
  mutate(play_no = 1 : n()) %>%
  filter(!is.na(down)) %>%
  ungroup()

# initialize dates in time_of_day with game_date
month(pbp$time_of_day) <- month(pbp$game_date)
year(pbp$time_of_day) <- year(pbp$game_date)
day(pbp$time_of_day) <- day(pbp$game_date)


# roll over to next day if it's early morning UTC time
pbp <- pbp %>%
  mutate(time_of_day = if_else(
    hour(time_of_day) <= 12, time_of_day + ddays(1), time_of_day
    ),
  time_of_day = with_tz(time_of_day, "America/New_YOrk")
  )

drives <- pbp %>%
  group_by(game_id, fixed_drive) %>%
  summarise(
    posteam = dplyr::first(posteam),
    defteam = dplyr::first(defteam),
    start_time = dplyr::first(na.omit(time_of_day)),
    end_time = dplyr::last(na.omit(time_of_day)),
    start_play = dplyr::first(na.omit(play_no)),
    end_play = dplyr::last(na.omit(play_no)),
    yardline_100 = dplyr::first(na.omit(yardline_100)),
    game_seconds_remaining = dplyr::first(na.omit(game_seconds_remaining)),
    drive_plays = n(),
    drive_result = dplyr::first(fixed_drive_result)
  ) %>%
  ungroup() %>%
  group_by(game_id) %>%
  mutate(
    prior_drive_result = dplyr::lag(drive_result)
  ) %>%
  ungroup() %>%
  arrange(
    game_id, defteam, fixed_drive
  ) %>%
  group_by(
    game_id, defteam
  ) %>%
  mutate(
    rest = as.numeric(start_time - dplyr::lag(end_time), units = "hours"),
    rest_plays = start_play - dplyr::lag(end_play) - 1,
    drive_length = as.numeric(end_time - start_time, units = "hours"),
    cum_time_on_field = cumsum(replace_na(drive_length, 0)) - replace_na(drive_length, 0),
    cum_plays_on_field = cumsum(drive_plays) - drive_plays,
    drive_points = case_when(
      drive_result == "Touchdown" ~ 7,
      drive_result == "Field goal" ~ 3,
      TRUE ~ 0
    )
  ) %>%
  ungroup() %>%
  select(
    game_id, fixed_drive, start_time, end_time,
    posteam, defteam, yardline_100, game_seconds_remaining, rest, rest_plays,
    cum_time_on_field, cum_plays_on_field, drive_points, prior_drive_result
  ) %>%
  # this doesn't really tell us what we want
  filter(prior_drive_result != "Opp touchdown")

saveRDS(drives, '_posts/2020-08-25-defense-and-rest-time-re-visited/data.rds')


drives %>%
  ggplot(aes(yardline_100, drive_points)) +
  geom_jitter(alpha = .1, size = 1, height = .25, width = 0) +
  theme_stata(scheme = "sj", base_size = 12) +
  labs(x = "Distance from end zone",
       y = "Points on drive",
       caption = "Figure: @benbbaldwin | Data: @nflfastR",
       title = 'Points vs field position') +
  theme(
    plot.title = element_text(face = 'bold'),
    plot.caption = element_text(hjust = 1),
    axis.text.y = element_text(angle = 0, vjust = 0.5),
    aspect.ratio = 1/1.618
  ) +
  geom_smooth()


model1 <- gam(drive_points ~ s(yardline_100) + s(rest), data=drives)
plot(model1)

model2 <- gam(drive_points ~ s(yardline_100), data=drives)


drives$points_hat <- predict.gam(model2, drives)
drives$points_over_expected <- drives$drive_points - drives$points_hat


# rest vs points
drives %>%
  mutate(rest = rest * 60) %>%
  ggplot(aes(rest, points_over_expected)) +
  # geom_point(alpha = .1, size = 1) +
  theme_bw() +
  labs(x = "Rest time (minutes)",
       y = "Points over expected",
       caption = "Figure: @benbbaldwin | Data: @nflfastR",
       title = 'Points over expected vs rest time') +
  theme(
    plot.title = element_text(face = 'bold'),
    plot.caption = element_text(hjust = 1),
    axis.text.y = element_text(angle = 0, vjust = 0.5),
    aspect.ratio = 1/1.618
  ) +
  theme_stata(scheme = "sj", base_size = 12) +
  geom_smooth() +
  scale_x_continuous(breaks = scales::pretty_breaks(15))




drives %>%
  filter(cum_time_on_field < -8) %>%
  select(game_id, fixed_drive)

drives %>%
  select(fixed_drive, defteam, rest, drive_length) %>%
  mutate(
    # cum_rest = cumsum(replace_na(rest, 0)) - replace_na(rest, 0)
    cum_time_on_field = cumsum(drive_length) - drive_length
  )

drives %>%
  mutate(rest = round(rest, 0)) %>%
  select(rest) %>%
  group_by(rest) %>%
  summarise(n = n())

drives %>%
  filter(rest < 45) %>%
  ggplot(aes(x = rest)) +
  geom_histogram() +
  theme_stata(scheme = "sj", base_size = 12) +
  xlab("Minutes")


