include("MCMC_BayesB.jl")
include("MCMC_BayesC.jl")
include("MT_MCMC_BayesB.jl")
include("MT_MCMC_BayesC.jl")

"""
    runMCMC(mme,df;Pi=0.0,estimatePi=false,chain_length=1000,starting_value=false,printout_frequency=100,missing_phenotypes=false,constraint=false,methods="conventional (no markers)",output_samples_frequency::Int64 = 0)

Run MCMC (marker information included or not) with sampling of variance components.

* available **methods** include "conventional (no markers)", "BayesC0", "BayesC", "BayesCC","BayesB".
* **missing_phenotypes**
* **Pi** is a dictionary such as `Pi=Dict([1.0; 1.0]=>0.7,[1.0; 0.0]=>0.1,[0.0; 1.0]=>0.1,[0.0; 0.0]=>0.1)`
* save MCMC samples every **output_samples_frequency** iterations
* **starting_value** can be provided as a vector for all location parameteres except marker effects.
* print out the monte carlo mean in REPL with **printout_frequency**
* **constraint**=true if constrain residual covariances between traits to be zero.
"""
function runMCMC(mme,df;
                Pi                = 0.0,   #Dict{Array{Float64,1},Float64}()
                chain_length      = 100,
                starting_value    = false,
                missing_phenotypes= false,
                constraint        = false,
                estimatePi        = false,
                methods           = "conventional (no markers)",
                printout_frequency= chain_length+1,
                output_samples_frequency::Int64 = 0,
                update_priors_frequency::Int64=0)

  if mme.M != 0 && mme.M.G_is_marker_variance==false
    genetic2marker(mme.M,Pi)
    println("Priors for marker effects covariance matrix were calculated from genetic covariance matrix and π.")
    if !isposdef(mme.M.G) #also work for scalar
      error("Marker effects covariance matrix is not postive definite! Please modify the argument: Pi.")
    end
    println("Marker effects covariance matrix is ")
    println(round(mme.M.G,6),".\n\n")
  end

  MCMCinfo(methods,chain_length,starting_value,printout_frequency,
           output_samples_frequency,missing_phenotypes,constraint,estimatePi,
           update_priors_frequency,mme)

  if mme.nModels ==1
      if methods in ["BayesC","BayesC0","conventional (no markers)"]
          res=MCMC_BayesC(chain_length,mme,df,
                          π          =Pi,
                          methods    =methods,
                          estimatePi =estimatePi,
                          sol        =starting_value,
                          outFreq    =printout_frequency,
                          output_samples_frequency=output_samples_frequency)
       elseif methods =="BayesB"
           res=MCMC_BayesB(chain_length,mme,df,Pi,
                            estimatePi =false,
                            sol        =starting_value,
                            outFreq    =printout_frequency,
                            output_samples_frequency=output_samples_frequency)
        else
            error("No options!!!")
        end
    elseif mme.nModels > 1
        if Pi != 0.0 && round(sum(values(Pi)),2)!=1.0
          error("Summation of probabilities of Pi is not equal to one.")
        end
        if methods in ["BayesC","BayesCC","BayesC0","conventional (no markers)"]
          res=MT_MCMC_BayesC(chain_length,mme,df,
                          Pi     = Pi,
                          sol    = starting_value,
                          outFreq= printout_frequency,
                          missing_phenotypes=missing_phenotypes,
                          constraint = constraint,
                          estimatePi = estimatePi,
                          methods    = methods,
                          output_samples_frequency=output_samples_frequency,
                          update_priors_frequency=update_priors_frequency)
        elseif methods=="BayesB"
            if Pi == 0.0
                error("Pi is not provided!!")
            end
            res=MT_MCMC_BayesB(chain_length,mme,df,Pi,
                            sol=starting_value,
                            outFreq=printout_frequency,
                            missing_phenotypes=missing_phenotypes,
                            constraint=constraint,
                            output_samples_frequency=output_samples_frequency)
        else
            error("No methods options!!!")
        end
    else
        error("No options!")
    end
  res
end
