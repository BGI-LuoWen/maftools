#' Plots vaf distribution of genes
#' @description Plots vaf distribution of genes as a boxplot or violinplot.
#'
#' @param maf an \code{\link{MAF}} object generated by \code{\link{read.maf}}
#' @param vafCol manually specify column name for vafs. Default looks for column 't_vaf'
#' @param genes specify genes for which plots has to be generated
#' @param density logical whether to plot density plot of vaf
#' @param violin if TRUE plots violin plot
#' @param orderByMedian Orders genes by decreasing median VAF. Default TRUE
#' @param top if \code{genes} is NULL plots top n number of genes. Defaults to 5.
#' @param flip if TRUE, flips axes. Default FALSE
#' @param fn Filename. If given saves plot as a output pdf. Default NULL.
#' @param width Width of plot to be saved. Default 6
#' @param height Height of plot to be saved. Default 5
#' @return ggplot object which can be further modified.
#' @examples
#' laml.maf <- system.file("extdata", "tcga_laml.maf.gz", package = "maftools")
#' laml <- read.maf(maf = laml.maf, removeSilent = TRUE, useAll = FALSE)
#' plotVaf(maf = laml, vafCol = 'i_TumorVAF_WU')
#'
#' @export

plotVaf = function(maf, vafCol = NULL, genes = NULL, violin = FALSE, top = 10, orderByMedian = TRUE, flip = FALSE, fn = NULL, width = 6, height = 5){

  dat = maf@data

  if(!'t_vaf' %in% colnames(dat)){
    if(is.null(vafCol)){
      print(colnames(dat))
      stop('t_vaf field is missing. Use vafCol to manually specify vaf column name.')
    }else{
      colnames(dat)[which(colnames(dat) == vafCol)] = 't_vaf'
    }
  }

  if(is.null(genes)){
    genes = maf@gene.summary[1:top, Hugo_Symbol]
  }

  #dat.genes = data.frame(dat[dat$Hugo_Symbol %in% genes])
  #suppressMessages(datm <- melt(dat.genes[,c('Hugo_Symbol', 't_vaf')]))
  dat.genes = dat[dat$Hugo_Symbol %in% genes]
  suppressWarnings(datm <- data.table::melt(data = dat.genes[,.(Hugo_Symbol, t_vaf)]))
  #remove NA from vcf
  datm = datm[!is.na(value)]

  #maximum vaf
  if(max(datm$value, na.rm = TRUE) > 1){
    datm$value = datm$value/100
  }

  if(orderByMedian){
    geneOrder = datm[,median(value),Hugo_Symbol][order(V1, decreasing = TRUE)][,Hugo_Symbol]
    datm$Hugo_Symbol = factor(x = datm$Hugo_Symbol, levels = geneOrder)
  }

  if(violin){
    gg = ggplot(data = datm, aes(x = Hugo_Symbol, y = value))+
      geom_violin(draw_quantiles = TRUE, na.rm = TRUE, fill = 'gray70', alpha = 0.6)
  } else{
      gg = ggplot(data = datm, aes(x = Hugo_Symbol, y = value))+
        geom_boxplot(outlier.color = 'gray70', outlier.size = 0.6, alpha = 0.6, fill = 'gray70')
  }

  gg = gg+cowplot::theme_cowplot(font_size = 10)+ylim(0, 1)+
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1),legend.position = 'none')+
    ylab('VAF')+xlab('')+cowplot::background_grid(major = 'xy')

  if(flip){
    gg = gg+coord_flip()+theme(axis.text.x = element_text(angle = 0, vjust = 0.5, hjust=0.5))
  }

  if(!is.null(fn)){
    cowplot::save_plot(filename = paste0(fn, '.pdf'), plot = gg, base_height = height, base_width = width, bg = 'white')
  }

  print(gg)
  return(gg)
}
