SubRegressionBased <- function(y_l, X, conversion = "sum", 
                               method = "chow-lin-maxlog", fr = 4, 
                               neg.rho = FALSE, 
                               fixed.rho = 0.5, tol = 1e-16, 
                               lower = -0.999, upper = 0.999){
  # performs temporal disaggregation for regression based methods
  #
  # Args:
  #   y_l:          vector of the low-frequency left-hand side variable
  #   X:            matrix of high-frequency indicators
  #   conversion:   type of conversion ("sum", "average", "first", "last")
  #   method:       method
  #   neg.rho:      should a negative rho (AR1-parameter) be allowed 
  #   fixed.rho:    set a predefined rho
  #   fr:           ratio of high-frequency units per low-frequency unit
  #   tol:          desired accuracy, passed on to optim()
  #   lower, upper: scalar indicating the limits of the rho parameter
  #
  # Returns:
  #   A list, containing the output of CalcGLS() and the following elements:
  #     fitted.values   vector, interpolated (and extrapolated) high frequency 
  #                     series
  #     p               vector, preliminary high frequency series
  #     residuals       vector, low-frequency residuals
  #     rho             scalar, autoregressive parameter
  #     truncated       logical, whether rho has been truncated to 0
  
  # dimensions of y_l and X
  n_l <- length(y_l)
  n <- dim(X)[1]
  m <- dim(X)[2]
  
  # conversion matrix expanded with zeros
  C <- CalcC(n_l, conversion, fr, n)
  
  pm <- CalcPowerMatrix(n)
  
  # aggregated values
  X_l <- C %*% X
  
  # default value for the truncated indicator
  truncated <- FALSE
  
  # method specific optimization objective
  if (method == "chow-lin-maxlog"){
    Objective <- function(rho){
      -CalcGLS(y = y_l, X = X_l, vcov = C%*%CalcQ(rho, pm)%*%t(C), 
               stats = FALSE)$logl
    }
  } else if (method == "chow-lin-minrss-ecotrim"){
    Objective <- function(rho){
      CalcGLS(y = y_l, X = X_l, vcov = C%*%CalcR(rho, pm)%*%t(C), logl = FALSE, 
              stats = FALSE)$rss
    } 
  } else if  (method == "chow-lin-minrss-quilis"){
    Objective <- function(rho){
      CalcGLS(y = y_l, X = X_l, vcov = C%*%CalcQ(rho, pm)%*%t(C), logl = FALSE, 
              stats = FALSE)$rss
    }
  } else if (method == "litterman-maxlog"){
    Objective <- function(rho){
      -CalcGLS(y = y_l, X = X_l, vcov = C%*%CalcQ_Lit(X, rho)%*%t(C), 
               stats = FALSE)$logl
    }
  } else if (method == "litterman-minrss"){
    Objective <- function(rho){
      CalcGLS(y = y_l, X = X_l, vcov = C%*%CalcQ_Lit(X, rho)%*%t(C), 
              logl = FALSE, stats = FALSE)$rss
    }
  }
  
  # finding the optimal rho parameter
  if (method %in% c("chow-lin-maxlog", "chow-lin-minrss-ecotrim", 
                    "chow-lin-minrss-quilis", "litterman-maxlog", 
                    "litterman-minrss")){
    optimize.results <- optimize(Objective, lower = lower , upper = upper, tol = tol,
                                 maximum = FALSE)
    rho <- optimize.results$minimum
    
    # set negative rho to 0 if specified (faster than 'lower' = 0)
    if ((!neg.rho) & (rho < 0)){
      rho <- 0
      truncated <- TRUE
    } 
    
  } else if (method == "fernandez"){
    rho <- 0
  } else if (method == "ols"){
    rho <- 0
  } else if (method %in% c("chow-lin-fixed", "litterman-fixed")){
    rho <- fixed.rho
  }
  
  # finding Q
  if (method %in% c("fernandez", "litterman-maxlog", "litterman-minrss", 
                    "litterman-fixed")){
    Q       <- CalcQ_Lit(X = X, rho = rho)
  } else if (method %in% c("chow-lin-maxlog", "chow-lin-minrss-ecotrim", 
                           "chow-lin-minrss-quilis",  "chow-lin-fixed", "ols")){
    Q       <- CalcQ(rho = rho, pm = pm)
  }
  
  # aggregating Q
  Q_l <- C %*% Q %*% t(C)
  
  # final GLS estimation (aggregated)
  z <- CalcGLS(y = y_l, X = X_l, vcov = Q_l)
  
  # preliminary series
  p   <- as.numeric(X %*% z$coefficients)
  
  # distribution matrix
  D <- Q %*% t(C) %*% z$vcov_inv
  
  # low frequency residuals
  u_l <- as.numeric(y_l - C %*% p)
  
  # final series
  y <- as.numeric(p + D %*% u_l)
  
  # output
  z$vcov_inv         <- NULL  # not need to keep
  z$fitted.values    <- y
  z$p                <- p
  z$residuals        <- u_l
  z$rho              <- rho
  z$truncated        <- truncated
  z
}


SubDenton <- function(y_l, X, conversion, method, fr, 
                      criterion = "proportional", h = 1) {
  # performs temporal disaggregation for denton methods
  #
  # Args:
  #   y_l:          vector of the low-frequency left-hand side variable
  #   X:            matrix of high-frequency indicators
  #   conversion:   type of conversion ("sum", "average", "first", "last")
  #   method:       method
  #   fr:           ratio of high-frequency units per low-frequency unit
  #
  # Returns:
  #   a list containing the following variables
  #     fitted.values   interpolated (and extrapolated) high frequency series
  #     p               preliminary high frequency series
  #     residuals       low-frequency residuals
  
  if (dim(as.matrix(X))[2] > 1){
    stop("Right hand side is not a vector, only one series allowed in
         Denton methods")
  }
  if (!(criterion %in% c("additive", "proportional"))) {
    stop("criterion for Denton methods must be additive or proportional")
  }
  
  # uniform is a special case of denton
  if (method == "uniform"){
    h <- 0
    criterion <- "additive"
    method <- "denton"
  }
  
  # dimensions of y_l and X
  n_l <- length(y_l)
  n <- length(as.numeric(X))
  
  # conversion matrix expanded with zeros
  C <- CalcC(n_l, conversion, fr, n)
  
  D <- D_0 <- diag(n)
  diag(D[2:n, 1:(n-1)]) <- -1
  X_inv <- diag(1 / (as.numeric(X)/mean(X)))
  
  if (h == 0) {
    if(criterion == "proportional") {
      D_0 <- D_0 %*% X_inv
    }
  } else if (h>0) {
    for (i in 1:h) {
      D_0 <- D%*%D_0
    }
    if(criterion == "proportional") {
      D_0 <- D_0 %*% X_inv
    }
  } else stop("wrong specification of h")
  
  # low frequency residuals
  u_l <- as.numeric(y_l - C %*% X)
  
  if (method == "denton-cholette"){
    if (h == 0) {
      D_1 <- D_0
    } else {D_1 <- D_0[-(1:h),]}
    A <- t(D_1)%*% D_1
    
    # Eq. (2.2) from Denton (1971); Eq (6.8) from Cholette and Dagum (2006)
    y <- solve(
      rbind(cbind(A, t(C)), cbind(C, matrix(0, nrow = n_l, ncol = n_l)))
    ) %*% rbind(
      cbind(A, matrix(0, nrow = n, ncol = n_l)),
      cbind(C, diag(1, nrow = n_l, ncol = n_l))
    ) %*% matrix(c(X, u_l))
    
    # final series
    y <- y[1:n]
    
  } else if (method == "denton"){
    D_1 <- D_0
    
    # Denton (1971), in the text below Eq. (2.2)
    Q <- solve(t(D_1) %*% D_1)
    
    # distribution matrix
    D <- Q %*% t(C) %*% solve(C %*% Q %*% t(C))
    
    # final series
    y <- as.numeric(X + D %*% u_l)
  }
  
  # output
  z <- list()
  z$fitted.values <- y
  z$p             <- X
  z$residuals     <- u_l
  z$criterion     <- criterion
  z$h             <- h
  
  z
  }
