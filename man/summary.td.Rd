\name{summary.td}
\alias{print.summary.td}
\alias{summary.td}
\title{Summary of a Temporal Disaggregation}
\usage{
  \method{summary}{td} (object, ...)

  \method{print}{summary.td} (x,
    digits = max(3, getOption("digits") - 3),
    signif.stars = getOption("show.signif.stars"), ...)
}
\arguments{
  \item{object}{an object of class \code{"td"}, usually, a
  result of a call to \code{\link{td}}.}

  \item{x}{an object of class \code{"summary.td"}, usually,
  a result of a call to \code{summary.td}.}

  \item{digits}{the number of significant digits to use
  when printing.}

  \item{signif.stars}{logical. If \code{TRUE},
  'significance stars' are printed for each coefficient.}

  \item{\dots}{further arguments passed to or from other
  methods.}
}
\value{
  \code{summary.td} returns a list containing the summary
  statistics included in \code{object}, and computes the
  following additional statistics:

  \item{n_l}{number of low frequency observations}
  \item{n}{number of high frequency observations}
  \item{sigma}{standard deviation of the regression}
  \item{ar_l}{empirical auto-correlation of the low
  frequency series} \item{coefficients}{a named matrix
  containing coefficients, standard deviations, t-values
  and p-values}

  The \code{print} method prints the summary output in a
  similar way as the method for \code{"lm"}.
}
\description{
  \code{summary} method for class "td".
}
\examples{
data(swisspharma)

mod1 <- td(sales.a ~ imports.q + exports.q)
summary(mod1)

mod2 <- td(sales.a ~ 0, to = "quarterly", method = "uniform")
summary(mod2)
}
\seealso{
  \code{\link{td}} for the main function for temporal
  disaggregation.
}
\keyword{models}
\keyword{ts,}

