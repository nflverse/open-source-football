# This is the model I used to create HC power index. This data is available: hc_index.csv
#Model
start_time = Sys.time(); model<-sample_hc %>%
  lmer(
    formula=
      score_differential ~
      home + #home vs away
      op_Over+ # adjusting opponent
      (1|coach/pass_grade) #adjusting for QB
    ,
    control = lmerControl(optimizer = "nloptwrap", 
                          calc.derivs = FALSE,
                          optCtrl = list(method = "nlminb", 
                                         starttests = FALSE, kkt = FALSE)
    )
  );end_time = Sys.time();end_time - start_time
  
  getME(model, "theta")
  fixef(model)
  
  coach=broom.mixed::tidy(model,effects="ran_vals")%>%
    filter(group=='coach')%>% 
    select(coach = level,estimate,std.error) %>%
    mutate(
      t_stat = estimate/ std.error,
      grade = rescale(estimate, to = c(1, 100))
    ) %>%
    arrange(desc(grade)) %>% select(-std.error,-t_stat)