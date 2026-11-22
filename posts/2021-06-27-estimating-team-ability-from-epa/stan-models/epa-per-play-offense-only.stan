data{
  int<lower = 0> N; //number of plays
  int<lower = 1> I; //number of teams
  int<lower = 0, upper = I> ii[N]; //indicator for offense
  real<lower = -16, upper = 10> y[N]; //epa
}
parameters{
  real<lower = 0> sigma_y; //error for t distribution
  real<lower = 0> sigma_off; //variance in offensive ability
  vector[I] alpha_off_raw;
}
transformed parameters{ //using non-centered paramaterization
  vector[I] alpha_off = alpha_off_raw * sigma_off;
}
model{
  //priors
  alpha_off_raw ~ normal(0,1);
  sigma_off ~ normal(.06,.03);
  sigma_y ~ normal(1,.2);
  
  //likelihood
    y ~ normal(alpha_off[ii], sigma_y);
}
