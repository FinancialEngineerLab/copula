### test of fitCopula ##########################################################

## one replicate
do1 <- function(cop,n) {
  x <- rcopula(cop,n)
  u <- pobs(x)
  f.itau <- fitCopula(cop, u, method="itau")
  f.irho <- fitCopula(cop, u, method="irho")
  f.mpl <- fitCopula(cop, u, method="mpl")
  f.ml <- fitCopula(cop, x, method="ml")
  cbind(est = c(itau = f.itau@estimate, irho = f.irho@estimate,
          mpl = f.mpl@estimate, ml   = f.ml@estimate),
        se = c(itau = sqrt(f.itau@var.est), irho = sqrt(f.irho@var.est),
          mpl = sqrt(f.mpl@var.est), ml = sqrt(f.ml@var.est)))
}

## N replicates with mean of estimates and se, and sd of estimates
testCop <- function(cop, n, N) {
  sim <- replicate(N, do1 (cop,n))
  m <- rowMeans(sim,dims=2)
  cbind(bias = abs(m[,"est"] - cop@parameters), ## abs of bias
        dSE  = abs(m[,"se"] - apply(sim[,1,],1,sd))) ## abs of mean of se minus sd of estimates
}

##' Test of the methods in fitCopula for a bivariate one-parameter copula family
##'
##' @title Test of the methods in fitCopula for a bivariate one-parameter copula family
##' @param cop is the copula family
##' @param tau.set is the set of tau values for which the parameters of cop are set
##' @param n.set is the set of n values used in the simulation
##' @param N is the number of repetitions for computing the bias and dSE
##' @return an array bias and dSE in different tau and n scenarios
##' @author Martin
run1test <- function(cop, tau.set, n.set, N) {
  theta <- structure(calibKendallsTau(cop,tau.set),
		     names = paste("tau", format(tau.set), sep="="))
  names(n.set) <- paste("n",format(n.set),sep="=")
  setPar <- function(cop, value) { cop@parameters <- value ; cop }
  cop.set <- lapply(theta, setPar, cop=cop)
  sapply(cop.set,
         function(cop)
         sapply(n.set, function(n) testCop(cop,n,N), simplify = "array"),
         simplify = "array")
}


##' Reshapes the results for processing by xyplot
##' @title Reshapes the results for processing by xyplot
##' @param res object returned by run1test
##' @param taunum logical indicating whether the taus are numeric or character
##' @return a matrix containing the reshaped results
##' @author Martin
reshape.res <- function(res,taunum=FALSE) {
  names(dimnames(res)) <- c("method","stat","n","tau")
  d <- cbind(expand.grid(dimnames(res),KEEP.OUT.ATTRS=FALSE), x=as.vector(res))
  d[,"n"  ] <- as.numeric(vapply(strsplit(as.character(d[, "n" ]),split="="),`[`,"",2))
  if (taunum)
    d[,"tau"] <- as.numeric(vapply(strsplit(as.character(d[,"tau"]),split="="),`[`,"",2))
  d
}

## plot the results
plots.res <- function(d, log=TRUE) {
  require(lattice)
  xyplot(x ~ n | stat*tau, groups=method, data=d,type="b",
         scales = list(x=list(log=log), y=list(log=log)))
}

## test code
rr <- run1test(normalCopula(), tau.set=seq(0.2,0.8,by=0.2), n.set=c(50,100,200), N=200)
d <- reshape.res(rr)
plots.res(d)
plots.res(d, log=FALSE)