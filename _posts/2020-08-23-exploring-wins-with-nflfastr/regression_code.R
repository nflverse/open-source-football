# Setup our own correlation-matrix function. It calls the default
# cor(...) function of R on the user-supplied data frame, but it only
# calculates it on the numerical (i.e., integer and numeric) columns

aa_cor <- function(x) {
    cols <- which(sapply(x, class) %in% c("integer", "numeric", "AsIs"))
    if(length(cols) > 1)
        return(cor(x[, cols]))
    else {
        warning("Correlation matrix: Not enough numerical columns. Returning NA.")
        return(NA)
    }
}

# Setup a function to provide the necessary diagnostics to critique a
# (linear) regression

aa_critique_fit <- function(fit) {

    # The object res stores our results as a list. Initialize it

    res <- list()

    # Use coefficients and intercept of the fit to create the fitted
    # regression equation/formula,

    coeffs <- coefficients(fit)
    res$formula <- paste0(
        as.character(formula(fit)[2]), " = ",
        round(coeffs[1], 4), " + ",
        paste(sprintf("%.4f * %s", coeffs[-1], names(coeffs[-1])), collapse=" + ")
    )

    # Store R's standard summary of the fit

    res$summary <- summary(fit)

    # Pull out the adjusted R^2, standard error, and mean Y values

    res$R2 <- res$summary$adj.r.squared
    res$Se <- res$summary$sigma
    res$mean_Y <- mean(fit$model[[1]], na.rm = TRUE)

    # Get the 95% confidence intervals for the coefficients and intercept

    res$confint <- confint(fit)

    # Construct the plot of residuals on fitted values

    res$residual_plot <- qplot(fit$fitted.values, fit$residuals) +
        xlab("Fitted Value") + ylab("Residual")

    # Construct the residual histogram (actually, residual density)

    res$residual_histogram <- qplot(fit$residuals, geom = "density") + xlab("Residual")

    # Store the correlation matrix using the above aa_cor() function

    res$cor <- aa_cor(fit$model)

    # If this is a multiple linear regression, calculate the
    # "generalized" VIFs

    # # if(length(fit$coefficients) > 2) {
    # if(length(labels(terms(fit))) > 1) {
    #     if(class(vif(fit)) == "numeric") res$vif <- vif(fit)
    #     else res$vif <- vif(fit)[, 1]
    # }

    # Return the results

    res
}
