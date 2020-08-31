library(lubridate)
library(tidyverse)

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
  mutate(
    # use lubridate to get hours, minutes and seconds
    # from the time_of_day column which is formatted as HH:MM:SS
    time_of_day = lubridate::parse_date_time(time_of_day, orders = "HMS")
    ) %>%
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
  # used later to calculate plays of rest
  mutate(play_no = 1 : n()) %>%
  # let's only look at plays with downs 1-4 (i.e., no kickoffs, PATs, etc)
  filter(!is.na(down)) %>%
  ungroup()

# initialize dates in time_of_day with game_date
# this step is necessary because time_of_day is in UTC time
# which means games often last into the following day
# so we will also be working with the date of the game
month(pbp$time_of_day) <- month(pbp$game_date)
year(pbp$time_of_day) <- year(pbp$game_date)
day(pbp$time_of_day) <- day(pbp$game_date)

pbp <- pbp %>%
  mutate(
    time_of_day = if_else(
      # roll over to next day if it's early morning UTC time
      hour(time_of_day) <= 12, time_of_day + ddays(1), time_of_day
      ),
    # display timezone as ET
    time_of_day = with_tz(time_of_day, "America/New_YOrk")
  )

drives <- pbp %>%
  # first, collapse everything down to the drive level
  group_by(game_id, fixed_drive) %>%
  summarise(
    qtr = dplyr::first(na.omit(qtr)),
    posteam = dplyr::first(posteam),
    defteam = dplyr::first(defteam),
    point_diff = dplyr::first(na.omit(score_differential)),
    start_time = dplyr::first(na.omit(time_of_day)),
    end_time = dplyr::last(na.omit(time_of_day)),
    start_play = dplyr::first(na.omit(play_no)),
    end_play = dplyr::last(na.omit(play_no)),
    yardline_100 = dplyr::first(na.omit(yardline_100)),
    game_seconds_remaining = dplyr::first(na.omit(game_seconds_remaining)),
    half_seconds_remaining = dplyr::first(na.omit(half_seconds_remaining)),
    drive_plays = n(),
    drive_result = dplyr::first(fixed_drive_result),
    # if the drive begins and ends with a kneel, it's a "kneel drive"
    # we will throw these drives out later
    kneel_drive = if_else(dplyr::first(qb_kneel) == 1 & dplyr::last(qb_kneel), 1, 0)
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
    half = if_else(qtr > 2, "2nd", "1st"),

    # will be used for grouping plays in one of the figures
    quarter = if_else(qtr == 3 & dplyr::lag(qtr) == 2, "1st 3rd Q drive", "Other"),

    # Rest is the difference between the start time of the current drive
    # and the end time of the previous time the defense was on the field
    rest = as.numeric(start_time - dplyr::lag(end_time), units = "hours"),

    # Same idea for rest plays
    rest_plays = start_play - dplyr::lag(end_play) - 1,

    # Length of given drive
    drive_length = as.numeric(end_time - start_time, units = "hours"),

    # Total number of time defense has spent on the field up to beginning of drive
    # (need to subtract current drive because it hasn't happened yet when drive starts)
    cum_time_on_field = cumsum(replace_na(drive_length, 0)) - replace_na(drive_length, 0),

    # Same thing for plays
    cum_plays_on_field = cumsum(drive_plays) - drive_plays,

    # Get cumulative time spent resting
    cum_rest = cumsum(replace_na(rest, 0)),
    cum_rest_plays = cumsum(replace_na(rest_plays, 0)),

    # Convert drive result to points
    drive_points = case_when(
      drive_result == "Touchdown" ~ 7,
      drive_result == "Field goal" ~ 3,
      TRUE ~ 0
    )
  ) %>%
  ungroup() %>%
  filter(kneel_drive == 0) %>%
  select(
    game_id, fixed_drive, start_time, end_time, half, quarter, point_diff,
    posteam, defteam, yardline_100, game_seconds_remaining, half_seconds_remaining, rest, rest_plays,
    cum_time_on_field, cum_plays_on_field, drive_points, prior_drive_result,
    cum_rest, cum_rest_plays
  )

saveRDS(drives, '_posts/2020-08-25-defense-and-rest-time-re-visited/data.rds')


