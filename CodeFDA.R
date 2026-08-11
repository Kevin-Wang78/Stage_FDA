################################################################################
################################## Stage sur FDA ###############################
################################################################################

# Importation des bibliothèques
library(reticulate)
library(fda)
library(fda.usc)
library(fdasrvf)
library(MFPCA)
library(funData)
library(ggplot2)
library(caret)
library(pROC)
library(RcppCNPy)

###################### Transformation en images binaires #######################

# Importation de fichiers
np <- import("numpy", convert = FALSE)

# Extraire du fichier X_segmented 
x_seg <- np$load("data/X_segmented.npy", mmap_mode = "r")

# Pour produire des images en noir et blanc
bw_logical_py <- x_seg$any(axis = 3L)

# Images sous forme de booléens
bw_all_logical <- py_to_r(bw_logical_py)

# Transformation en images binaires (0 et 1 pour differencier les 2 couleurs)
bw_all <- array(as.integer(bw_all_logical), dim = dim(bw_all_logical))

# Sauvegarde du nouveau fichier créé
saveRDS(
  bw_all, 
  file = "data/X_binaire2.rds", 
  compress = FALSE
)

# Essai pour charger le nouveau fichier créé
test_load <- readRDS("data/X_binaire2.rds")

# Exemple de code pour voir une des images binaires quelconque
une_image <- bw_all[42, , ] # Ici, on prend le grain de beauté 42

# Affichage de l'image binaire
image(une_image, col = c("black", "white"), useRaster = TRUE)

########################## Extraction de contours ##############################

# Lecture des données
donnees_grains <- readRDS("data/X_binaire2.rds")

# Nombre de grains de beauté dans les données
nb_images <- dim(donnees_grains)[1]

# Liste pour stocker les contours contenant les coordonnées
liste_contours <- vector("list", nb_images)

# Utilisation de l'algorithme de Marching Square pour tracer les contours
for (index in 1:nb_images) {
  image_quelconque <- donnees_grains[index, , ]
  contour_trace <- contourLines(
    x = 1:nrow(image_quelconque),
    y = 1:ncol(image_quelconque),
    z = image_quelconque,
    levels = 0.3
  )
  
  # Si la longueur du contour est positive, alors, tout s'est bien passé
  if (length(contour_trace) > 0) {
    # On extrait le premier contour trouvé
    df_contour <- data.frame(
      x = contour_trace[[1]]$x,
      y = contour_trace[[1]]$y
    )
    
    # Stocker les coordonnées du contour
    liste_contours[[index]] <- df_contour
  } else {
    liste_contours[[index]] <- NULL
  }
  
  # Message pour avertir que les contours ont bien été traités
  if (index %% 100 == 0) {
    message("L'image a ete bien traitee.")
  }
} 

# Sauvegarde de ce nouveau fichier contenant les contours sous forme numérique
saveRDS(
  liste_contours,
  "data/contours_extraits_partie1.rds"
)

## Pour voir un exemple de contour

# Chargement du fichier
mes_contours <- readRDS("data/contours_extraits_partie1.rds")

# Index choisi pour commencer le contour
index_choisi <- 42 # au hasard
un_contour <- mes_contours[[index_choisi]] 

# Tracer le contour du grain de beauté
if (!is.null(un_contour)) {
  plot(un_contour$x, un_contour$y, 
       type = "l",          # "ligne continue
       col = "black",       # Couleur du contour
       lwd = 2,             # Épaisseur de la ligne
       asp = 1,             
       main = paste("Contour extrait du grain de beauté #", index_choisi),
       xlab = "Coordonnées X", 
       ylab = "Coordonnées Y")
} 

##################### Lissage & Séparation Train/Test Initial #######################

# Chargement du fichier contenant les contours extraits
mes_contours <- readRDS("data/contours_extraits_partie1.rds")

# Filtrer les indices des contours valides 
indices_valides_init <- seq_along(mes_contours)
contours_valides     <- mes_contours[indices_valides_init]

# Alignement des métadonnées Y
np <- import("numpy")
Y <- np$load("data/y.npy")
Y <- py_to_r(Y)
Y <- ifelse(Y == "mel", 1, 0)

y_valides <- Y[indices_valides_init]

# Changement en base de Fourier 
base_fourier <- create.fourier.basis(rangeval = c(0, 2*pi), nbasis = 101)

# Centrer les contours
contour_to_fd <- function(contour) {
  
  # Centrage des donnees
  x <- contour$x - mean(contour$x)
  y <- contour$y - mean(contour$y)
  
  # Paramétrisation par longueur d'arc ramenée sur [0, 2pi]
  s <- c(0, cumsum(sqrt(diff(x)^2 + diff(y)^2)))
  t <- 2 * pi * s / max(s)
  
  # Réechantillonner de façon uniforme
  t_new <- seq(0, 2*pi, length.out = 200)
  x_new <- approx(t, x, xout = t_new, method = "linear", rule = 2)$y
  y_new <- approx(t, y, xout = t_new, method = "linear", rule = 2)$y
  
  # Lissage par Fourier
  list(
    x = smooth.basis(t_new, x_new, fdParobj = base_fourier)$fd,
    y = smooth.basis(t_new, y_new, fdParobj = base_fourier)$fd,
    t_x = mean(contour$x),
    t_y = mean(contour$y)
  )
}

# Fonction qui va seulement tenir compte des contours valides
formes <- lapply(contours_valides, contour_to_fd)

saveRDS(formes, "data/formes_lissees.rds")

# Split Entrainement/Test
set.seed(123)

# 80% des données a l'entrainement et 20% des données au test
train_indices <- createDataPartition(y_valides, p = 0.8, list = FALSE)

# Formes qui vont être dans l'entrainement
formes_train <- formes[train_indices]
y_train      <- y_valides[train_indices]

# Formes qui vont être dans le test
formes_test  <- formes[-train_indices]
y_valides <- as.vector(y_valides)
y_test <- y_valides[-train_indices]

########################### Alignement par ICF ##########################

temps <- seq(0, 2*pi, length.out = 200) # Premier parametre
deltas <- seq(0, 2*pi, length.out = 40) # Deuxieme parametre

# Fonction pour trouver la rotation optimale 
rotation_opt <- function(x, y, x_reference, y_reference) {
  atan2(sum(x*y_reference - y*x_reference), sum(x*x_reference + y*y_reference))
}

# Contour de référence choisi sur le Train (Pouvant aller de 1 a 5)
moyenne <- formes_train[[1]] # Ici, on choisit de prendre le premier contour comme référence
nb_iter <- 10

# Alignement du TRAIN 
x_reference <- eval.fd(temps, formes_train[[1]]$x) # Ici, le premier contour comme référence
y_reference <- eval.fd(temps, formes_train[[1]]$y) # Ici, le premier contour comme référence

for (iter in 1:nb_iter) {
  
  formes_alignees_train <- lapply(seq_along(formes_train), function(i) {
    f <- formes_train[[i]]
    x <- eval.fd(temps, f$x)
    y <- eval.fd(temps, f$y)
    
    erreurs <- numeric(length(deltas))
    
    for (k in seq_along(deltas)) {
      d <- deltas[k]
      x_s <- approx(temps, x, (temps + d) %% (2 * pi), rule = 2)$y
      y_s <- approx(temps, y, (temps + d) %% (2 * pi), rule = 2)$y
      erreurs[k] <- sum((x_s - x_reference)^2 + (y_s - y_reference)^2)
    }
    
    d_opt <- deltas[which.min(erreurs)]
    x_shift <- approx(temps, x, (temps + d_opt) %% (2 * pi), rule = 2)$y
    y_shift <- approx(temps, y, (temps + d_opt) %% (2 * pi), rule = 2)$y
    
    theta <- rotation_opt(x_shift, y_shift, x_reference, y_reference)
    
    list(
      x = x_shift * cos(theta) - y_shift * sin(theta),
      y = x_shift * sin(theta) + y_shift * cos(theta),
      theta = theta
    )
  })
  
  mat_x <- sapply(formes_alignees_train, `[[`, "x")
  mat_y <- sapply(formes_alignees_train, `[[`, "y")
  
  moyenne$x <- smooth.basis(argvals = temps, y = rowMeans(mat_x), fdParobj = base_fourier)$fd
  moyenne$y <- smooth.basis(argvals = temps, y = rowMeans(mat_y), fdParobj = base_fourier)$fd  
  message("Itération Train ", iter, " / ", nb_iter, " terminée")
}

# Alignement du TEST sur la même référence du Train
formes_alignees_test <- lapply(seq_along(formes_test), function(i) {
  f <- formes_test[[i]]
  x <- eval.fd(temps, f$x)
  y <- eval.fd(temps, f$y)
  
  erreurs <- numeric(length(deltas))
  for (k in seq_along(deltas)) {
    d <- deltas[k]
    x_s <- approx(temps, x, (temps + d) %% (2 * pi), rule = 2)$y
    y_s <- approx(temps, y, (temps + d) %% (2 * pi), rule = 2)$y
    erreurs[k] <- sum((x_s - x_reference)^2 + (y_s - y_reference)^2)
  }
  
  d_opt <- deltas[which.min(erreurs)]
  x_shift <- approx(temps, x, (temps + d_opt) %% (2 * pi), rule = 2)$y
  y_shift <- approx(temps, y, (temps + d_opt) %% (2 * pi), rule = 2)$y
  
  theta <- rotation_opt(x_shift, y_shift, x_reference, y_reference)
  
  list(
    x = x_shift * cos(theta) - y_shift * sin(theta),
    y = x_shift * sin(theta) + y_shift * cos(theta),
    theta = theta
  )
})

# Extraire les theta optimaux
liste_theta_train <- lapply(formes_alignees_train, `[[`, "theta")
liste_theta_test  <- lapply(formes_alignees_test,  `[[`, "theta")

# Ici, le premier contour comme référence que vient la sauvegarde
saveRDS(
  formes_alignees_train,
  "data/contours_alignes_ICF_1_train.rds"
)

saveRDS(
  formes_alignees_test,
  "data/contours_alignes_ICF_1_test.rds"
)

############################### 4 COMPOSANTES ##################################

#----------------------------------- FPCA --------------------------------------

# Préparation des matrices Train 
matrice_X_tr <- t(sapply(formes_alignees_train, `[[`, "x"))
matrice_Y_tr <- t(sapply(formes_alignees_train, `[[`, "y"))

# Construction de l'array 3D pour le Train
array_contours_tr <- array(0, dim = c(200, length(formes_train), 2))
array_contours_tr[,,1] <- t(matrice_X_tr)
array_contours_tr[,,2] <- t(matrice_Y_tr)

# Lissage avec la base de Fourier à 29 fonctions
fourier_basis <- create.fourier.basis(rangeval = c(0, 2*pi), nbasis = 29)
fd_contours_tr <- smooth.basis(temps, array_contours_tr, fourier_basis)$fd

# Exécution de la FPCA sur le Train (6 composantes)
fpca_result <- pca.fd(fd_contours_tr, nharm = 6)

# Calcul et affichage des variances expliquées
variances <- fpca_result$varprop * 100
variance_cumulee <- cumsum(variances)

# Tableau qui va contenir la variabilité de chaque composante principale
tableau_variance <- data.frame(
  Composante = paste0("FPC", 1:6),
  `Variance_Expliquee (%)` = round(variances[1:6], 2),
  `Variance_Cumulee (%)` = round(variance_cumulee[1:6], 2)
)

# Afficher les valeurs de variabilité
print(tableau_variance)

# Extraction des scores de Train
scores_FPCA_tr <- apply(fpca_result$scores[, 1:6, ], 1, c)
scores_FPCA_tr <- t(scores_FPCA_tr)
colnames(scores_FPCA_tr) <- c(paste0("PC", 1:6, "_X"), paste0("PC", 1:6, "_Y"))

# Extraction des matrices Test
matrice_X_te <- t(sapply(formes_alignees_test, `[[`, "x"))
matrice_Y_te <- t(sapply(formes_alignees_test, `[[`, "y"))

# Centrage par la moyenne du TRAIN 
mean_x_train <- rowMeans(matrice_X_tr)
mean_y_train <- rowMeans(matrice_Y_tr)

matrice_X_te_centered <- matrice_X_te - mean_x_train
matrice_Y_te_centered <- matrice_Y_te - mean_y_train

# Construction de l'array 3D centré pour le Test
array_contours_te_cent <- array(0, dim = c(200, length(formes_test), 2))
array_contours_te_cent[,,1] <- t(matrice_X_te_centered)
array_contours_te_cent[,,2] <- t(matrice_Y_te_centered)

# Lissage avec la même base de Fourier, mais à 29 fonctions
fd_contours_te_cent <- smooth.basis(temps, array_contours_te_cent, fourier_basis)$fd

# Calcul des scores par projection matricielle directe des coefficients
coef_te <- fd_contours_te_cent$coefs      # dim: [29, N_test, 2]
coef_harm <- fpca_result$harmonics$coefs  # dim: [29, 6, 2]

# Matrice de Gram des fonctions de base
J <- eval.penalty(fourier_basis, Lfdobj = 0)

scores_FPCA_te_mat <- matrix(0, nrow = length(formes_test), ncol = 12)

# Calcul du produit scalaire pour chaque composante K (1 à 6)
for (k in 1:6) {
  # Produit scalaire sur X
  score_x <- t(coef_te[,,1]) %*% J %*% coef_harm[,k,1]
  # Produit scalaire sur Y
  score_y <- t(coef_te[,,2]) %*% J %*% coef_harm[,k,2]
  
  scores_FPCA_te_mat[, k]     <- score_x
  scores_FPCA_te_mat[, k + 6] <- score_y
}

scores_FPCA_te <- as.data.frame(scores_FPCA_te_mat)
colnames(scores_FPCA_te) <- c(paste0("PC", 1:6, "_X"), paste0("PC", 1:6, "_Y"))

# Graphiques des composantes principales
lambdas <- fpca_result$values 
sd_harmonics <- sqrt(lambdas) 
var_pct <- round(fpca_result$varprop * 100, 2)

par(mfrow = c(2, 3), mar = c(4, 4, 3, 1))
t_grid <- seq(0, 2 * pi, length.out = 200)

mean_fd <- fpca_result$meanfd
mean_eval <- eval.fd(t_grid, mean_fd) 
mean_x <- mean_eval[, 1, 1]
mean_y <- mean_eval[, 1, 2]

harmonics_fd <- fpca_result$harmonics
harm_eval <- eval.fd(t_grid, harmonics_fd) 

nombre_composantes <- 6
for (k in 1:nombre_composantes) {
  sd_k <- sd_harmonics[k]
  psi_kx <- harm_eval[, k, 1]
  psi_ky <- harm_eval[, k, 2]
  
  plus_2sd_x  <- mean_x + 2 * sd_k * psi_kx
  plus_2sd_y  <- mean_y + 2 * sd_k * psi_ky
  moins_2sd_x <- mean_x - 2 * sd_k * psi_kx
  moins_2sd_y <- mean_y - 2 * sd_k * psi_ky
  
  plot(plus_2sd_x, plus_2sd_y, type = "l", col = "red", lwd = 2, asp = 1,
       main = paste0("FPC", k, " (", var_pct[k], "%)"),
       xlab = "X", ylab = "Y")
  lines(moins_2sd_x, moins_2sd_y, col = "blue", lwd = 2, lty = 2)
  lines(mean_x, mean_y, col = "black", lwd = 1.5)
}

par(mfrow = c(1, 1))

#----------------------------- Classification ----------------------------------

# Récupération des caractéristiques géométriques
tx_train <- sapply(formes_train, function(f) f$t_x[1])
ty_train <- sapply(formes_train, function(f) f$t_y[1])
theta_train <- as.numeric(liste_theta_train)

tx_test <- sapply(formes_test, function(f) f$t_x[1])
ty_test <- sapply(formes_test, function(f) f$t_y[1])
theta_test <- as.numeric(liste_theta_test)

# Calcul de l'erreur de reconstruction par rapport à la moyenne du Train
if (ncol(matrice_X_tr) == 200) {
  mean_x_vec <- colMeans(matrice_X_tr)
  mean_y_vec <- colMeans(matrice_Y_tr)
  erreur_train <- rowSums((matrice_X_tr - matrix(mean_x_vec, nrow = nrow(matrice_X_tr), ncol = 200, byrow = TRUE))^2 +
                            (matrice_Y_tr - matrix(mean_y_vec, nrow = nrow(matrice_Y_tr), ncol = 200, byrow = TRUE))^2)
  
  erreur_test  <- rowSums((matrice_X_te - matrix(mean_x_vec, nrow = nrow(matrice_X_te), ncol = 200, byrow = TRUE))^2 +
                            (matrice_Y_te - matrix(mean_y_vec, nrow = nrow(matrice_Y_te), ncol = 200, byrow = TRUE))^2)
} else {
  mean_x_vec <- rowMeans(matrice_X_tr)
  mean_y_vec <- rowMeans(matrice_Y_tr)
  erreur_train <- colSums((matrice_X_tr - mean_x_vec)^2 + (matrice_Y_tr - mean_y_vec)^2)
  erreur_test  <- colSums((matrice_X_te - mean_x_vec)^2 + (matrice_Y_te - mean_y_vec)^2)
}

# Assemblage des jeux de données
donnees_train <- cbind(
  data.frame(
    Y      = factor(y_train, levels = c(0, 1)),
    t_x    = tx_train,
    t_y    = ty_train,
    theta  = theta_train,
    erreur = erreur_train
  ),
  as.data.frame(scores_FPCA_tr)
)

donnees_test <- cbind(
  data.frame(
    Y      = factor(y_test, levels = c(0, 1)),
    t_x    = tx_test,
    t_y    = ty_test,
    theta  = theta_test,
    erreur = erreur_test
  ),
  as.data.frame(scores_FPCA_te)
)

# Calcul des poids dans un vecteur séparé
nb_benin     <- sum(donnees_train$Y == 0)
nb_melanome  <- sum(donnees_train$Y == 1)
poids_vector <- ifelse(donnees_train$Y == 1, nb_benin / nb_melanome, 1)

# Ajustement du modèle de régression logistique
modele_logit <- suppressWarnings(
  glm(
    Y ~ ., 
    data = donnees_train, 
    family = binomial(link = "logit"), 
    weights = poids_vector
  )
)

# Imprimer les valeur-p pour chaque paramètre (varialble) dans le but de voir leur niveau de signification
summary(modele_logit)

# Prédiction des probabilités sur l'échantillon de Test
probabilites_test <- predict(modele_logit, newdata = donnees_test, type = "response")

# Analyse ROC et calcul de l'AUC
courbe_roc <- roc(donnees_test$Y, probabilites_test)
auc_valeur <- as.numeric(auc(courbe_roc))

# Extraction du seuil de décision optimal (Indice de Youden)
coords_opt <- coords(courbe_roc, "best", ret = "threshold")
seuil_decision <- as.numeric(coords_opt[1, "threshold"])

# Application du seuil optimal pour la classification binaire
y_pred_test <- factor(ifelse(probabilites_test > seuil_decision, 1, 0), levels = c(0, 1))

# Matrice de confusion et métriques de performance
matrice_eval <- confusionMatrix(y_pred_test, donnees_test$Y, positive = "1")
print(matrice_eval)

# Tracé de la courbe ROC
plot(
  courbe_roc, 
  col = "firebrick", 
  lwd = 3, 
  main = paste("Courbe ROC - Modèle Logistique FDA (AUC =", round(auc_valeur, 3), ")")
)
grid()

# Extraction et affichage des métriques clés
accuracy    <- as.numeric(matrice_eval$overall["Accuracy"])
precision   <- as.numeric(matrice_eval$byClass["Precision"])
sensibilite <- as.numeric(matrice_eval$byClass["Sensitivity"])

f1_score <- as.numeric(matrice_eval$byClass["F1"])
if (is.na(f1_score)) {
  f1_score <- 2 * (precision * sensibilite) / (precision + sensibilite)
}

# Afficher les métriques de performance
cat(sprintf("AUC         : %.4f\n", auc_valeur))
cat(sprintf("Accuracy    : %.4f (%.2f%%)\n", accuracy, accuracy * 100))
cat(sprintf("F1-Score    : %.4f\n", f1_score))

# Regarder la valeur pour l'exactitude équilibré dans le but de montrer que cela est plus performant
balanced_accuracy <- as.numeric(matrice_eval$byClass["Balanced Accuracy"])
balanced_accuracy
balanced_accuracy_arrondi <- round(balanced_accuracy, 4)
print(balanced_accuracy_arrondi * 100)




