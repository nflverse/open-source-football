library(tidyverse)

games <- readRDS(url("http://www.habitatring.com/games.rds")) %>%
  filter(game_type == 'REG', season <= 2019) %>%
  select(season, week, home_team, away_team, result)

home <- games %>%
  rename(team = home_team) %>%
  group_by(team, season) %>%
  summarize(home_diff = mean(result)) %>%
  ungroup()

away <- games %>%
  rename(team = away_team) %>%
  mutate(result = -result) %>%
  group_by(team, season) %>%
  summarize(away_diff = mean(result))

data <- home %>%
  left_join(away, by = c('team', 'season')) %>%
  mutate(
    team = case_when(
      team == 'OAK' ~ 'LV',
      team == 'SD' ~ 'LAC',
      team == 'STL' ~ 'LA',
      TRUE ~ team
    ),
    home_adv =
      (home_diff - away_diff) / 2
  ) %>%
  left_join(nflfastR::teams_colors_logos, by = c('team' = 'team_abbr'))

league_data <- home %>%
  left_join(away, by = c('team', 'season')) %>%
  mutate(
    home_adv =
      (home_diff - away_diff) / 2
  ) %>%
  group_by(season) %>%
  summarize(home_adv = mean(home_adv)) %>%
  ungroup() %>%
  mutate(team = 'League Avg')

data %>%
  bind_rows(league_data) %>%
  saveRDS('_posts/2020-08-23-homefield-advantage-in-the-nfl/data.rds')
