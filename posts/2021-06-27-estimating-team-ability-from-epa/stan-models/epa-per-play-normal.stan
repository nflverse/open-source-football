data{
  int<lower = 0> N; //number of plays
  int<lower = 1> I; //number of teams
  int<lower = 0, upper = I> ii[N]; //indicator for offense
  int<lower = 0, upper = I> jj[N]; //indicator for defense
  real<lower = -16, upper = 10> y[N]; //epa
  int<lower = 1> N_rep; //number of samples for posterior density check
  int<lower = 1, upper = I> ii_rep[N_rep];
  int<lower = 1, upper = I> jj_rep[N_rep];
}
parameters{
  real<lower = 0> sigma_y; //error for t distribution
  real<lower = 0> sigma_off; //variance in offensive ability
  real<lower = 0> sigma_def; //variance in defensive ability
  vector[I] alpha_off_raw;
  vector[I] alpha_def_raw;
}
transformed parameters{ //using non-centered paramaterization
  vector[I] alpha_off = alpha_off_raw * sigma_off;
  vector[I] alpha_def = alpha_def_raw * sigma_def;
}
model{
  //priors
  alpha_off_raw ~ normal(0,1);
  alpha_def_raw ~ normal(0,1);
  sigma_off ~ normal(.06,.03);
  sigma_def ~ normal(.03,.03);
  sigma_y ~ normal(1,.2);
  
  //likelihood
    y ~ normal(alpha_off[ii] + alpha_def[jj], sigma_y);
}
generated quantities{
  vector[N_rep] y_rep;
  
  for (n in 1:N_rep){
    y_rep[n] = normal_rng(alpha_off[ii_rep[n]] + alpha_def[jj_rep[n]], sigma_y);
  }
}
