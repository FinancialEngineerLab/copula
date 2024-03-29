## Copyright (C) 2012 Marius Hofert, Ivan Kojadinovic, Martin Maechler, and Jun Yan
##
## This program is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free Software
## Foundation; either version 3 of the License, or (at your option) any later
## version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
## FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along with
## this program; if not, see <http://www.gnu.org/licenses/>.


require(copula)
sessionInfo() # will change often.. but if we need the info, get it here

## Regression Tests -- n=1 failed till 2012-07-15
u1 <- pobs(rbind(1:4)) # = (1/2 1/2 1/2 1/2)
cG <- gumbelCopula(2, d=4)
ocG<- onacopula("Gumbel", C(2., 1:4))
(rtG  <- cCopula(u1, copula = ocG))
(rtGI <- cCopula(u1, copula = ocG, inverse=TRUE))
(IrtG <- cCopula(rtG , copula = cG, inverse=TRUE, drop=TRUE))
(rtG..<- cCopula(rtGI, copula = cG, inverse=TRUE, drop=TRUE))
## failed with  " object 'n' not found " in 0.999.17
stopifnot(exprs = {
    all.equal(rtG,  cCopula(u1, copula = cG), tolerance = 1e-15)
    all.equal(rtG,  rbind(c(0.5, 0.530633, 0.4852854, 0.4567624)), tol = 7e-7)# seen 6.97e-8
    all.equal(rtGI, cCopula(u1, copula = cG, inverse=TRUE), tol = 1e-15)
    all.equal(rtGI, rbind(c(0.5, 0.4797781, 0.4997766, 0.5174252)),tol = 5e-7)# seen 4.97e-8
    all.equal(u1, IrtG, tol = 1e-4) # see 5.28e-5
    all.equal(cCopula(rtG.., copula = cG), rtGI, tol = 1e-4) # see 2.0e-5
})

### A faster, more checking version of demo(estimation.gof)
### that is, of ../demo/estimation.gof.R
##              ~~~~~~~~~~~~~~~~~~~~~~~~
## Note: This is only for proof of concept, the numbers chosen are not reasonable
##       for proper (estimation and) goodness-of-fit testing

(doExtras <- copula:::doExtras())
source(system.file("Rsource", "estim-gof-fn.R", package="copula"))
## --> estimation.gof() etc
source(system.file("Rsource", "utils.R",     package="copula", mustWork=TRUE))
##-> assertError(), ... showProc.time()


## GoF methods (NOTE: 'htrafo' only implemented for objects of type 'outer_nacopula')
## (gofTraf <- eval(formals(gofPB)$trafo.method)[-1]) # "cCopula", "htrafo"
gofTraf <- "cCopula"
(gofMeth <- c("SnB", "SnC")) ## IK: eval(formals(gofPB)$method)) # "Sn", "SnB", "SnC", "AnChisq", "AnGamma"

n <- 64 # sample size [small here for CPU reasons]
d <- 5 # dimension
tau <- 0.25 # Kendall's tau

### apply all procedures (to data from AMH) ####################################

simFamily <- "AMH"
cop <- getAcop(simFamily)
theta <- cop@iTau(tau) # true parameter

## start the loop
cat("\n### data from ",simFamily," (n = ",n,", d = ",d,", theta = ",
    format(theta),", tau = ", format(tau),") ###\n\n",sep="")

showProc.time()

## checking / for debugging purposes
tools::assertError(
    estimation.gof(n, d=d, simFamily=simFamily, tau=tau,
                   N=3, estim.method="mpl", verbose=FALSE,
                   gof.trafo = "cCopula", #  <- only "none" is allowed
                   gof.method="Sn",
                   checkFamilies = c("Clayton", "Gumbel"))
)

suppressWarnings(RNGversion("3.5.0")) # => sample() "biased" --> warning --> *remove* in future!
set.seed(1) # set seed
## note: this might (still) take a while...
RR <- sapply(gofTraf, simplify="array", function(gt)
         {
             sapply(gofMeth, simplify="array", function(gm)
                    estimation.gof(n, d=d, simFamily=simFamily, tau=tau,
				   N=3, # << "nonsense" for speed reasons;..
                                   ## for a particular method under consideration
                                   ## please choose a larger number here, for example 1000
                                   estim.method="mpl", # simulation="pb", default
                                   verbose=FALSE,
                                   gof.trafo=gt, # "cCopula" ("htrafo"; see above)
                                   gof.method=gm)) # gofMeth (one of "Sn", "SnB", "SnC")
                                   # checkFamilies=setdiff(copula:::c_longNames, "AMH")) # default
         })
showProc.time()
if(interactive()) {
    str(RR, vec.len=8)
} else { ## for reproducibility (comparing): *not* showing time
    cat("dim(RR): (", format(dim(RR),collapse=","),")\n")
    str(dimnames(RR))
}


## Now print RR
options(digits=5)
## No times here...
RR[,c("theta_hat", "tau_hat", "P_value", "< 0.05"),,]

## ... but rather here, separately:
apply(RR[,c("timeEstim","timeGoF"),,], c(3,1,2), mean)

showProc.time()


### *Some* minimal  gofCopula() examples {the help page has \donttest{} !}
catn <- function(...) cat(..., "\n", sep="")
set.seed(101)

## A two-dimensional data example -------
x <- rCopula(200, claytonCopula(3))

### FIXME:  test an    optim.method = "Brent"  (and maybe another optim.method) example !!

fMeth <- c("mpl", "ml", "itau", "irho")
gofL <- sapply(fMeth, function(fitMeth) {
    catn("\nfit*( estim.method = '", fitMeth,"')\n----------------------")
    print(gofCopula(gumbelCopula (), x, N = 10, verbose=FALSE,
		    estim.method = fitMeth))
    print(gofCopula(claytonCopula(), x, N = 10, verbose=FALSE,
		    estim.method = fitMeth))
}, simplify=FALSE)
## other 'optim.method's :
gBr <- gofCopula(claytonCopula(), x, N=10, verbose=FALSE,
                 optim.method="Brent", lower=0, upper=10)
gNM <- gofCopula(claytonCopula(), x, N=10, verbose=FALSE, optim.method="Nelder")
showProc.time()

stopifnot(all.equal(vapply(gofL, `[[`, 0., "statistic"),
		    setNames(c(0.01355175, 0.01355175, 0.01201136, 0.01257382),
			     fMeth), tolerance = 1e-6),
	  all.equal(vapply(gofL, `[[`, 0., "p.value"),
		    setNames(c(0.4090909, 0.3181818, 0.4090909, 0.8636364),
			     fMeth), tolerance = 1e-6),
	  all.equal(unname(gBr$parameter), 3.193331257, tolerance = 2e-7),
	  gBr$p.value > 0.68,
	  all.equal(unname(gNM$parameter), 3.1932227,   tolerance = 2e-7),
	  gNM$p.value > 0.3)

## The same using the multiplier approach -- "ml" is not allowed:
for(fitMeth in c("mpl", "itau", "irho")) {
    catn("\nfit*( estim.method = '", fitMeth,"')\n----------------------\n")
    print(gofCopula(gumbelCopula (), x, N = 10, verbose=FALSE,
		    estim.method = fitMeth, simulation="mult"))
    print(gofCopula(claytonCopula(), x, N = 10, verbose=FALSE,
		    estim.method = fitMeth, simulation="mult"))
    print(gofCopula(gumbelCopula (), x, N = 10, verbose=FALSE,
		    estim.method = fitMeth, simulation="mult",
                    method="Rn"))
    print(gofCopula(claytonCopula(), x, N = 10, verbose=FALSE,
		    estim.method = fitMeth, simulation="mult",
                    method="Rn"))
}
warnings()


## A three-dimensional example	------------------------------------
x <- rCopula(200, tCopula(c(0.5, 0.6, 0.7), dim = 3, dispstr = "un"))

gumbC <- gumbelCopula(1, dim = 3, use.indepC="FALSE")
t.cop  <- tCopula(dim = 3, dispstr = "un", df.fixed=TRUE)
t.copV <- tCopula(dim = 3, dispstr = "un", df.fixed=FALSE)

showProc.time()

## NOTE: takes a while...
if(doExtras)
for(meth in eval(formals(gofPB)$method)) {
    catn("\ngof method: ", meth,"\n==========================")
    traMeth <- if(meth == "Sn") "none" else "cCopula"
  for(fitMeth in c("mpl", "ml", "itau", "irho", "itau.mpl")) {
    catn("fit*( estim.method = '", fitMeth,"')\n------------------------")
    if(fitMeth != "itau.mpl") {
        catn("Gumbel copula:")
        print(gofCopula(gumbC, x, method=meth, N = 10, verbose=FALSE,
                        estim.method = fitMeth, trafo.method = traMeth))
    }
    if(meth != "Sn" && fitMeth != "irho") {
	## ... not available for t copulas as pCopula() cannot be computed
	##     for non-integer degrees of freedom yet.
	catn("t-copula (df.fixed = FALSE):")
	print(gofCopula(t.copV, x, method=meth, N = 10, verbose=FALSE,
			estim.method = fitMeth, trafo.method = traMeth))
    } else if(meth == "Sn" && !(fitMeth %in% c("irho", "itau.mpl"))) {
	catn("t-copula (df.fixed = TRUE):")
	print(gofCopula(t.cop, x, method=meth, N = 10, verbose=FALSE,
			estim.method = fitMeth, trafo.method = traMeth))
    }
  }
  showProc.time()
}
if(doExtras) warnings()

## The same using the multiplier approach -- "ml" is not allowed in general;
##  "itau" and "irho"  only  for  d = 2	 (for now !)
for(fitMeth in c("mpl")) {
    catn("\nfit*( estim.method = '", fitMeth,"')\n----------------------\n")
    print(gofCopula(gumbC, x, N = 10, estim.method = fitMeth, simulation="mult"))
    print(gofCopula(t.cop, x, N = 10, estim.method = fitMeth, simulation="mult"))
    print(gofCopula(gumbC, x, N = 10, estim.method = fitMeth, simulation="mult",
                    method="Rn"))
    print(gofCopula(t.cop, x, N = 10, estim.method = fitMeth, simulation="mult",
                    method="Rn"))
}
showProc.time()
warnings()


### Test complicated implementation of SnB and SnC test statistics #############

##' Simple versions of the test statistics of Genest, Remillard, Beaudoin (2009)
##' @title Simple versions of the test statistics of Genest, Remillard, Beaudoin (2009)
##'	   for testing U[0,1]^d
##' @param u n x d matrix of (pseudo-/copula-)observations
##' @param method one of "SnB" or "SnC"; see Genest, Remillard, Beaudoin (2009)
##' @return values of the chosen test statistic
##' @author Marius Hofert
gofTstatSimple <- function(u, method=c("SnB", "SnC")) {
    if(!is.matrix(u)) u <- rbind(u, deparse.level=0L)
    d <- ncol(u)
    n <- nrow(u)
    stopifnot(n >= 1, d >= 2)
    method <- match.arg(method)
    switch(method,
	   "SnB" =
       { ## S_n(B)
	   sum1 <- sum(apply(1 - u^2, 1, prod)) / 2^(d-1)
	   sum2 <- numeric(n)
	   for(i in 1:n) {
	       s <- 0
	       for(j in 1:n) s <- s + prod(1 - pmax(u[i,], u[j,]))
	       sum2[i] <- s
	   }
	   n/3^d - sum1 + mean(sum2)
       },
	   "SnC" =
       { ## S_n(C)
	   Dn <- numeric(n)
	   for(i in 1:n){
	       for(k in 1:n){
		   Dn[i] <- Dn[i] + all(u[k,] <= u[i,])/n
	       }
	   }
	   Cperp <- apply(u, 1, prod) # independence copula Pi
	   sum((Dn-Cperp)^2)
       },
	   stop("unsupported method ", method))
}

## Test
n <- 200
set.seed(1)

for(d in if(doExtras) 2:4 else 3) {
    u <- matrix(runif(n*d), ncol=d)
    showProc.time()
    ##
    showSys.time(B. <- gofTstat(u, method="SnB"))
    showSys.time(C. <- gofTstat(u, method="SnC"))
    stopifnot(all.equal(B., gofTstatSimple(u, method="SnB")),
              all.equal(C., gofTstatSimple(u, method="SnC")))
    print(c(SnB = B., SnC = C.))
    showProc.time()
}
warnings()

## Now (have default "L-BFGS-B"), works :
cop <- archmCopula("Clayton", param=2, dim=d)
for(met in gofMeth) {
    catn("\n gof-method: ", met, ":\n---------")
    nBoot <- switch(met,
                    "SnB" = 1,
                    "SnC" = 2,
                    ## the rest:
                    7)
    if(doExtras) nBoot <- 8 * nBoot
    set.seed(7)
    st <- system.time( ## "SnB" is relatively slow - shorten here:
        gn <- gofCopula(cop, x = u, N = nBoot,
                        method = met, estim.method = "mpl",
                        simulation = "pb", verbose = FALSE))
    print(gn)
    print(st)
    catn("=================================================")
}
showProc.time()


## Test parametric-bootstrap with all statistics
## for Clayton, Gumbel, danube and rdj data sets
if(doExtras >= 2) {

    meths  <- c("Sn",    "SnB",     "SnC") ## for "pb" (= default)
    trafos <- c("none", "cCopula", "cCopula")

    stopifnot(length(meths) == length(trafos))
    doGOFTests <- function(cop, x, N) {
        for (i in seq_along(meths))
            print(gofCopula(cop, x = x, method = meths[i],
                            trafo.method = trafos[i], N = N))
    }

    ### Clayton #############################
    x <- rCopula(300,claytonCopula(4))

    ## Clayton should not be rejected
    print( doGOFTests(claytonCopula(), x, N=100) )

    ## Gumbel should be rejected
    print( doGOFTests(gumbelCopula(), x, N=100) )

    ### Gumbel #############################
    x <- rCopula(300,gumbelCopula(4))

    ## Clayton should be rejected
    print( doGOFTests(claytonCopula(), x, N=100) )

    ## Gumbel should not be rejected
    print( doGOFTests(gumbelCopula(), x, N=100) )

    ### danube -- skip if lcopula is not available ##########################
    if(!inherits(try(data(danube, package = "lcopula")), "try-error")) {
        x <- as.matrix(danube)
        ## Clayton should be rejected
        print( doGOFTests(claytonCopula(), x, N=100) )
        ## Gumbel should not be (too strongly) rejected
        print( doGOFTests( gumbelCopula(), x, N=100) )
    }

    ### rdj ###############################
    data(rdj)
    x <- as.matrix(rdj[,2:4])
    ## Clayton should be rejected
    print( doGOFTests(claytonCopula(dim = 3), x, N=50) )

    ## t with df=10 should not be rejected
    cop <- tCopula(dim = 3, dispstr = "un", df = 10, df.fixed = TRUE)
    print( doGOFTests(cop, x, N=50) )
}
