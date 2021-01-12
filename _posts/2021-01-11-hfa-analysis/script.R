# I'm not allowed to share PFF data, but here is the script I used to generate the charts
# The columns in my data are:

# score differential: point differencial team - opposing team
# Over: team PFF overall grade for the season
# op_Over: opposing team PFF overall grade for the season
# pass_grade: team PFF passing grade for the game
# op_pass_grade: opposing team PFF passing grade for the game
# home: 1=home, 0=away
# HC_index: HC power index (refer to HC_index_script.R) 
# team: observed team
# Data name: sample

# Example:
# score_differential Over op_Over pass_grade op_pass_grade home HC_index team         game_id
#                -16 78.5    91.9       62.3          78.9    0 59.37623  ATL 2019_01_ATL_MIN
#                 16 91.9    78.5       78.9          62.3    1 69.58822  MIN 2019_01_ATL_MIN


#Chart 1
# Mixed model ----------------------------------------------------------------------
model = sample %>%
  filter(season>=2006) %>%
  lmer(formula=
         score_differential ~
         Over + 
         op_Over +
         pass_grade +
         op_pass_grade+
         home +
         HC_index +
         (0+home|team))

team_hf = broom.mixed::tidy(
  model,effects="ran_vals"
) %>%
  filter(group=='team') %>%
  mutate(
    LHFA = fixef(model)[6],
    HFA = estimate + LHFA,
    LHFA.std.error = sqrt(diag(vcov(model)))[6],
    HFA.std.error = std.error + LHFA.std.error,
  ) %>% rename(iHFA = estimate,iHFA.std.error = std.error)%>% 
  arrange(iHFA) %>%
  arrange(iHFA) %>%
  dplyr::select(
    team=level,LHFA,iHFA,HFA,LHFA.std.error, iHFA.std.error,HFA.std.error
  )

logos = nflfastR::teams_colors_logos %>% 
  select(
    team_abbr,team_logo_espn
  )
plot = team_hf %>% inner_join(
  .,logos, by = c("team" = "team_abbr")
)
z=1.036

plot %>%
  ggplot(aes(x=factor(team, level = team),y=HFA)) + 
  geom_linerange(size=.75,color='gray30',aes(ymin=(HFA - z * HFA.std.error),
                                             ymax=(HFA + z * HFA.std.error)))+
  ggimage::geom_image(aes(image = team_logo_espn),size=.035, asp=1) +
  coord_flip()+
  theme_bw() +
  labs(
    title='Estimated home field advantage per team',
    subtitle = 'During 2006 - 2020. Regular season. 85% Confidence Intervals',
    caption = 'Data: nflfastR & PFF | Chart by Adrian Cadena @adrian_stats',
    y='Home field advantage'
  )+
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(hjust=0.5,size=10,color='gray20',family = "Trebuchet MS"),
    plot.subtitle = element_text(hjust=0.5,size=8,color='gray20',family = "Trebuchet MS"),
    axis.title = element_text(hjust=0.5,size=8,color='gray20',family = "Trebuchet MS"),
    axis.title.y = element_blank(),
    axis.text.x =  element_text(hjust=0.5,size=7,color='gray20',family = "Trebuchet MS"),
    plot.caption = element_text(size=7,color='gray20',family = "Trebuchet MS"),
    legend.position = 'right',
    legend.title = element_text(size=7,color='gray20',family = "Trebuchet MS"),
    legend.text = element_text(size=7,color='gray20',family = "Trebuchet MS")
  )

#Chart 2
lst = list()
for (y in 2006:2020){
  data_y = sample %>% dplyr::filter(season == y)
  # Mixed model
  model =  lmer(
    score_differential ~
      Over + 
      op_Over +
      pass_grade +
      op_pass_grade+
      home +
      HC_index +
      (0+home|team)
    ,
    control = lmerControl(
      optimizer = "nloptwrap", calc.derivs = FALSE,
      optCtrl = list(method = "nlminb", starttests = FALSE, kkt = FALSE))
    ,
    data = data_y
  )
  
  hf = broom.mixed::tidy(model,effects="ran_vals")  %>%
    filter(group=='team') %>%
    mutate(
      estimate = fixef(model)[6]) %>% 
    arrange(estimate) %>%
    dplyr::select(level,HFA = estimate,std.error) 
  
  hf$season = y
  
  lst[[toString(y)]] = hf
} 
HFA_ = dplyr::bind_rows(lst)

HFA_seas = HFA_ %>% 
  dplyr::group_by(season) %>% 
  dplyr::summarise(
    HFA = mean(HFA)
  )

HFA_seas %>% ggplot(aes(x=season,y=HFA)) +
  geom_line(color="#ef8a62",size=1)+
  geom_smooth(color="#67a9cf",fill="#B6D6E8")+
  geom_text(
    aes(y=HFA,label=round(HFA,1)),
    family="Trebuchet MS",fontface='bold',
    size=3.5
  )+
  labs(
    title = "Movement of league home field advantage",
    subtitle = "My model suggests that league home field advantage has been declining during the 
last couple of seasons until reaching a negative value in 2019",
    caption = 'Data: nflfastR & PFF | Chart by Adrian Cadena @adrian_stats',
    y='Estimated League Home Field Advantage',
    x='Season') + 
  scale_x_continuous(breaks=c(2006,2008,2010,2012,2014,2016,2018,2020))+
  theme_bw()+
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(hjust=0.5,size=12,color='gray20',family = "Trebuchet MS"),
    plot.subtitle = element_text(hjust=0.5,size=10,color='gray20',family = "Trebuchet MS"),
    axis.title = element_text(hjust=0.5,size=10,color='gray20',family = "Trebuchet MS"),
    axis.text.y =  element_blank(),
    axis.text.x =  element_text(hjust=0.5,size=10,color='gray20',family = "Trebuchet MS"),
    plot.caption = element_text(size=9,color='gray20',family = "Trebuchet MS")
  )  +ggsave("C:/Users/adrian-boss/Documents/GitHub/website/content/post/HFA/featured.png")

#Chart 3
lst = list()
for (y in 2006:2020){
  data_y = sample %>% dplyr::filter(season == y)
  
  model =  lmer(
    score_differential ~
      Over + 
      op_Over +
      pass_grade +
      op_pass_grade+
      home +
      HC_index +
      (0+home|team)
    ,
    control = lmerControl(
      optimizer = "nloptwrap", calc.derivs = FALSE,
      optCtrl = list(method = "nlminb", starttests = FALSE, kkt = FALSE)
    )
    ,
    data = data_y)
  
  hf = broom.mixed::tidy(model,effects="ran_vals")  %>%
    filter(group=='team') %>%
    mutate(
      LHFA = fixef(model)[6],
      HFA = estimate + LHFA,
      LHFA.std.error = sqrt(diag(vcov(model)))[6],
      HFA.std.error = std.error + LHFA.std.error
    )%>% 
    arrange(estimate) %>%
    dplyr::select(team=level,LHFA,iHFA = estimate,HFA,LHFA.std.error,iHFA.std.error = std.error,HFA.std.error) 
  
  hf$season = y
  
  lst[[toString(y)]] = hf
} 

HFA = dplyr::bind_rows(lst) 

colors = nflfastR::teams_colors_logos %>%
  filter(team_abbr %in% c('ARI','PHI'))%>%
  select(color=team_color) 

HFA %>% 
  filter(team %in% c('ARI','PHI'))%>%
  ggplot(aes(x=season,y=iHFA))+
  scale_colour_manual( values = colors$color)+
  geom_line(aes(color=team),size=1)+
  theme_bw() +
  labs(
    title = 'Movement of team-specific home field advantage', 
    subtitle = 'The behavior of team-specific home field advantage is volatile and unpredictable.
As an example, I present iHFA for ARI and PHI since 2006.',
    caption = 'Data: nflfastR & PFF | Chart by Adrian Cadena @adrian_stats',
    x = 'Season',
    y = 'Team-Specific Home Field Advantage (iHFA)',
    color = "Team"
  )+
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(hjust=0.5,size=12,color='gray20',family = "Trebuchet MS"),
    plot.subtitle = element_text(hjust=0.5,size=10,color='gray20',family = "Trebuchet MS"),
    axis.text.x =  element_text(hjust=0.5,size=10,color='gray20',family = "Trebuchet MS"),
    plot.caption = element_text(size=9,color='gray20',family = "Trebuchet MS"),
    legend.position = 'top',
    legend.title = element_text(size=8,color='gray20',family = "Trebuchet MS"),
    legend.text = element_text(size=8,color='gray20',family = "Trebuchet MS")
  ) + scale_x_continuous(breaks=c(2006,2008,2010,2012,2014,2016,2018,2020))

#Chart 4
model = sample %>%
  filter(season==2020) %>%
  lmer(formula=
         score_differential ~
         Over + 
         op_Over +
         pass_grade +
         op_pass_grade+
         home +
         HC_index +
         (0+home|team))

team_hf = broom.mixed::tidy(
  model,effects="ran_vals"
) %>%
  filter(group=='team') %>%
  mutate(
    LHFA = fixef(model)[6],
    HFA = estimate + LHFA,
    LHFA.std.error = sqrt(diag(vcov(model)))[6],
    HFA.std.error = std.error + LHFA.std.error,
  ) %>% rename(iHFA = estimate,iHFA.std.error = std.error)%>% 
  arrange(iHFA) %>%
  arrange(iHFA) %>%
  dplyr::select(
    team=level,LHFA,iHFA,HFA,LHFA.std.error, iHFA.std.error,HFA.std.error
  )

logos = nflfastR::teams_colors_logos %>% 
  select(
    team_abbr,team_logo_espn
  )
plot = team_hf %>% inner_join(
  .,logos, by = c("team" = "team_abbr")
)
z=1.036

plot %>%
  ggplot(aes(x=factor(team, level = team),y=HFA)) + 
  geom_linerange(size=.75,color='gray30',aes(ymin=(HFA - z * HFA.std.error),
                                             ymax=(HFA + z * HFA.std.error)))+
  ggimage::geom_image(aes(image = team_logo_espn),size=.035, asp=1) +
  coord_flip()+
  theme_bw() +
  labs(
    title='Estimated home field advantage per team',
    subtitle = 'Regular season 2020. 85% Confidence Intervals.',
    caption = 'Data: nflfastR & PFF | Chart by Adrian Cadena @adrian_stats',
    y='Home field advantage'
  )+
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(hjust=0.5,size=10,color='gray20',family = "Trebuchet MS"),
    plot.subtitle = element_text(hjust=0.5,size=8,color='gray20',family = "Trebuchet MS"),
    axis.title = element_text(hjust=0.5,size=8,color='gray20',family = "Trebuchet MS"),
    axis.title.y = element_blank(),
    axis.text.x =  element_text(hjust=0.5,size=7,color='gray20',family = "Trebuchet MS"),
    plot.caption = element_text(size=7,color='gray20',family = "Trebuchet MS"),
    legend.position = 'right',
    legend.title = element_text(size=7,color='gray20',family = "Trebuchet MS"),
    legend.text = element_text(size=7,color='gray20',family = "Trebuchet MS")
  ) 





