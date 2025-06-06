library(dplyr)
library(tidyverse)
library(ggplot2)

source('results_to_df_range.R') ## script to format list of results as single df
source('na_indicies.R') # helper to find NA values in model comparisons

## Load data:
## params:
load("irtm_bcfa_bsem_params_partial_.rds")
## all_results:
load("irtm_bcfa_bsem_time_partial_.rds")
## model_times:
load("irtm_bcfa_bsem_res_partial_.rds")

##
all_results <- lapply(all_results, function(x) {
  if ("irtM" %in% names(x)) {
    names(x)[names(x) == "irtM"] <- "irtm"
  }
  return(x)
})


all_results <- lapply(all_results, function(x) {
  if ("CFA" %in% names(x)) {
    names(x)[names(x) == "CFA"] <- "bcfa"
  }
  return(x)
})

## get index of NA values in the sim results
## NA out the time runs for those models
## (to not distort estimated time)
## first column is round
## second column is model
##(1 = irtm, 2 = bsem, 3 = bcfa)

na_ind <-na_indicies(all_results)

## update time to NA out times for failed models:
updated_time <- na_times(model_times, na_ind)


## Param list to df:
## Need to remove null entries
## but keep them!

# Initialize an empty list to store non-NULL values
non_null_params <- compact(params_tracker)
non_null_results <- compact(all_results)
non_null_time <- compact(model_times)


# Create a data frame from the non-NULL list
params_df <- bind_rows(non_null_params)

## Send results to dataframe:

sim_results <- bsem_results_to_df(non_null_results,
                                  params_df, 
                                  mode = 3) # model stats


## Runtime by model
time_results <- bsem_results_to_df(non_null_time ,
                                   params_df,
                                   mode = 1) # model stats

#summary(time_results$max)

## Data for Fig 3:  count NA by models:
na_count_by_group <- bsem_results_to_df(non_null_results,
                                        params_df, 
                                        mode = 2) # NA coun


gg_sim_results <- bsem_results_to_df(non_null_results,
                                  params_df, 
                                  mode = 1) # model stats
## column names for labels:

colnames(gg_sim_results)[which(colnames(gg_sim_results) == "pass_N")] <- "N"
colnames(gg_sim_results)[which(colnames(gg_sim_results) == "pass_K")] <- "K"

p_results <- ggplot(gg_sim_results, aes(x= pass_d, 
                                     y=avg,
                                     ymin=min, 
                                     ymax=max,
                                     pch=as.factor(model), 
                                     linetype=as.factor(model))) + 
  geom_point(size=2.5) +
  geom_line() + 
  geom_ribbon(alpha=0.2, linewidth =0) + 
  labs(linetype='Model', pch='Model') + 
  xlab('Dimensions') + 
  ylab('MSE') + 
  scale_x_continuous(breaks=c(2,3, 5, 8))+
  theme_bw() +
  theme(legend.position="bottom", 
        legend.background = element_rect(color='black'), 
        text=element_text(size=20, family="Times")) +
  facet_wrap(~ N + K,  labeller = label_both)

p_results

ggsave(filename='simulations/results/figures/MSE_range_irt-bsem-bcfa.png', 
       plot=p_results,
       dpi = 300,  width = 12, height=6)

## Time results

colnames(time_results)[which(colnames(time_results) == "pass_N")] <- "N"
colnames(time_results)[which(colnames(time_results) == "pass_K")] <- "K"


t_results <- ggplot(time_results, aes(x= pass_d, 
                                        y=avg,
                                        ymin=min, 
                                        ymax=max,
                                        pch=as.factor(model), 
                                        linetype=as.factor(model))) + 
  geom_point(size=2.5) +
  geom_line() + 
  geom_ribbon(alpha=0.2, linewidth =0) + 
  labs(linetype='Model', pch='Model') + 
  xlab('Dimensions') + 
  ylab('Runtime') + 
  theme_bw() +
  theme(legend.position="bottom", 
        legend.background = element_rect(color='black'), 
        text=element_text(size=20, family="Times")) +
  facet_wrap(~ N + K, labeller = label_both)

t_results

ggsave(filename='simulations/results/figures/time_range_irt-bsem-bcfa.png', 
       plot=t_results,
       dpi = 300,  width = 12, height=6)


### Failed runs:

## Plot model failures
colnames(na_count_by_group)[which(colnames(na_count_by_group) == "pass_N")] <- "N"
colnames(na_count_by_group)[which(colnames(na_count_by_group) == "pass_K")] <- "K"

ggmiss <- ggplot(na_count_by_group, 
                 aes(x= pass_d,
                     y= pct_missing,
                     pch = as.factor(model), 
                     linetype=as.factor(model))) + 
  geom_line() +
  geom_point(size=2.5) +
  xlab('Dimensions') + 
  ylab('Percent Failed Models') + 
  scale_x_continuous(breaks=c(2,3, 5, 8))+
  labs(linetype='Model', pch='Model') + 
  theme_bw()+  
  theme(legend.position="bottom", 
        legend.background = element_rect(color='black'), 
        text=element_text(size=20, family="Times")) +
  facet_wrap(~ N + K, labeller = label_both)

ggmiss

ggsave(filename='simulations/results/figures/failed_models_range.png',
       plot=ggmiss,
       dpi = 300, 
       width = 12, 
       height=6)


## which am I waiting for:

gg_remainder <- ggplot(na.omit(na_count_by_group), 
                 aes(x= pass_d,
                     y= count,
                     pch = as.factor(model), 
                     linetype=as.factor(model))) + 
  geom_line() +
  geom_point(size=2.5) +
  xlab('Dimensions') + 
  ylab('Models Run') + 
  labs(linetype='Model', pch='Model') + 
  theme_bw()+  
  theme(legend.position="bottom", 
        legend.background = element_rect(color='black'), 
        text=element_text(size=20, family="Times")) +
  facet_wrap(~ N + K, labeller = label_both)

gg_remainder

ggsave(filename='simulations/results/figures/sim_progress.png',
       plot=gg_remainder,
       dpi = 300, 
       width = 12, 
       height=6)

