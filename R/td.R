#' Temporal Disaggregation of Time Series
#' 
#' Perform temporal disaggregation or interpolation of low frequency to high 
#' frequency time series. \code{td} can be used with objects of class
#' \code{"\link{ts}"} as well as with basic vectors.
#' 
#' \code{td} is used to disaggregate or interpolate a low frequency to a higher 
#' frequency time series, while either the sum, the average, the first or the 
#' last value of the resulting high-frequency series is consistent with the low 
#' frequency series. Disaggregation can be performed with or without the help of
#' one or more indicator series. It can deal with all situations where the high 
#' frequency is an integer multiple of the low frequency (e.g. weeks to days), 
#' but not with irregular frequencies (e.g. weeks to months).
#' 
#' The selection of a temporal disaggregation model is similar to the selection 
#' of a linear regression model. Thus, \code{td} closely mirrors the working of 
#' the \code{\link{lm}} function. The left hand side of the
#' \code{\link{formula}} denotes the low-frequency series, the right hand side
#' the indicators. If no indicator is specified, the right hand side must be set
#' equal to \code{1} (see examples). Unlike \code{lm}, \code{td} handles
#' \code{\link{ts}} and \code{mts} time-series objects, as a typical application
#' involves the use of these objects. Alternatively, If used with basic vectors,
#' the \code{to} argument specifies the ratio between the high and the low
#' frequency series.
#' 
#' For the generalized least squares (GLS) methods \code{"chow-lin-maxlog"}, 
#' \code{"chow-lin-minrss-ecotrim"}, \code{"chow-lin-minrss-quilis"}, 
#' \code{"litterman-maxlog"} and \code{"litterman-minrss"}, an autoregressive 
#' parameter \eqn{\rho} is estimated. Default (and recommended) method is 
#' \code{chow-lin-maxlog}. With \code{neg.rho = FALSE} (default), it produces 
#' good results for a wide range of applications.
#' 
#' There are two variants of the \code{chow-lin-minrss} approach that lead to 
#' different results: Ecotrim by Barcellan (2002) uses a correlation matrix 
#' instead of the variance covariance matrix (implemented in 
#' \code{"chow-lin-minrss-ecotrim"}), the Matlab library by Quilis (2009) 
#' multiplies the correlation matrix with \eqn{1/(1-\rho^2)} (implemented in 
#' \code{"chow-lin-minrss-quilis"}).
#' 
#' The Denton methods \code{"denton"} and \code{"denton-cholette"} can be 
#' specified with one or without an indicator. The parameter \code{h} can be set
#' equal to \code{0}, \code{1}, or \code{2}. Depending on the value, the 
#' \code{denton} procedure minimizes the sum of squares of the deviations
#' between the levels (\code{0}), the first differences (\code{1}) or the second
#' differences (\code{2}) of the indicator and the resulting series. 
#' Additionally, \code{criterion} can be set equal to \code{"proportional"} or 
#' \code{"additive"}, depending on whether the proportional or the absolute 
#' deviations should be considered for minimzation. \code{"denton-cholette"} 
#' removes the transient movement of the original \code{"denton"} method at the 
#' beginning of the resulting series.
#' 
#' \code{"uniform"} is a special case of the \code{"denton"} approach, with 
#' \code{h} equals  \code{0} and \code{criterion} equals  \code{"proportional"}.
#' It distributes the residuals uniformly. If no indicator is used, this leads
#' to a step-shaped series.
#' 
#' \code{"ols"} performs an ordinary least squares regression (OLS) and 
#' distributes the residuals uniformly. It is especially useful for comparing
#' the estimators of GLS and OLS regressions.
#' 
#' @param formula     an object of class \code{"\link{formula}"}: a symbolic 
#'                    description of the the temporal disaggregation model. The
#'                    details of model specification are given under 'Details'.
#' @param conversion  type of conversion: \code{"sum"}, \code{"average"}, 
#'                    \code{"first"} or \code{"last"}.
#' @param method      method of temporal disaggregation: 
#'                    \code{"chow-lin-maxlog"}, 
#'                    \code{"chow-lin-minrss-ecotrim"}, 
#'                    \code{"chow-lin-minrss-quilis"}, \code{"chow-lin-fixed"}, 
#'                    \code{"fernandez"}, \code{"litterman-maxlog"}, 
#'                    \code{"litterman-minrss"}, \code{"litterman-fixed"},
#'                    \code{"denton-cholette"}, \code{"denton"}, 
#'                    \code{"uniform"} or \code{"ols"}. See 'Details'.
#' @param to          high-frequency destination frequency as a character string
#'                    (\code{"quarterly"} or \code{"monthly"}) or as a scalar 
#'                    (e.g. \code{2}, \code{4}, \code{7}, \code{12}). If the
#'                    input series are \code{ts} objects, the argument is
#'                    necessary if no indicator is given. If the input series 
#'                    are vectors, \code{to} must be a scalar indicating the
#'                    frequency ratio.
#'                    
#'                    
#' @param neg.rho     should a negative autoregressive parameter \eqn{\rho} be 
#'                    allowed. If not, negative \eqn{\rho} values will be
#'                    truncated to 0.
#' @param fixed.rho   set a predefined autoregressive parameter \eqn{\rho}. Only
#'                    works with the methods \code{"chow-lin-fixed"} and 
#'                    \code{"litterman-fixed"}.
#' @param criterion   minimzation criterion for Denton methods: 
#'                    \code{"proportional"} or \code{"additive"}.  See 
#'                    'Details'.
#' @param h           degree of differencing for Denton methods. See 'Details'.
#' @param start       (optional) start date. Similar to pre-processing the input
#'                    series with \code{\link{window}}.
#' @param end         (optional) end date. Similar to pre-processing the input 
#'                    series with \code{\link{window}}.
#' @param ...         additional arguments to be passed to the low level
#'                    subfunctions.
#' @return \code{td} returns an object of class \code{"td"}.
#'   
#'   The function \code{\link[=predict.td]{predict}} computes the interpolated 
#'   high frequency series. If the high-frequency indicator series are longer 
#'   than the low-frequency series, the resulting series will be extrapolated. 
#'   The function \code{coefficients} extracts the coefficients. The function 
#'   \code{residuals} extracts the low frequency residuals. The function 
#'   \code{\link[=summary.td]{summary}} prints a summary of the estimation.
#'   
#'   An object of class \code{"td"} is a list containing the following 
#'   components: 
#'   \item{fitted.values}{disaggregated or interpolated (and extrapolated) high
#'   frequency series} 
#'   \item{p}{preliminary high frequency series} 
#'   \item{residuals}{low-frequency residuals} 
#'   \item{rho}{autoregressive parameter, \eqn{\rho}} 
#'   \item{truncated}{logical, whether \eqn{\rho} has been truncated to 0}
#'   \item{coefficients}{a named vector of coefficients} 
#'   \item{se}{standard errors of the coefficients} 
#'   \item{s_2}{ML-estimator of the variance of the high-frequency residuals} 
#'   \item{s_2_gls}{GLS-estimator of the variance of the high-frequency
#'   residuals} 
#'   \item{tss}{weighted (low frequency) total sum of squares}
#'   \item{rss}{weighted (low frequency) residual sum of squares}
#'   \item{r.squared}{R squared} 
#'   \item{adj.r.squared}{adjusted R squared} 
#'   \item{logl}{log-likelihood} 
#'   \item{aic}{Akaike information criterion} 
#'   \item{bic}{Schwarz information criterion} 
#'   \item{rank}{number of right hand variables (including intercept)}
#'   \item{df}{degrees of freedom} 
#'   \item{method}{method of temporal disaggregation} 
#'   \item{call}{function call} 
#'   \item{name}{name of the low frequency variable} 
#'   \item{fr}{the ratio of high to low-frequency series} 
#'   \item{conversion}{type of temporal conversion} 
#'   \item{actual}{actual values of the low frequeny series} 
#'   \item{model}{a matrix containing the indicators (and a constant if
#'   present)} 
#'   \item{criterion}{minimization criterion in Denton methods} 
#'   \item{h}{order of differencing in Denton methods}
#'   
#' @references  Chow, G. C., & Lin, A. L. (1971). Best linear unbiased 
#'   interpolation, distribution, and extrapolation of time series by related 
#'   series. \emph{The review of Economics and Statistics}, 372-375.
#'   
#'   Denton, F. T. (1971). Adjustment of monthly or quarterly series to annual 
#'   totals: an approach based on quadratic minimization. \emph{Journal of the 
#'   American Statistical Association}, 66(333), 99-102.
#'   
#'   Barcellan, R. (2002). ECOTRIM: a program for temporal disaggregation of
#'   time series, Workshop on Quarterly National Accounts, Eurostat.
#'   
#'   Quilis, E. M. (2009). Matlab Temporal Disaggregation Library. URL: 
#'   \url{http://www.mathworks.com/matlabcentral/fileexchange/24438-temporal-disaggregation-library}
#'   
#' @seealso \code{\link{ta}} for temporal aggregation, the inverse function of 
#'   \code{td}.
#'   
#'   \code{\link[=summary.td]{summary}} is used to obtain and print a summary of
#'   the results.
#'   
#'   \code{\link[=predict.td]{predict}} is used to extract the disaggregated or 
#'   interpolated high frequency series.
#'   
#'   \code{\link[=plot.td]{plot}} is used to plot the predicted and actual low 
#'   frequency series, as well as the residuals.
#'   
#' @examples 
#' data(swisspharma)
#' 
#' # one indicator, no intercept 
#' mod1 <- td(sales.a ~ 0 + exports.q) 
#' summary(mod1)  # summary statistics 
#' plot(mod1)  # residual plot of regression 
#' plot(predict(mod1))  
#' 
#' # interpolated quarterly series
#'  
#' # temporally aggregated series is equal to the annual value 
#' all.equal(ta(predict(mod1), conversion = "sum", to = "annual"), sales.a)
#'  
#' # several indicators, including an intercept 
#' mod2 <- td(sales.a ~ imports.q + exports.q)
#'  
#' # no indicator (Denton-Cholette) 
#' mod3 <- td(sales.a ~ 1, to = "quarterly", method = "denton-cholette")
#'  
#' # no indicator (uniform) 
#' mod4 <- td(sales.a ~ 1, to = "quarterly", method = "uniform")
#'  
#' # Example from Denton (1971), see references. 
#' d.q <- ts(rep(c(50, 100, 150, 100), 5), frequency = 4) 
#' d.a <- ts(c(500, 400, 300, 400, 500))
#'  
#' a1 <- predict(td(d.a ~ 0 + d.q, method = "denton", 
#'                  criterion = "additive", h = 0)) 
#' a2 <- predict(td(d.a ~ 0 + d.q, method = "denton", 
#'                  criterion = "additive", h = 1)) 
#' a3 <- predict(td(d.a ~ 0 + d.q, method = "denton", 
#'                  criterion = "additive", h = 2)) 
#' a4 <- predict(td(d.a ~ 0 + d.q, method = "denton", 
#'                  criterion = "additive", h = 3))
#'  
#' p1 <- predict(td(d.a ~ 0 + d.q, method = "denton", 
#'                  criterion = "proportional", h = 0)) 
#' p2 <- predict(td(d.a ~ 0 + d.q, method = "denton", 
#'                  criterion = "proportional", h = 1)) 
#' p3 <- predict(td(d.a ~ 0 + d.q, method = "denton", 
#'                  criterion = "proportional", h = 2)) 
#' p4 <- predict(td(d.a ~ 0 + d.q, method = "denton", 
#'                  criterion = "proportional", h = 3))
#'  
#' # Table in Denton (1971), page 101: 
#' round(cbind(d.q, a1, a2, a3, a4, p1, p2, p3, p4))
#'  
#' @keywords ts, models
#' @export
#' 
td <- function(formula, conversion = "sum", to = "quarterly", 
               method = "chow-lin-maxlog", neg.rho = FALSE, fixed.rho = 0.5, 
               criterion = "proportional", h = 1,
               start = NULL, end = NULL, ...) {
  
  # td deals with the formula interface, the time-series properties
  # and allows for optional shortening of the series. The estimation itself is
  # done by subfunctions starting with Sub...
  
  cl <- match.call()
  
  
  # --- input consistency ----------------------------------------------------
  
  # dont allow length=2 vectors as start or end inputs
  if (any(c(length(start), length(end)) > 1)){
    stop("'start' or 'end' must be specified as a decimal fraction")
  }
  
  
  # ---- prepare Formula, extract names and data ------------------------------
  
  # extract X (right hand side, high frequency) formula, names and data
  X.formula <- formula; X.formula[[2]] <- NULL
  X.series.names <- all.vars(X.formula)
  
  # extract y_l (left hand side, low frequency) formula, values and names
  y_l.formula <- formula[[2]]
  y_l.series <- eval(y_l.formula, envir=environment(formula))
  y_l.name <- deparse(y_l.formula)
  
  
  # ---- set ts.mode ----------------------------------------------------------
  
  # 1. is y_l.series a time series? if so, set ts.mode to TRUE
  if (is.ts(y_l.series)){
    ts.mode <- TRUE
    # 2. is there a X? is it a time series? if not, set ts.mode to FALSE
    if (length(X.series.names) > 0) {
      if (!is.ts(get(X.series.names[1], envir=environment(X.formula)))){
        warning("Only left hand side is a time series. Using non-ts mode.")
        ts.mode <- FALSE
      }
    }
  } else{
    ts.mode <- FALSE
  }
  
  
  # ---- set or modify time series attributes ('fr', 'start', 'end') ----------
  
  if (ts.mode) {
    
    ### ts.mode: y_l.series
    if (is.null(start)) {
      start <- time(y_l.series)[!is.na(y_l.series)][1]
    }
    f_l <- frequency(y_l.series)
    
    ### ts.mode: X.series
    if (length(X.series.names) > 0){  # If X is pecified
      # first series of X (to get 'start' and 'f')
      X.series.first <- eval(X.formula[[2]], envir = environment(X.formula))
      X.start <- time(X.series.first)[!is.na(X.series.first)][1]
      f <- frequency(X.series.first)
      fr <- f/f_l
      if (X.start > start){
        start <- floor(X.start) + 
          (ceiling(((X.start - floor(X.start)) * f) / fr)) / f_l
      }
      
    } else {  # If no X is specified
      if (is.numeric(to)){  # frequency specified by a number
        f <- to
      } else if (is.character(to)){  # frequency specified by a char string
        if (to == "quarterly"){
          f <- 4
        } else if (to == "monthly"){
          f <- 12
        } else {
          stop("'to' argument: unknown character string")
        }
      } else stop ("'to' argument: wrong specification")
      fr <- f/f_l
      X.start <- start
    }
    
    # define X.end, if 'end' is specified
    if(!is.null(end)){
      X.end <- floor(end) + (fr * ((end-floor(end)) * f_l + 1) - 1) / f
    } else {
      X.end <- NULL
    }
  }  else {
    
    ### non ts.mode
    if (!is.numeric(to)){stop("In non-ts mode, 'to' must be an integer number.")}
    f_l <- 1
    f <- to
    fr <- f/f_l
  }
  
  # --- raw X matrix ----------------------------------------------------------
  
  if (length(X.series.names) > 0){
    X <- model.matrix(X.formula)
    X.names <- dimnames(X)[[2]]
  } else {  
    # if there is no X Variables, set it to a constant ('Denton' Methods)
    X <- matrix(rep(1, times = length(y_l.series) * fr))
    if (!(method %in% c("denton-cholette", "denton", "uniform"))) {
      warning ("No indicator specified: denton,
               denton-cholette or uniform are recommended.")
    }
    X.names <- "(Intercept)"
    }
  
  if (ts.mode){
    X <- ts(X, start = X.start, frequency = f)
  }
  
  # --- adjust length of y_l.series and X (only ts.mode) -----------------------
  
  if (ts.mode){
    y_l.series <- window(y_l.series, start = start, end = end)
    X <- window(X, start = start, end = X.end)
  }
  
  
  # --- final data matrices ---------------------------------------------------
  
  y_l <- as.matrix(y_l.series)
  X <- matrix(X, nrow=nrow(X), ncol=ncol(X))
  dimnames(X) <- list(NULL, X.names)
  
  
  # --- estimation ------------------------------------------------------------
  
  # actual estimation 
  if (method %in% c("chow-lin-maxlog", "chow-lin-minrss-ecotrim",
                    "chow-lin-minrss-quilis", "chow-lin-fixed",
                    "litterman-maxlog", "litterman-minrss", "litterman-fixed", 
                    "fernandez", "ols")){
    z <- SubRegressionBased(y_l = y_l, X = X, conversion = conversion, 
                            method = method, neg.rho = neg.rho, 
                            fixed.rho = fixed.rho, fr = fr, ...)
  } else if (method %in% c("denton-cholette", "denton", "uniform")){
    z <- SubDenton(y_l = y_l, X = X, conversion = conversion, method = method, 
                   criterion = criterion, h = h, fr = fr, ...)
  } else {
    stop("method does not exist")
  }
  
  
  # --- output ----------------------------------------------------------------
  
  # add coefficent names to output
  if (!is.null(z$coefficients)) {
    names(z$coefficients) <- names(z$se) <- X.names
  }
  
  # additional output
  z$method             <- method
  z$call               <- cl
  z$name               <- y_l.name
  z$fr                 <- fr
  z$conversion         <- conversion
  z$actual             <- y_l.series
  z$model              <- X
  if (ts.mode) {
    z$model            <- ts(z$model, start = start, frequency = f)
    z$p                <- ts(z$p, start = start, frequency = f)
    z$fitted.values    <- ts(z$fitted.values, start = start, frequency = f)
    z$residuals        <- ts(z$residuals, start = start, frequency = f_l)
    z$actual           <- ts(z$actual, start = start, frequency = f_l)
  }
  class(z) <- "td"
  z
}
